select
    merch,
    fraud_count,
    fraud_rate,
    is_suspicious
from {{ ref('mart_merchant_analytics') }}
where
    (
        is_suspicious = 1
        and not (
            fraud_count >= {{ var('merchant_min_frauds') }}
            and fraud_rate >= {{ var('merchant_suspicious_rate') }}
        )
    )
    or (
        is_suspicious = 0
        and fraud_count >= {{ var('merchant_min_frauds') }}
        and fraud_rate >= {{ var('merchant_suspicious_rate') }}
    )
