{{ config(quoting={database:False, schema:True, identifier:False}) }}
select
    name
from {{ ref("lower")}}