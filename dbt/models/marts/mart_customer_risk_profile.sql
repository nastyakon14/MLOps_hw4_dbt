{{
    config(
        materialized='table',
        engine='MergeTree()',
        order_by='(customer_id)'
    )
}}

with customers as (
    select
        customer_id,
        any(name_1) as first_name,
        any(name_2) as last_name,
        any(gender) as gender,
        any(us_state) as us_state,
        count(*) as txn_count,
        countIf(is_fraud = 1) as fraud_count,
        round(sum(amount), 2) as total_amount,
        round(avg(amount), 2) as avg_amount,
        min(transaction_time) as first_transaction_at,
        max(transaction_time) as last_transaction_at
    from {{ ref('stg_transactions') }}
    group by customer_id
)

select
    customer_id,
    first_name,
    last_name,
    gender,
    us_state,
    txn_count,
    fraud_count,
    total_amount,
    avg_amount,
    first_transaction_at,
    last_transaction_at,
    {{ fraud_rate('fraud_count', 'txn_count') }} as fraud_rate,
    {{ risk_segment(fraud_rate('fraud_count', 'txn_count'), 'fraud_count') }} as risk_segment
from customers
