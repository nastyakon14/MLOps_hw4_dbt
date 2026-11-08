select
    day_of_week,
    hour_of_day,
    txn_count,
    fraud_count,
    is_elevated_risk
from {{ ref('mart_hourly_fraud_pattern') }}
where
    is_elevated_risk = 1
    and (
        fraud_count = 0
        or txn_count < {{ var('hourly_min_transactions') }}
    )
