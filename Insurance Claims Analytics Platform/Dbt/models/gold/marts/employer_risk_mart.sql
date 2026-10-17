with claim_payments as 
(
select 
claim_id,
sum(PAYMENT_AMOUNT) as total_payments
from {{ ref('fact_payment') }}
group by claim_id
),
employer_claims_details as 
(
select
claim.CLAIM_ID,
claim.AFFLICATION_DATE,
datediff('day',claim.AFFLICATION_DATE,claim.LODGEMENT_DATE) as lodgement_delay,
payments.total_payments,
injury.afflication_category,
employer.EMPLOYER_ID,
employer.INDUSTRY as employer_industry,
employer.REGION as employer_region,
employer.employer_size as employer_size,
employer.EMPLOYEE_COUNT
from {{ ref('dim_employer') }} as employer
left join {{ ref('fact_claim') }} as claim
on employer.employer_sk = claim.employer_sk
left join claim_payments as payments
on claim.claim_id = payments.claim_id
left join {{ ref('dim_injury') }} as injury
on claim.AFFLICATION_NATURE_CD_sk = injury.AFFLICATION_NATURE_CD_sk
),
employer_metrics as 
(
-- overall metrics    
select 
EMPLOYER_ID,
'OVERALL' AS dimension_name,
'ALL' AS DIMENSION_VALUE,
count(CLAIM_ID) as total_claims,
sum(total_payments) as total_payments_amount,
avg(lodgement_delay) as avg_lodgement_delay
from employer_claims_details
group by EMPLOYER_ID

union all 
-- industry metrics
select 
EMPLOYER_ID,
'INDUSTRY' AS dimension_name,
coalesce(employer_industry,'UNKNOWN') AS DIMENSION_VALUE,
count(CLAIM_ID) as total_claims,
sum(total_payments) as total_payments_amount,
avg(lodgement_delay) as avg_lodgement_delay
FROM employer_claims_details
GROUP BY EMPLOYER_ID,employer_industry

UNION ALL 

-- EMPLOYER SIZE METRICS
SELECT 
EMPLOYER_ID,
'EMPLOYER_SIZE' AS dimension_name,
coalesce(employer_size,'UNKNOWN') AS DIMENSION_VALUE,
count(CLAIM_ID) as total_claims,
sum(total_payments) as total_payments_amount,
avg(lodgement_delay) as avg_lodgement_delay
FROM employer_claims_details
GROUP BY EMPLOYER_ID, employer_size

UNION ALL 

-- INJURY METRICS
SELECT 
EMPLOYER_ID,
'INJURY_CATEGORY' AS dimension_name,
coalesce(afflication_category,'UNKNOWN') AS DIMENSION_VALUE,
count(CLAIM_ID) as total_claims,
sum(total_payments) as total_payments_amount,
avg(lodgement_delay) as avg_lodgement_delay
FROM employer_claims_details
GROUP BY EMPLOYER_ID, afflication_category
)
SELECT * FROM employer_metrics

