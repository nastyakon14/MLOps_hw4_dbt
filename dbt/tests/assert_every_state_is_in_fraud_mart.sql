select staging_states.us_state
from (
    select distinct us_state
    from {{ ref('stg_transactions') }}
) as staging_states
left join {{ ref('mart_fraud_by_state') }} as fraud_by_state
    on staging_states.us_state = fraud_by_state.us_state
where fraud_by_state.us_state is null
