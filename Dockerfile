FROM apache/airflow:2.10.5-python3.11

# dbt vit dans son propre venv pour éviter les conflits de dépendances avec Airflow
RUN python -m venv /home/airflow/dbt_venv \
    && /home/airflow/dbt_venv/bin/pip install --no-cache-dir dbt-bigquery==1.9.1

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

ENV PATH="/home/airflow/dbt_venv/bin:${PATH}"
