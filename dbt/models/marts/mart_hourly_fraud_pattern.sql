{{
    config(
        materialized='table',
        engine='MergeTree()',
        order_by='(day_of_week, hour_of_day)'
    )
}}

with slots as (
    select
        day_of_week,
        transaction_hour as hour_of_day,
        any(day_name) as day_name,
        count(*) as txn_count,
        countIf(is_fraud = 1) as fraud_count,
        round(sum(amount), 2) as total_amount
    from {{ ref('stg_transactions') }}
    group by
        day_of_week,
        transaction_hour
),

overall_rates as (
    select
        sum(fraud_count) as fraud_count,
        sum(txn_count) as txn_count
    from slots
)

select
    slots.day_of_week,
    slots.day_name,
    slots.hour_of_day,
    slots.txn_count,
    slots.fraud_count,
    slots.total_amount,
    {{ fraud_rate('slots.fraud_count', 'slots.txn_count') }} as fraud_rate,
    if(
        slots.txn_count >= {{ var('hourly_min_transactions') }}
        and slots.fraud_count > 0
        and toFloat64(slots.fraud_count) / toFloat64(slots.txn_count)
        >= if(
            overall_rates.txn_count = 0,
            toFloat64(0),
            toFloat64(overall_rates.fraud_count) / toFloat64(overall_rates.txn_count)
        ) * {{ var('hourly_risk_multiplier') }},
        toUInt8(1),
        toUInt8(0)
    ) as is_elevated_risk
from slots
cross join overall_rates
