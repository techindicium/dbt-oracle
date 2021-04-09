{{
    config(
        materialized='incremental'
    )
}}


select * from {{ source('hr_database', 'employees') }}

{% if is_incremental() %}

  where employee_Id > (select max(employee_Id) from {{ this }})

{% endif %}