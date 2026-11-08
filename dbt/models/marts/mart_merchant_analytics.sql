{{
    config(
        materialized='table',
        engine='MergeTree()',
        order_by='(merch)'
    )
}}

with transactions as (
    select
        merch,
        cat_id,
        customer_id,
        amount,
        is_fraud
    from {{ ref('stg_transactions') }}
),

totals as (
    select
        merch,
        count(*) as txn_count,
        countIf(is_fraud = 1) as fraud_count,
        uniqExact(customer_id) as unique_customers,
        round(sum(amount), 2) as total_amount,
        round(avg(amount), 2) as avg_amount
    from transactions
    group by merch
),

category_counts as (
    select
        merch,
        cat_id,
        count(*) as cat_txn_count
    from transactions
    group by
        merch,
        cat_id
),

primary_category as (
    select
        merch,
        argMax(cat_id, cat_txn_count) as category
    from category_counts
    group by merch
)

select
    totals.merch,
    primary_category.category,
    totals.txn_count,
    totals.fraud_count,
    totals.unique_customers,
    totals.total_amount,
    totals.avg_amount,
    {{ fraud_rate('totals.fraud_count', 'totals.txn_count') }} as fraud_rate,
    if(
        totals.fraud_count >= {{ var('merchant_min_frauds') }}
        and {{ fraud_rate('totals.fraud_count', 'totals.txn_count') }}
        >= {{ var('merchant_suspicious_rate') }},
        toUInt8(1),
        toUInt8(0)
    ) as is_suspicious
from totals
inner join primary_category
    on totals.merch = primary_category.merch
