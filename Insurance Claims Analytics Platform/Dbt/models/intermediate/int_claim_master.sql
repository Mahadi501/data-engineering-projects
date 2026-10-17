with int_claims_master as
(
SELECT
claim.CLAIM_ID,
claim.CLAIM_NUMBER,
claim.WORKER_ID,
worker.GENDER,
worker.AGE_GROUP,
worker.EMPLOYEMENT_TYPE,
claim.AFFLICATION_NATURE_CD,
injury_ref.INJURY_DESCRIPTION,
injury_ref.afflication_category,
injury_ref.BODY_LOCATION,
injury_ref.SEVERITY_CATEGORY,
claim.AFFLICATION_DATE,
claim.LODGEMENT_DATE,
claim.CLAIM_STATUS,
claim.CLAIM_TYPE,
claim.CLAIM_LIABILITY_STATUS,
claim.CLAIM_MANAGER,
claim.EMPLOYER_ID,
employer.EMPLOYER_NAME,
employer.employer_size,
employer.INDUSTRY,
employer.region as employer_region,
claim.CREATED_TIMESTAMP,
claim.UPDATED_TIMESTAMP,
claim.SOURCE_FILE_NAME,
claim.LOADED_AT_TIMESTAMP,
claim.RECORD_LOADED_TIMESTAMP,
claim.BATCH_ID,
claim.SOURCE_SYSTEM
from {{ ref('stg_claims') }} as claim
left join {{ ref('stg_workers') }} as worker
on claim.WORKER_ID = worker.WORKER_ID
left join {{ ref('stg_injury_reference') }}  as injury_ref
on claim.AFFLICATION_NATURE_CD = injury_ref.AFFLICATION_NATURE_CD
left join {{ ref('stg_employers') }} as employer 
on claim.EMPLOYER_ID = employer.EMPLOYER_ID
)

select * from int_claims_master