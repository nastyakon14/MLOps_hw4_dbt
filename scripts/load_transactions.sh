#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA_CSV="${DATA_CSV:-$ROOT/../hw2/data/train.csv}"

if [[ ! -f "$DATA_CSV" ]]; then
  echo "CSV не найден: $DATA_CSV" >&2
  echo "Положите train.csv из домашки по ClickHouse или задайте DATA_CSV." >&2
  exit 1
fi

cd "$ROOT"
docker compose up -d

for _ in $(seq 1 60); do
  if docker compose exec -T clickhouse clickhouse-client --password dbt --query "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

docker compose exec -T clickhouse clickhouse-client --password dbt --multiquery --query "
CREATE DATABASE IF NOT EXISTS transactions_db;
DROP TABLE IF EXISTS transactions_db.transactions;
CREATE TABLE transactions_db.transactions
(
    transaction_time DateTime,
    merch String,
    cat_id String,
    amount Float64,
    name_1 String,
    name_2 String,
    gender String,
    us_state String,
    lat Float64,
    lon Float64,
    merchant_lat Float64,
    merchant_lon Float64,
    target UInt8
)
ENGINE = MergeTree
ORDER BY (us_state, cat_id, transaction_time);
"

docker compose exec -T clickhouse clickhouse-client --password dbt --query "
INSERT INTO transactions_db.transactions
(
    transaction_time,
    merch,
    cat_id,
    amount,
    name_1,
    name_2,
    gender,
    us_state,
    lat,
    lon,
    merchant_lat,
    merchant_lon,
    target
)
SELECT
    parseDateTimeBestEffort(transaction_time) AS transaction_time,
    merch,
    cat_id,
    toFloat64(amount) AS amount,
    name_1,
    name_2,
    gender,
    us_state,
    toFloat64(lat) AS lat,
    toFloat64(lon) AS lon,
    toFloat64(merchant_lat) AS merchant_lat,
    toFloat64(merchant_lon) AS merchant_lon,
    toUInt8(target) AS target
FROM input('transaction_time String, merch String, cat_id String, amount String, name_1 String, name_2 String, gender String, street String, one_city String, us_state String, post_code String, lat String, lon String, population_city String, jobs String, merchant_lat String, merchant_lon String, target String')
FORMAT CSVWithNames
" < "$DATA_CSV"

docker compose exec -T clickhouse clickhouse-client --password dbt --query "
SELECT count() AS rows, sum(target) AS frauds
FROM transactions_db.transactions
FORMAT PrettyCompact
"
