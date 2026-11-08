select
    metric_date,
    us_state,
    large_txn_share
from {{ ref('mart_daily_state_metrics') }}
where large_txn_share < 0 or large_txn_share > 100
