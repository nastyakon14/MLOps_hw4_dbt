{% macro fraud_rate(fraud_count, total_count) -%}
cast(
    if(
        {{ total_count }} = 0,
        toFloat64(0),
        round(100.0 * {{ fraud_count }} / {{ total_count }}, 2)
    ) as Float64
)
{%- endmacro %}
