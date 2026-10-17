with dim_worker as 
(
select
{{dbt_utils.generate_surrogate_key(['WORKER_ID'])}} as worker_sk,
WORKER_ID,
GENDER,
AGE_GROUP,
OCCUPATION,
POSTCODE,
EMPLOYEMENT_TYPE,
HIRE_DATE
from {{ ref('silver_workers') }}
)
select * from dim_worker