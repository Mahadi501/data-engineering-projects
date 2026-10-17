with int_payment_details as 
(
select 
payment.PAYMENT_ID,
payment.CLAIM_ID,
claim.CLAIM_NUMBER,
claim.AFFLICATION_NATURE_CD,
claim.AFFLICATION_DATE,
claim.LODGEMENT_DATE,
claim.CLAIM_MANAGER,
claim.CLAIM_LIABILITY_STATUS,
claim.CLAIM_TYPE,
payment.PAYMENT_DATE,
payment.PAYMENT_TYPE,
payment.PAYMENT_AMOUNT,
payment.PROVIDER_ID,
payment.PAYMENT_STATUS,
payment.CREATED_TIMESTAMP,
payment.SOURCE_FILE_NAME,
payment.LOADED_AT_TIMESTAMP,
payment.RECORD_LOADED_TIMESTAMP,
payment.BATCH_ID,
payment.SOURCE_SYSTEM 
from {{ ref('stg_payments') }} as payment
left join {{ ref('stg_claims') }} as claim
on payment.CLAIM_ID = claim.CLAIM_ID
)
select * from int_payment_details
