{% macro oracle__snapshot_merge_sql(target, source, insert_cols) -%}
    {%- set insert_cols_csv = [] -%}
    
    {% for column in insert_cols %}
      {% do insert_cols_csv.append("s." + column) %}
    {% endfor %}

    {%- set dest_cols_csv = [] -%}
    
    {% for column in insert_cols %}
      {% do dest_cols_csv.append("d." + column) %}
    {% endfor %}

    merge into {{ target }} d
    using {{ source }} s
    on (s.dbt_scd_id = d.dbt_scd_id)

    when matched
        then update
        set dbt_valid_to = s.dbt_valid_to
        where d.dbt_valid_to is null
          and s.dbt_change_type in ('update', 'delete')
    when not matched
        then insert ({{ dest_cols_csv | join(', ') }})
        values ({{ insert_cols_csv | join(', ') }})
        where s.dbt_change_type = 'insert'
{% endmacro %}