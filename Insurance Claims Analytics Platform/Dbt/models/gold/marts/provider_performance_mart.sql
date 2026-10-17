with provider_payments as 
(
select 
provider.PROVIDER_ID,
provider.SPECIALITY,
provider.PROVIDER_STATUS,
payment.PAYMENT_ID,
payment.CLAIM_ID,
payment.PAYMENT_AMOUNT,
from {{ ref('dim_provider') }} as provider
left join  {{ ref('fact_payment') }} as payment
on payment.provider_sk = provider.provider_sk
and payment.PAYMENT_STATUS = 'APPROVED'
),
-- overall metrics
provider_metrics as 
(
select 
PROVIDER_ID,
'OVERALL' AS dimension,
'ALL' AS dimension_value,
count(distinct CLAIM_ID) as total_claims,
sum(PAYMENT_AMOUNT) as total_payments,
count(distinct SPECIALITY) as provider_speciality_count
from provider_payments
group by PROVIDER_ID

union all 
-- provider status
select 
PROVIDER_ID,
'PROVIDER_STATUS' AS dimension,
coalesce(PROVIDER_STATUS,'UNKNOWN') as dimension_value,
count(distinct CLAIM_ID) as total_claims,
sum(PAYMENT_AMOUNT) as total_payments,
count(distinct SPECIALITY) as provider_speciality_count
from provider_payments
group by PROVIDER_ID,PROVIDER_STATUS

UNION ALL 
-- PROVIDER SPECIALITY
select 
PROVIDER_ID,
'PROVIDER_SPECIALITY' AS dimension,
coalesce(SPECIALITY,'UNKNOWN') as dimension_value,
count(distinct CLAIM_ID) as total_claims,
sum(PAYMENT_AMOUNT) as total_payments,
count(distinct SPECIALITY) as provider_speciality_count
FROM provider_payments
GROUP BY PROVIDER_ID,SPECIALITY
)
select * from provider_metrics


