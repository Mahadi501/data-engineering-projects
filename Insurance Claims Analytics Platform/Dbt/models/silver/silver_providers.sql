{{
    config(
        materialized='incremental',
        unique_key='PROVIDER_ID',
        incremental_strategy = 'merge'
    )
}}

with incremental_providers as 
(
select 
PROVIDER_ID,
PROVIDER_NAME,
PROVIDER_TYPE,
SPECIALITY,
REGION,
PROVIDER_STATUS,
SOURCE_FILE_NAME,
LOADED_AT_TIMESTAMP,
RECORD_LOADED_TIMESTAMP,
BATCH_ID,
SOURCE_SYSTEM 
from {{ ref('stg_providers') }}
{% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where RECORD_LOADED_TIMESTAMP > (select dateadd('day',-2,max(RECORD_LOADED_TIMESTAMP)) from {{ this }}) 
{% endif %}

),
silver_providers as 
(
select 
*
from incremental_providers
qualify row_number() over(partition by PROVIDER_ID order by LOADED_AT_TIMESTAMP desc, RECORD_LOADED_TIMESTAMP desc) = 1
)

select * from silver_providers
