
{% macro oracle__test_accepted_values(model, values) %}

{% set column_name = kwargs.get('column_name', kwargs.get('field')) %}
{% set quote_values = kwargs.get('quote', True) %}

with all_values as (

    select distinct
        {{ column_name }} as value_field

    from {{ model.include(False, True, True) }}

),

validation_errors as (

    select
        value_field

    from all_values
    where value_field not in (
        {% for value in values -%}
            {% if quote_values -%}
            '{{ value }}'
            {%- else -%}
            {{ value }}
            {%- endif -%}
            {%- if not loop.last -%},{%- endif %}
        {%- endfor %}
    )
)

select count(*)
from validation_errors

{% endmacro %}



{% macro oracle__test_not_null(model) %}

{% set column_name = kwargs.get('column_name', kwargs.get('arg')) %}

select count(*)
from {{ model.include(False, True, True) }}
where {{ column_name }} is null

{% endmacro %}
