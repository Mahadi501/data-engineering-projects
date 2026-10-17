with int_provider_activity as 
(
select 
payment.PAYMENT_ID,
payment.CLAIM_ID,
claim.WORKER_ID,
claim.AFFLICATION_NATURE_CD,
claim.LODGEMENT_DATE,
claim.CLAIM_STATUS,
payment.PAYMENT_DATE,
payment.PAYMENT_TYPE,
payment.PAYMENT_AMOUNT,
payment.PAYMENT_STATUS,
payment.PROVIDER_ID,
provider.PROVIDER_NAME,
provider.PROVIDER_TYPE,
provider.SPECIALITY,
provider.REGION as provider_region
from {{ ref('stg_payments') }} as payment
left join {{ ref('stg_claims') }} as claim
on payment.CLAIM_ID = claim.CLAIM_ID
left join {{ ref('stg_providers') }} as provider
on payment.PROVIDER_ID = provider.PROVIDER_ID
)

select * from int_provider_activity