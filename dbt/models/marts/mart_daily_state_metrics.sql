{{
    config(
        materialized='table',
        engine='MergeTree()',
        order_by='(metric_date, us_state)'
    )
}}

select
    transaction_date as metric_date,
    us_state,
    count(*) as txn_count,
    countIf(is_fraud = 1) as fraud_count,
    round(sum(amount), 2) as total_amount,
    round(avg(amount), 2) as avg_amount,
    round(quantileExact(0.95) (amount), 2) as p95_amount,
    {{ fraud_rate('countIf(is_fraud = 1)', 'count(*)') }} as fraud_rate,
    round(100.0 * countIf(is_large_transaction = 1) / count(*), 2) as large_txn_share
from {{ ref('stg_transactions') }}
group by
    transaction_date,
    us_state
