import json
from datetime import datetime, timezone

import pytest

from velib.extract import FIELDS, build_object_path, to_ndjson

HOUR = datetime(2026, 10, 15, 14, 0, tzinfo=timezone.utc)
NOW = datetime(2026, 10, 15, 14, 3, 12, tzinfo=timezone.utc)

RECORD = {
    "stationcode": "12345",
    "name": "Rivoli - Louvre",
    "is_installed": "OUI",
    "capacity": 30,
    "numdocksavailable": 10,
    "numbikesavailable": 20,
    "mechanical": 15,
    "ebike": 5,
    "is_renting": "OUI",
    "is_returning": "OUI",
    "duedate": "2026-10-15T14:00:00+00:00",
    "coordonnees_geo": {"lon": 2.34, "lat": 48.86},
    "nom_arrondissement_communes": "Paris",
    "code_insee_commune": "75056",
    "champ_inconnu": "doit être ignoré",
}


def test_to_ndjson_keeps_only_known_fields_and_adds_metadata():
    out = to_ndjson([RECORD], HOUR, NOW)
    row = json.loads(out.strip())
    assert set(row) == set(FIELDS) | {"snapshot_hour", "ingested_at"}
    assert "champ_inconnu" not in row
    assert row["snapshot_hour"] == HOUR.isoformat()


def test_to_ndjson_one_line_per_record():
    out = to_ndjson([RECORD, RECORD, RECORD], HOUR, NOW)
    assert len(out.strip().splitlines()) == 3


def test_missing_fields_become_null():
    row = json.loads(to_ndjson([{"stationcode": "1"}], HOUR, NOW))
    assert row["capacity"] is None


def test_object_path_is_deterministic_and_partitioned():
    path = build_object_path(HOUR)
    assert path == "raw/velib/dt=2026-10-15/hour=14/velib_20261015T14.ndjson"
    assert build_object_path(HOUR) == path


@pytest.mark.parametrize("bad", [[], {}, None])
def test_fetch_records_rejects_empty(monkeypatch, bad):
    import velib.extract as extract

    class FakeResponse:
        def raise_for_status(self):
            pass

        def json(self):
            return bad

    monkeypatch.setattr(extract.requests, "get", lambda *a, **k: FakeResponse())
    with pytest.raises(ValueError):
        extract.fetch_records()
