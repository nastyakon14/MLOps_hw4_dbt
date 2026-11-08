# dbt: транзакции и фрод

Слой dbt поверх таблицы `transactions_db.transactions` из домашки по ClickHouse.
Сырьё — `hw2/data/train.csv` (786 431 операция, колонка `target` — фрод).

```
transactions_db.transactions → stg_transactions → витрины
```

## Реализовано

- 6 витрин
- макросы `amount_bucket`, `is_large_amount`, `fraud_rate`, `risk_segment`
- пакеты `dbt_utils`, `dbt_date`, `dbt_expectations`
- `schema.yml`: описания, `not_null`, `unique`, `accepted_values`, тесты пакетов
- singular-тесты в `dbt/tests/`
- unit-тесты dbt 1.8+ на staging и каждую витрину
- `dbt/.sqlfluff`, `.pre-commit-config.yaml`, `Makefile`

## Версии

- dbt-core 1.10.23
- dbt-clickhouse 1.10.3
- ClickHouse 25.8
- sqlfluff 3.5.0

## Запуск

Нужны Docker, Python 3.11 и CSV из hw2.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

make load
cd dbt
export DBT_PROFILES_DIR="$PWD"
dbt deps && dbt seed && dbt run && dbt test
dbt docs generate && dbt docs serve --port 8085
```

Тот же цикл из корня: `make all`, линт — `make lint`, документация — `make docs-serve`.

`make load` поднимает ClickHouse и заливает CSV. По умолчанию берётся `../hw2/data/train.csv`. Другой файл: `DATA_CSV=/path/to/train.csv make load`.

Профиль лежит в `dbt/profiles.yml`: `localhost:8123`, пользователь `default`, пароль `dbt`, база моделей `analytics`, источник `transactions_db`.

## Витрины

| Модель | Зерно | Что считает |
| --- | --- | --- |
| `mart_daily_state_metrics` | день, штат | число, сумма, средний чек, P95, доля крупных, fraud_rate |
| `mart_fraud_by_category` | категория | число, фрод, суммы, fraud_rate, ранг |
| `mart_fraud_by_state` | штат | fraud_rate, клиенты, мерчанты, суммы, регион Census |
| `mart_customer_risk_profile` | клиент | история, средний чек, fraud_rate, сегмент HIGH/MEDIUM/LOW |
| `mart_hourly_fraud_pattern` | день недели, час | fraud_rate и флаг повышенного риска |
| `mart_merchant_analytics` | мерчант | оборот, fraud_rate, флаг подозрительности |

Крупная транзакция — сумма от 100. Клиент в HIGH, если fraud_rate ≥ 20%; в MEDIUM, если фрод был, но доля ниже; в LOW, если фрода не было. Мерчант подозрителен при ≥ 3 фродах и доле ≥ 2%. Час повышенного риска — не меньше 100 операций, есть фрод, и доля хотя бы в 1.5 раза выше средней.

Корзины суммы: `xs` < 10, `s` < 50, `m` < 100, `l` < 500, иначе `xl`.

## Тесты

Generic: `not_null`, `unique`, `accepted_values`, `relationships`, `dbt_utils.unique_combination_of_columns`, `dbt_utils.accepted_range`, `dbt_utils.expression_is_true`, `dbt_expectations.expect_column_values_to_be_between`, `expect_column_values_to_be_in_set`, `expect_column_distinct_count_to_equal`, `expect_table_row_count_to_equal`, `expect_table_row_count_to_be_between`.

Singular:

- `assert_no_negative_amounts`
- `assert_fraud_rate_bounds`
- `assert_large_txn_share_bounds`
- `assert_customer_risk_segments`
- `assert_suspicious_merchant_rule`
- `assert_elevated_risk_has_volume_and_fraud`
- `assert_every_state_is_in_fraud_mart`

Unit-тесты в `dbt/models/unit_tests.yml`: корзины суммы, сегмент клиента, доля крупных, ранг категории, джойн штатов, окно повышенного риска, флаг мерчанта.

## Линт

`make lint` гоняет sqlfluff с диалектом ClickHouse и dbt-templater. pre-commit вызывает те же `sqlfluff-lint` и `sqlfluff-fix` через `.venv` (сначала `make install`).

## Документация

Скриншот DAG: `docs/screenshots/dbt_lineage.png`.
Лог `dbt test`: `docs/dbt_test.log`.
