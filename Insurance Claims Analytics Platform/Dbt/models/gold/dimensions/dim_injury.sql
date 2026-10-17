with dim_injury as 
(
select 
{{dbt_utils.generate_surrogate_key(['afflication_nature_cd'])}} afflication_nature_cd_sk,
afflication_nature_cd,
INJURY_DESCRIPTION,
afflication_category,
BODY_LOCATION,
SEVERITY_CATEGORY
from {{ ref('stg_injury_reference') }}
)
select * from dim_injury