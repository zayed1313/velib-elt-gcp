.PHONY: setup up down logs trigger test lint dbt-parse

setup:
	cp -n .env.example .env || true
	@echo "Édite .env puis place ta clé de service dans secrets/gcp-key.json"

up:
	docker compose up -d --build
	@echo "Airflow : http://localhost:8080"

down:
	docker compose down

logs:
	docker compose logs -f airflow-scheduler

trigger:
	docker compose exec airflow-scheduler airflow dags trigger velib_elt

test:
	python -m pytest -q

lint:
	ruff check .
