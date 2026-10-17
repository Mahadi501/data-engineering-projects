with fact_payment as 
(
select 
payment.PAYMENT_ID,
payment.CLAIM_ID,
payment.CLAIM_NUMBER,
injury.AFFLICATION_NATURE_CD_sk,
provider.provider_sk,
payment.CLAIM_MANAGER,
payment.CLAIM_LIABILITY_STATUS,
payment.CLAIM_TYPE,
payment.PAYMENT_DATE,
payment.PAYMENT_TYPE,
payment.PAYMENT_AMOUNT,
payment.PAYMENT_STATUS
from {{ ref('silver_payments') }} as payment
inner join {{ ref('dim_injury') }} as injury
on payment.AFFLICATION_NATURE_CD = injury.AFFLICATION_NATURE_CD
inner join {{ ref('dim_provider') }} as provider
on payment.PROVIDER_ID = provider.PROVIDER_ID
)
select * from fact_payment