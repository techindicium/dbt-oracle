
{% macro oracle_incremental_upsert_backup(tmp_relation, target_relation, unique_key=none, statement_name="main") %}
    {%- set dest_columns = adapter.get_columns_in_relation(target_relation) -%}
    {%- set dest_cols_csv = dest_columns | map(attribute='name') | join(', ') -%}

    {%- if unique_key is not none -%}
    delete
    from {{ target_relation }}
    where ({{ unique_key }}) in (
        select ({{ unique_key }})
        from {{ tmp_relation }}
    );
    {%- endif %}

    insert into {{ target_relation }} ({{ dest_cols_csv }})
    (
       select {{ dest_cols_csv }}
       from {{ tmp_relation }}
    )
{%- endmacro %}

{% macro oracle_incremental_upsert(tmp_relation, target_relation, unique_key=none, statement_name="main") %}
    {%- set dest_columns = adapter.get_columns_in_relation(target_relation) -%}
    {%- set dest_cols_csv = dest_columns | map(attribute='name') | join(', ') -%}

    {%- if unique_key is not none -%}
    merge into {{ target_relation }} target
      using {{ tmp_relation }} temp
      on (temp.{{ unique_key }} = target.{{ unique_key }})
    when matched then
      update set
      {% for col in dest_columns if col.name != unique_key %}
        target.{{ col.name }} = temp.{{ col.name }}
        {% if not loop.last %}, {% endif %}
      {% endfor %}
    when not matched then
      insert( {{ dest_cols_csv }} )
      values(
        {% for col in dest_columns %}
          temp.{{ col.name }}
          {% if not loop.last %}, {% endif %}
        {% endfor %}
      )
    {%- else %}
    insert into {{ target_relation }} ({{ dest_cols_csv }})
    (
       select {{ dest_cols_csv }}
       from {{ tmp_relation }}
    )
    {% endif %}
{%- endmacro %}
