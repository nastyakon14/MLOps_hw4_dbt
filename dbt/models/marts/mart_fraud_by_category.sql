{{
    config(
        materialized='table',
        engine='MergeTree()',
        order_by='(cat_id)'
    )
}}

with by_category as (
    select
        cat_id,
        count(*) as txn_count,
        countIf(is_fraud = 1) as fraud_count,
        round(sum(amount), 2) as total_amount,
        round(sumIf(amount, is_fraud = 1), 2) as fraud_amount,
        round(avg(amount), 2) as avg_amount,
        {{ fraud_rate('countIf(is_fraud = 1)', 'count(*)') }} as fraud_rate
    from {{ ref('stg_transactions') }}
    group by cat_id
)

select
    cat_id,
    txn_count,
    fraud_count,
    total_amount,
    fraud_amount,
    avg_amount,
    fraud_rate,
    row_number() over (
        order by fraud_rate desc, cat_id asc
    ) as fraud_rank
from by_category
