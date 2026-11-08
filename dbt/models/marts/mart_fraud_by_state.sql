{{
    config(
        materialized='table',
        engine='MergeTree()',
        order_by='(us_state)'
    )
}}

with by_state as (
    select
        us_state,
        count(*) as txn_count,
        countIf(is_fraud = 1) as fraud_count,
        uniqExact(customer_id) as unique_customers,
        uniqExact(merch) as unique_merchants,
        round(sum(amount), 2) as total_amount,
        round(sumIf(amount, is_fraud = 1), 2) as fraud_amount
    from {{ ref('stg_transactions') }}
    group by us_state
)

select
    by_state.us_state,
    states.state_name,
    states.census_region,
    by_state.txn_count,
    by_state.fraud_count,
    by_state.unique_customers,
    by_state.unique_merchants,
    by_state.total_amount,
    by_state.fraud_amount,
    {{ fraud_rate('by_state.fraud_count', 'by_state.txn_count') }} as fraud_rate
from by_state
inner join {{ ref('states') }} as states
    on by_state.us_state = states.state_code
