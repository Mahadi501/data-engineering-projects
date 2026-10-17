with fact_claims as
(
select 
claim.CLAIM_ID,
claim.CLAIM_NUMBER,
worker.worker_sk,
injury.AFFLICATION_NATURE_CD_sk,
employer.employer_sk,
claim.LODGEMENT_DATE,
claim.AFFLICATION_DATE,
claim.CLAIM_STATUS,
claim.CLAIM_TYPE,
claim.CLAIM_LIABILITY_STATUS,
claim.CLAIM_MANAGER
from {{ ref('silver_claims') }} as claim
left join {{ ref('dim_worker') }} as worker
on claim.WORKER_ID = worker.WORKER_ID
left join {{ ref('dim_employer') }} as employer
on claim.EMPLOYER_ID = employer.EMPLOYER_ID
left join {{ ref('dim_injury') }} as injury
on claim.AFFLICATION_NATURE_CD = injury.AFFLICATION_NATURE_CD
)
select * from fact_claims