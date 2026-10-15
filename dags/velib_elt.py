"""DAG horaire : API Vélib' -> GCS -> BigQuery (raw) -> dbt build (staging, marts, tests)."""
from __future__ import annotations

import os
from datetime import timedelta

import pendulum
from airflow.decorators import dag, task
from airflow.operators.bash import BashOperator

PROJECT = os.environ["GCP_PROJECT_ID"]
BUCKET = os.environ["GCS_BUCKET"]
RAW_DATASET = os.environ.get("BQ_RAW_DATASET", "velib_raw")
LOCATION = os.environ.get("BQ_LOCATION", "EU")

DBT_CMD = """
set -euo pipefail
rm -rf /tmp/dbt_run && cp -r /opt/airflow/dbt /tmp/dbt_run && cd /tmp/dbt_run
dbt deps --profiles-dir .
dbt build --profiles-dir .
"""


@dag(
    dag_id="velib_elt",
    schedule="@hourly",
    start_date=pendulum.datetime(2026, 10, 1, tz="UTC"),
    catchup=False,  # l'API ne donne que l'état courant : pas de backfill possible
    max_active_runs=1,
    default_args={"retries": 2, "retry_delay": timedelta(minutes=5)},
    tags=["velib", "elt", "gcp", "dbt"],
    doc_md=__doc__,
)
def velib_elt():
    @task
    def extract_to_gcs(data_interval_end=None) -> dict:
        from velib.extract import build_object_path, fetch_records, to_ndjson
        from velib.load import upload_to_gcs

        snapshot_hour = data_interval_end.replace(minute=0, second=0, microsecond=0)
        records = fetch_records()
        payload = to_ndjson(records, snapshot_hour, pendulum.now("UTC"))
        uri = upload_to_gcs(BUCKET, build_object_path(snapshot_hour), payload, PROJECT)
        return {"uri": uri, "snapshot_hour": snapshot_hour.isoformat(), "n_records": len(records)}

    @task
    def load_to_bigquery(extracted: dict) -> int:
        from velib.load import load_snapshot

        return load_snapshot(
            gcs_uri=extracted["uri"],
            project=PROJECT,
            dataset=RAW_DATASET,
            snapshot_hour=pendulum.parse(extracted["snapshot_hour"]),
            location=LOCATION,
        )

    dbt_build = BashOperator(task_id="dbt_build", bash_command=DBT_CMD)

    load_to_bigquery(extract_to_gcs()) >> dbt_build


velib_elt()
