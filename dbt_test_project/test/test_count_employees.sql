SELECT * FROM (
    select count(*) as count from {{ref('table_relation')}}
) c WHERE c.count != 5