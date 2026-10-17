with employer as (
select 
EMPLOYER_ID,
ABN,
EMPLOYER_NAME ,
INDUSTRY,
REGION,
employer_size,
EMPLOYEE_COUNT,
EFFECTIVE_DATE,
LAST_UPDATED_DATE
from {{ ref('silver_employers') }}
)
select 
{{dbt_utils.generate_surrogate_key(['EMPLOYER_ID'])}} as employer_sk,
EMPLOYER_ID,
ABN,
EMPLOYER_NAME ,
INDUSTRY,
REGION,
employer_size,
EMPLOYEE_COUNT
from employer
