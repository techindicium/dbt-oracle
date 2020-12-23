{% macro oracle__get_columns_in_query(select_sql) %}
    {% call statement('get_columns_in_query', fetch_result=True, auto_begin=False) -%}
        select * from (
            {{ select_sql }}
        ) __dbt_sbq
        where 1 = 0 and rownum < 1
    {% endcall %}

    {{ return(load_result('get_columns_in_query').table.columns | map(attribute='name') | lower | list) }}
{% endmacro %}

{% macro oracle__create_schema(database_name, schema_name) -%}
  {% set typename = adapter.type() %}
  {% set msg -%}
    create_schema not implemented for {{ typename }}
  {%- endset %}

  {{ exceptions.raise_compiler_error(msg) }}
{% endmacro %}

{% macro oracle__drop_schema(database_name, schema_name) -%}
  {% set typename = adapter.type() %}
  {% set msg -%}
    drop_schema  not implemented for {{ typename }}
  {%- endset %}

  {{ exceptions.raise_compiler_error(msg) }}
{% endmacro %}

{% macro oracle__create_table_as_backup(temporary, relation, sql) -%}
  {%- set sql_header = config.get('sql_header', none) -%}

  {{ sql_header if sql_header is not none }}

  create {% if temporary -%}
    global temporary 
  {%- endif %} table {{ relation.include(schema=(not temporary)).quote(schema=False, identifier=False) }}
  {% if temporary -%} on commit preserve rows {%- endif %}
  as 
    {{ sql }}
  
{%- endmacro %}

{% macro oracle__create_table_as(temporary, relation, sql) -%}
  {%- set sql_header = config.get('sql_header', none) -%}

  {{ sql_header if sql_header is not none }}

  create table {{ relation.quote(schema=False, identifier=False) }}
  as 
    {{ sql }}
  
{%- endmacro %}
{% macro oracle__create_view_as(relation, sql) -%}
  {%- set sql_header = config.get('sql_header', none) -%}

  {{ sql_header if sql_header is not none }}
  create view {{ relation.quote(schema=False, identifier=False)  }} as 
    {{ sql }}
  
{% endmacro %}

{% macro oracle__get_columns_in_relation(relation) -%}
  {% call statement('get_columns_in_relation', fetch_result=True) %}
      with columns as (
        select
            SYS_CONTEXT('userenv', 'DB_NAME') table_catalog,
            owner table_schema,
            table_name,
            column_name,
            data_type,
            data_type_mod,
            decode(data_type_owner, null, TO_CHAR(null), SYS_CONTEXT('userenv', 'DB_NAME')) domain_catalog,
            data_type_owner domain_schema,
            data_length character_maximum_length,
            data_length character_octet_length,
            data_length,
            data_precision numeric_precision,
            data_scale numeric_scale,
            nullable is_nullable,
            column_id ordinal_position,
            default_length,
            data_default column_default,
            num_distinct,
            low_value,
            high_value,
            density,
            num_nulls,
            num_buckets,
            last_analyzed,
            sample_size,
            SYS_CONTEXT('userenv', 'DB_NAME') character_set_catalog,
            'SYS' character_set_schema,
            SYS_CONTEXT('userenv', 'DB_NAME') collation_catalog,
            'SYS' collation_schema,
            character_set_name,
            char_col_decl_length,
            global_stats,
            user_stats,
            avg_col_len,
            char_length,
            char_used,
            v80_fmt_image,
            data_upgraded,
            histogram
          from sys.all_tab_columns
      )
      select
          lower(column_name) as "name",
          lower(data_type) as "type",
          char_length as "character_maximum_length",
          numeric_precision as "numeric_precision",
          numeric_scale as "numeric_scale"
      from columns
      where upper(table_name) = upper('{{ relation.identifier }}')
        {% if relation.schema %}
        and upper(table_schema) = upper('{{ relation.schema }}')
        {% endif %}
        {% if relation.database %}
        and upper(table_catalog) = upper('{{ relation.database }}')
        {% endif %}
      order by ordinal_position

  {% endcall %}
  {% set table = load_result('get_columns_in_relation').table %}
  {{ return(sql_convert_columns_in_relation(table)) }}
{% endmacro %}

{% macro oracle_escape_comment(comment) -%}
  {% if comment is not string %}
    {% do exceptions.raise_compiler_error('cannot escape a non-string: ' ~ comment) %}
  {% endif %}
  {%- set start_quote = "q'<" -%}
  {%- set end_quote = ">'" -%}
  {%- if end_quote in comment -%}
    {%- do exceptions.raise_compiler_error('The string ' ~ end_quote ~ ' is not allowed in comments.') -%}
  {%- endif -%}
  {{ start_quote }}{{ comment }}{{ end_quote }}
{%- endmacro %}

