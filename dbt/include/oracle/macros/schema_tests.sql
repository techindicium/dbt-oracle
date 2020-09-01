
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

select count(*) as validation_errors
from validation_errors

{% endmacro %}



{% macro oracle__test_not_null(model) %}

{% set column_name = kwargs.get('column_name', kwargs.get('arg')) %}

select count(*) as validation_errors
from {{ model.include(False, True, True) }}
where {{ column_name }} is null

{% endmacro %}

{% macro oracle__test_relationships(model, to, field) %}
  {% set column_name = kwargs.get('column_name', kwargs.get('from')) %}
  select count(*) as validation_errors
  from (
      select {{ column_name }} as id from {{ model.include(False, True, True) }}
  ) child
  left join (
      select {{ field }} as id from {{ to.include(False, True, True) }}
  ) parent on parent.id = child.id
  where child.id is not null
    and parent.id is null
{% endmacro %}
