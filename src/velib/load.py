"""Chargement GCS -> BigQuery (table raw, partitionnée par jour)."""
from __future__ import annotations

from datetime import datetime

from google.api_core.exceptions import NotFound
from google.cloud import bigquery, storage

RAW_TABLE = "velib_stations_status"

RAW_SCHEMA = [
    bigquery.SchemaField("stationcode", "STRING"),
    bigquery.SchemaField("name", "STRING"),
    bigquery.SchemaField("is_installed", "STRING"),
    bigquery.SchemaField("capacity", "INT64"),
    bigquery.SchemaField("numdocksavailable", "INT64"),
    bigquery.SchemaField("numbikesavailable", "INT64"),
    bigquery.SchemaField("mechanical", "INT64"),
    bigquery.SchemaField("ebike", "INT64"),
    bigquery.SchemaField("is_renting", "STRING"),
    bigquery.SchemaField("is_returning", "STRING"),
    bigquery.SchemaField("duedate", "TIMESTAMP"),
    bigquery.SchemaField(
        "coordonnees_geo",
        "RECORD",
        fields=[
            bigquery.SchemaField("lon", "FLOAT64"),
            bigquery.SchemaField("lat", "FLOAT64"),
        ],
    ),
    bigquery.SchemaField("nom_arrondissement_communes", "STRING"),
    bigquery.SchemaField("code_insee_commune", "STRING"),
    bigquery.SchemaField("ingested_at", "TIMESTAMP"),
    bigquery.SchemaField("snapshot_hour", "TIMESTAMP"),
]


def upload_to_gcs(bucket_name: str, object_path: str, payload: str, project: str) -> str:
    client = storage.Client(project=project)
    blob = client.bucket(bucket_name).blob(object_path)
    blob.upload_from_string(payload, content_type="application/x-ndjson")
    return f"gs://{bucket_name}/{object_path}"


def load_snapshot(
    gcs_uri: str,
    project: str,
    dataset: str,
    snapshot_hour: datetime,
    location: str = "EU",
) -> int:
    """Charge un snapshot de façon idempotente : on supprime l'heure concernée, puis on recharge."""
    client = bigquery.Client(project=project, location=location)
    table_id = f"{project}.{dataset}.{RAW_TABLE}"

    try:
        client.query(
            f"DELETE FROM `{table_id}` WHERE snapshot_hour = @hour",
            job_config=bigquery.QueryJobConfig(
                query_parameters=[bigquery.ScalarQueryParameter("hour", "TIMESTAMP", snapshot_hour)]
            ),
        ).result()
    except NotFound:
        pass  # premier run : la table n'existe pas encore, le load job la créera

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        schema=RAW_SCHEMA,
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
        create_disposition=bigquery.CreateDisposition.CREATE_IF_NEEDED,
        ignore_unknown_values=True,
        time_partitioning=bigquery.TimePartitioning(
            type_=bigquery.TimePartitioningType.DAY, field="snapshot_hour"
        ),
    )
    job = client.load_table_from_uri(gcs_uri, table_id, job_config=job_config)
    job.result()
    return job.output_rows
