{{
    config(
        materialized='incremental',
        unique_key='EMPLOYER_ID',
        incremental_strategy = 'merge'
    )
}}

with incrmntl_emloyers_src as 
(
select 
EMPLOYER_ID,
ABN,
EMPLOYER_NAME ,
INDUSTRY,
REGION,
employer_size,
EMPLOYEE_COUNT,
EFFECTIVE_DATE,
LAST_UPDATED_DATE,
SOURCE_FILE_NAME,
LOADED_AT_TIMESTAMP,
RECORD_LOADED_TIMESTAMP,
BATCH_ID,
SOURCE_SYSTEM
from {{ ref('stg_employers') }}

{% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where RECORD_LOADED_TIMESTAMP > (select dateadd(day,-2,max(RECORD_LOADED_TIMESTAMP)) from {{ this }}) 
{% endif %}
),
silver_employers as 
(
select 
*
from 
incrmntl_emloyers_src
qualify row_number() over(partition by EMPLOYER_ID order by LOADED_AT_TIMESTAMP desc,RECORD_LOADED_TIMESTAMP desc) = 1
)

select * from silver_employers