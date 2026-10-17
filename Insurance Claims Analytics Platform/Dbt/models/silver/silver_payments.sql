{{
    config(
        materialized='incremental',
        unique_key='payment_id',
        incremental_strategy = 'merge'
    )
}}
with intrmdt_payments_cte as 
(
select 
PAYMENT_ID,
CLAIM_ID,
CLAIM_NUMBER,
AFFLICATION_NATURE_CD,
AFFLICATION_DATE,
LODGEMENT_DATE,
CLAIM_MANAGER,
CLAIM_LIABILITY_STATUS,
CLAIM_TYPE,
PAYMENT_DATE,
PAYMENT_TYPE,
PAYMENT_AMOUNT,
PROVIDER_ID,
PAYMENT_STATUS,
CREATED_TIMESTAMP,
SOURCE_FILE_NAME,
LOADED_AT_TIMESTAMP,
RECORD_LOADED_TIMESTAMP,
BATCH_ID,
SOURCE_SYSTEM
from {{ ref('int_payment_details') }}

{% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where RECORD_LOADED_TIMESTAMP > (select dateadd(day,-2,max(RECORD_LOADED_TIMESTAMP)) from {{ this }}) 
{% endif %}

),
silver_payments as 
(
select
*
from intrmdt_payments_cte
qualify row_number() over(partition by payment_id order by LOADED_AT_TIMESTAMP desc, RECORD_LOADED_TIMESTAMP desc) = 1
)

select * from silver_payments

