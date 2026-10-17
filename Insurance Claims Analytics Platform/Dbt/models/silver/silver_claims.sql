{{
    config(
        materialized='incremental',
        unique_key='claim_id',
        incremental_strategy = 'merge'
    )
}}

with int_source_claims as 
(
select 
CLAIM_ID,
CLAIM_NUMBER,
WORKER_ID,
GENDER,
AGE_GROUP,
EMPLOYEMENT_TYPE,
AFFLICATION_NATURE_CD,
INJURY_DESCRIPTION,
afflication_category,
BODY_LOCATION,
SEVERITY_CATEGORY,
AFFLICATION_DATE,
LODGEMENT_DATE,
CLAIM_STATUS,
CLAIM_TYPE,
CLAIM_LIABILITY_STATUS,
CLAIM_MANAGER,
EMPLOYER_ID,
EMPLOYER_NAME,
employer_size,
INDUSTRY,
employer_region,
CREATED_TIMESTAMP,
UPDATED_TIMESTAMP,
SOURCE_FILE_NAME,
LOADED_AT_TIMESTAMP,
RECORD_LOADED_TIMESTAMP,
BATCH_ID,
SOURCE_SYSTEM
from {{ ref('int_claim_master') }}

{% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where RECORD_LOADED_TIMESTAMP > (select dateadd(day,-2,max(RECORD_LOADED_TIMESTAMP)) from {{ this }}) 
{% endif %}

),
silver_claims as
(
select 
*
from int_source_claims
qualify row_number() over(partition by claim_id order by UPDATED_TIMESTAMP desc, RECORD_LOADED_TIMESTAMP desc) = 1
)

select * from silver_claims