{% macro oracle__alter_relation_comment(relation, comment) %}
  {% set escaped_comment = oracle_escape_comment(comment) %}
  {# "comment on table" even for views #}
  comment on table {{ relation.quote(schema=False, identifier=False) }} is {{ escaped_comment }}
{% endmacro %}

{% macro oracle__persist_docs(relation, model, for_relation, for_columns) -%}
  {% if for_relation and config.persist_relation_docs() and model.description %}
    {% do run_query(alter_relation_comment(relation, model.description)) %}
  {% endif %}
  {% if for_columns and config.persist_column_docs() and model.columns %}
    {% set column_dict = model.columns %}
    {% for column_name in column_dict %}
      {% set comment = column_dict[column_name]['description'] %}
      {% set escaped_comment = oracle_escape_comment(comment) %}
      {% call statement('alter _column comment', fetch_result=False) -%}
        comment on column {{ relation.quote(schema=False, identifier=False) }}.{{ column_name }} is {{ escaped_comment }}
      {%- endcall %}
    {% endfor %}
  {% endif %}
{% endmacro %}

{% macro oracle__alter_column_type(relation, column_name, new_column_type) -%}
  {#
    1. Create a new column (w/ temp name and correct type)
    2. Copy data over to it
    3. Drop the existing column (cascade!)
    4. Rename the new column to existing column
  #}
  {%- set tmp_column = column_name + "__dbt_alter" -%}

  {% call statement('alter_column_type 1', fetch_result=False) %}
    alter table {{ relation.quote(schema=False, identifier=False) }} add column {{ adapter.quote(tmp_column) }} {{ new_column_type }}
  {% endcall %}
  {% call statement('alter_column_type 2', fetch_result=False) %}
    update {{ relation.quote(schema=False, identifier=False)  }} set {{ adapter.quote(tmp_column) }} = {{ adapter.quote(column_name) }}
  {% endcall %}
  {% call statement('alter_column_type 3', fetch_result=False) %}
    alter table {{ relation.quote(schema=False, identifier=False) }} drop column {{ adapter.quote(column_name) }} cascade
  {% endcall %}
  {% call statement('alter_column_type 4', fetch_result=False) %}
    rename column {{ relation.quote(schema=False, identifier=False) }}.{{ adapter.quote(tmp_column) }} to {{ adapter.quote(column_name) }}
  {% endcall %}

{% endmacro %}

{% macro oracle__drop_relation(relation) -%}
  {% call statement('drop_relation', auto_begin=False) -%}
   DECLARE
     dne_942    EXCEPTION;
     PRAGMA EXCEPTION_INIT(dne_942, -942);
  BEGIN
     EXECUTE IMMEDIATE 'DROP {{ relation.type }} {{ relation.quote(schema=False, identifier=False) }} cascade constraint';
  EXCEPTION
     WHEN dne_942 THEN
        NULL; -- if it doesn't exist, do nothing .. no error, nothing .. ignore.
  END;
  {%- endcall %}
{% endmacro %}

{% macro oracle__truncate_relation(relation) -%}
  {% call statement('truncate_relation') -%}
    truncate table {{ relation.quote(schema=False, identifier=False) }}
  {%- endcall %}
{% endmacro %}

{% macro oracle__rename_relation(from_relation, to_relation) -%}
  {% call statement('rename_relation') -%}
    rename {{ from_relation.include(False, False, True).quote(schema=False, identifier=False) }} to {{ to_relation.include(False, False, True).quote(schema=False, identifier=False) }}
  {%- endcall %}
{% endmacro %}

{% macro oracle__information_schema_name(database) -%}
  {% if database -%}
    {{ adapter.verify_database(database) }}
  {%- endif -%}
  sys
{%- endmacro %}

{% macro oracle__list_schemas(database) %}
  {% if database -%}
    {{ adapter.verify_database(database) }}
  {%- endif -%}
  {% call statement('list_schemas', fetch_result=True, auto_begin=False) -%}
     	select lower(username) as "name"
      from sys.all_users
      order by username
  {% endcall %}
  {{ return(load_result('list_schemas').table) }}
{% endmacro %}

{% macro oracle__check_schema_exists(information_schema, schema) -%}
  {% if information_schema.database -%}
    {{ adapter.verify_database(information_schema.database) }}
  {%- endif -%}
  {% call statement('check_schema_exists', fetch_result=True, auto_begin=False) %}
    select count(*) from sys.all_users where username = upper('{{ schema }}')
  {% endcall %}
  {{ return(load_result('check_schema_exists').table) }}
{% endmacro %}

{% macro oracle__list_relations_without_caching(schema_relation) %}
  {% call statement('list_relations_without_caching', fetch_result=True) -%}
    with tables as
      (select SYS_CONTEXT('userenv', 'DB_NAME') table_catalog,
         owner table_schema,
         table_name,
         case
           when iot_type = 'Y'
           then 'IOT'
           when temporary = 'Y'
           then 'TEMP'
           else 'BASE TABLE'
         end table_type
       from sys.all_tables
       union all
       select SYS_CONTEXT('userenv', 'DB_NAME'),
         owner,
         view_name,
         'VIEW'
       from sys.all_views
  )
  select lower(table_catalog) as "database_name"
    ,lower(table_name) as "name"
    ,lower(table_schema) as "schema_name"
    ,case table_type
      when 'BASE TABLE' then 'table'
      when 'VIEW' then 'view'
    end as "kind"
  from tables
  where table_type in ('BASE TABLE', 'VIEW')
    and upper(table_catalog) = upper('{{ schema_relation.database }}')
    and upper(table_schema) = upper('{{ schema_relation.schema }}')
  {% endcall %}
  {{ return(load_result('list_relations_without_caching').table) }}
{% endmacro %}

{% macro oracle__current_timestamp() -%}
  CURRENT_DATE
{%- endmacro %}

{% macro oracle__make_temp_relation(base_relation, suffix) %}
    {% set tmp_identifier = 'ora$ptt_' ~ base_relation.identifier %}
    {% set tmp_relation = base_relation.incorporate(
                                path={"identifier": tmp_identifier}) -%}

    {% do return(tmp_relation) %}
{% endmacro %}
