{% macro amount_bucket(amount_column) %}
case
    when {{ amount_column }} < 10 then 'xs'
    when {{ amount_column }} < 50 then 's'
    when {{ amount_column }} < 100 then 'm'
    when {{ amount_column }} < 500 then 'l'
    else 'xl'
end
{% endmacro %}

{% macro is_large_amount(amount_column) %}
if(
    {{ amount_column }} >= {{ var('large_amount_threshold') }},
    toUInt8(1),
    toUInt8(0)
)
{% endmacro %}
