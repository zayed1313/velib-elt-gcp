"""Extraction : snapshot temps réel des stations Vélib' (Paris Open Data, sans clé API)."""
from __future__ import annotations

import json
from datetime import datetime, timezone

import requests

API_URL = (
    "https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/"
    "velib-disponibilite-en-temps-reel/exports/json"
)

FIELDS = [
    "stationcode",
    "name",
    "is_installed",
    "capacity",
    "numdocksavailable",
    "numbikesavailable",
    "mechanical",
    "ebike",
    "is_renting",
    "is_returning",
    "duedate",
    "coordonnees_geo",
    "nom_arrondissement_communes",
    "code_insee_commune",
]


def fetch_records(url: str = API_URL, timeout: int = 60) -> list[dict]:
    """Télécharge l'état courant de toutes les stations."""
    response = requests.get(url, timeout=timeout)
    response.raise_for_status()
    records = response.json()
    if not isinstance(records, list) or not records:
        raise ValueError("Réponse API vide ou inattendue")
    return records


def to_ndjson(records: list[dict], snapshot_hour: datetime, ingested_at: datetime) -> str:
    """Garde les champs utiles, ajoute les métadonnées d'ingestion (NDJSON pour BigQuery)."""
    lines = []
    for record in records:
        row = {field: record.get(field) for field in FIELDS}
        row["snapshot_hour"] = snapshot_hour.isoformat()
        row["ingested_at"] = ingested_at.isoformat()
        lines.append(json.dumps(row, ensure_ascii=False))
    return "\n".join(lines) + "\n"


def build_object_path(snapshot_hour: datetime) -> str:
    """Chemin déterministe : un rerun écrase le même objet (idempotence)."""
    h = snapshot_hour.astimezone(timezone.utc)
    return f"raw/velib/dt={h:%Y-%m-%d}/hour={h:%H}/velib_{h:%Y%m%dT%H}.ndjson"
