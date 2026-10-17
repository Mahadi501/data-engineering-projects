{{
    config(
        materialized='incremental',
        unique_key='EVENT_ID',
        incremental_strategy = 'merge'
    )
}}

with incrmntl_rtw_events as 
(
select 
EVENT_ID,
EVENT_TYPE,
DAYS_LOST,
EVENT_DATE,
CLAIM_ID,
CLAIM_NUMBER,
WORKER_ID,
AFFLICATION_NATURE_CD,
CLAIM_STATUS,
CLAIM_TYPE,
CLAIM_LIABILITY_STATUS,
RTW_EVENT_CREATED_TIMESTAMP,
CREATED_TIMESTAMP,
UPDATED_TIMESTAMP,
SOURCE_FILE_NAME,
LOADED_AT_TIMESTAMP,
RECORD_LOADED_TIMESTAMP,
BATCH_ID,
SOURCE_SYSTEM
from {{ ref('int_rtw_journey') }}

{% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where LOADED_AT_TIMESTAMP > (select dateadd('day',-2,max(LOADED_AT_TIMESTAMP)) from {{ this }}) 
{% endif %}
),
silver_rtw_events as 
(
select 
*
from incrmntl_rtw_events
qualify row_number() over(partition by EVENT_ID order by LOADED_AT_TIMESTAMP desc,RECORD_LOADED_TIMESTAMP desc) = 1
)
select * from silver_rtw_events