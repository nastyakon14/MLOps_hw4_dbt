select
    customer_id,
    fraud_count,
    fraud_rate,
    risk_segment
from {{ ref('mart_customer_risk_profile') }}
where
    (
        risk_segment = 'LOW'
        and fraud_count != 0
    )
    or (
        risk_segment = 'MEDIUM'
        and not (
            fraud_count >= 1
            and fraud_rate < {{ var('risk_high_rate') }}
        )
    )
    or (
        risk_segment = 'HIGH'
        and fraud_rate < {{ var('risk_high_rate') }}
    )
    or risk_segment not in ('LOW', 'MEDIUM', 'HIGH')
