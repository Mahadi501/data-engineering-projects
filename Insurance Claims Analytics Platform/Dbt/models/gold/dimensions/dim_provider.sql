with dim_provider as 
(
select 
{{dbt_utils.generate_surrogate_key(['PROVIDER_ID'])}} as provider_sk,
PROVIDER_ID,
PROVIDER_NAME,
PROVIDER_TYPE,
SPECIALITY,
REGION,
PROVIDER_STATUS
from {{ ref('silver_providers') }}
)
select * from dim_provider