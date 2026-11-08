{% macro risk_segment(fraud_rate_pct, fraud_count) %}
cast(
    case
        when {{ fraud_rate_pct }} >= {{ var('risk_high_rate') }} then 'HIGH'
        when {{ fraud_count }} >= 1 then 'MEDIUM'
        else 'LOW'
    end as String
)
{% endmacro %}
