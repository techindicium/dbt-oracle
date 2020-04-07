{{config(materialization='view')}}
with persons_filtered as(
    select * from {{ source('hr_database', 'employees') }}
    where employee_Id = 100
)
select * from persons_filtered