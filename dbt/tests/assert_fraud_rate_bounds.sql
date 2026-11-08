select
    'mart_fraud_by_category' as model_name,
    cat_id as grain,
    fraud_rate
from {{ ref('mart_fraud_by_category') }}
where fraud_rate > 100 or fraud_rate < 0

union all

select
    'mart_fraud_by_state' as model_name,
    us_state as grain,
    fraud_rate
from {{ ref('mart_fraud_by_state') }}
where fraud_rate > 100 or fraud_rate < 0

union all

select
    'mart_customer_risk_profile' as model_name,
    customer_id as grain,
    fraud_rate
from {{ ref('mart_customer_risk_profile') }}
where fraud_rate > 100 or fraud_rate < 0

union all

select
    'mart_hourly_fraud_pattern' as model_name,
    concat(toString(day_of_week), '-', toString(hour_of_day)) as grain,
    fraud_rate
from {{ ref('mart_hourly_fraud_pattern') }}
where fraud_rate > 100 or fraud_rate < 0

union all

select
    'mart_merchant_analytics' as model_name,
    merch as grain,
    fraud_rate
from {{ ref('mart_merchant_analytics') }}
where fraud_rate > 100 or fraud_rate < 0

union all

select
    'mart_daily_state_metrics' as model_name,
    concat(toString(metric_date), '-', us_state) as grain,
    fraud_rate
from {{ ref('mart_daily_state_metrics') }}
where fraud_rate > 100 or fraud_rate < 0
