select
*
from {{ ref('silver_employers') }}
where EMPLOYEE_COUNT < 0
