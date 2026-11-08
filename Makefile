VENV := $(CURDIR)/.venv
DBT := $(VENV)/bin/dbt
SQLFLUFF := $(VENV)/bin/sqlfluff
export DBT_PROFILES_DIR := $(CURDIR)/dbt

.PHONY: help install clickhouse load deps seed run test unit-test docs docs-serve lint fix all

help:
	@echo "make install     venv + зависимости"
	@echo "make load        ClickHouse и загрузка CSV в transactions_db.transactions"
	@echo "make all         dbt deps, seed, run, test"
	@echo "make lint        sqlfluff"
	@echo "make docs-serve  документация на http://127.0.0.1:8085"

install:
	python3 -m venv $(VENV)
	$(VENV)/bin/pip install -U pip
	$(VENV)/bin/pip install -r requirements.txt

clickhouse:
	docker compose up -d

load: clickhouse
	./scripts/load_transactions.sh

deps:
	cd dbt && $(DBT) deps

seed:
	cd dbt && $(DBT) seed --full-refresh

run:
	cd dbt && $(DBT) run

unit-test:
	cd dbt && $(DBT) test --select test_type:unit

test:
	cd dbt && $(DBT) test

docs:
	cd dbt && $(DBT) docs generate

docs-serve:
	cd dbt && $(DBT) docs serve --port 8085

lint:
	cd dbt && $(SQLFLUFF) lint models tests

fix:
	cd dbt && $(SQLFLUFF) fix models tests

all: deps seed run test
