select p.employee_id, j.job_id, j.salary from {{ ref('jobs') }} j
join {{ref('person')}} p
on p.employee_id = j.employee_id