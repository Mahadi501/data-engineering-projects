{{
    config(
        materialized='incremental',
        unique_key='WORKER_ID',
        incremental_strategy = 'merge'
    )
}}

with silver_workers_incremental as 
(
select 
WORKER_ID,
GENDER,
AGE_GROUP,
OCCUPATION,
POSTCODE,
EMPLOYEMENT_TYPE,
HIRE_DATE,
SOURCE_FILE_NAME,
LOADED_AT_TIMESTAMP,
RECORD_LOADED_TIMESTAMP,
BATCH_ID,
SOURCE_SYSTEM
from {{ ref('stg_workers') }}

{% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where RECORD_LOADED_TIMESTAMP > (select dateadd('day',-2,max(RECORD_LOADED_TIMESTAMP)) from {{ this }}) 
{% endif %}

),
silver_employers as 
(
select 
* 
from silver_workers_incremental
qualify row_number() over(partition by WORKER_ID order by LOADED_AT_TIMESTAMP desc,RECORD_LOADED_TIMESTAMP desc) = 1
)


select * from silver_employers