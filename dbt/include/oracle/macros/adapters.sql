{% macro oracle__list_schemas(database) %}
    {% call statement('list_schemas', fetch_result=True, auto_begin=False) -%}
       	select username as schema_name
        from sys.all_users
        order by username
    {% endcall %}
    {{ return(load_result('list_schemas').table) }}
{% endmacro %}

{% macro oracle__create_schema(database_name, schema_name) -%}
  {% call statement('create_schema') -%}
    select 1 from dual -- just trying to do nothing for now
  {% endcall %}
{% endmacro %}


{% macro oracle__list_relations_without_caching(information_schema, schema) %}
  {% call statement('list_relations_without_caching', fetch_result=True) -%}
    SELECT 
      '{{ database }}' as database,
      lower(object_name),
      lower(owner),
      lower(object_type) as table_type
    FROM
      all_objects 
    where
      OWNER = (SELECT USER FROM dual)
  {% endcall %}
  {{ return(load_result('list_relations_without_caching').table) }}
{% endmacro %}

{% macro oracle__drop_relation(relation) -%}
  {% call statement('drop_relation', auto_begin=False) -%}
   DECLARE
     dne_942    EXCEPTION;
     PRAGMA EXCEPTION_INIT(dne_942, -942);
  BEGIN
     EXECUTE IMMEDIATE 'DROP {{ relation.type }} {{ relation }} cascade constraint';
  EXCEPTION
     WHEN dne_942 THEN
        NULL; -- if it doesn't exist, do nothing .. no error, nothing .. ignore.
  END;
  {%- endcall %}
{% endmacro %}

{% macro oracle__create_table_as(temporary, relation, sql) -%}
  {%- set sql_header = config.get('sql_header', none) -%}

  {{ sql_header if sql_header is not none }}

  create {% if temporary: -%}temporary{%- endif %} table
    {{ relation.include(database=False, schema=(not temporary)) }}
  as 
    {{ sql }}
  
{% endmacro %}


{% macro oracle__rename_relation(from_relation, to_relation) -%}
  {% set target_name = adapter.quote_as_configured(to_relation.identifier, 'identifier') %}
  {% call statement('rename_relation') -%}
    rename {{ from_relation.include(False, False, True) }} to {{ target_name }}
  {%- endcall %}
{% endmacro %}

{% macro oracle__get_columns_in_relation(relation) -%}
  {% call statement('get_columns_in_relation', fetch_result=True) %}
      select 
		  col.column_name,
          col.data_type, 
          col.data_length, 
          col.data_precision, 
          col.data_scale
      from sys.all_tab_columns col
      WHERE col.table_name = 'TABLE_RELATION'
      AND col.owner = (SELECT USER FROM dual)
      order by col.column_id
  {% endcall %}
  {% set table = load_result('get_columns_in_relation').table %}
  {{ return(sql_convert_columns_in_relation(table)) }}
{% endmacro %}

{% macro oracle__truncate_relation(relation) -%}
  {% call statement('truncate_relation') -%}
    truncate table {{ relation | replace('"', "")  }}
  {%- endcall %}
{% endmacro %}

{% macro oracle__create_view_as(relation, sql) -%}
  {%- set sql_header = config.get('sql_header', none) -%}
  {{ sql_header if sql_header is not none }}
  create view {{ relation.render() }} as
  {{ sql | replace(""+database+".", "")}}
{% endmacro %}
