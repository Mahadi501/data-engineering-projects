with stg_injury_ref as 
(
SELECT 
INJURY_CODE as afflication_nature_cd,
INJURY_DESCRIPTION,
upper(INJURY_CATEGORY) as afflication_category,
upper(BODY_LOCATION) as BODY_LOCATION,
upper(SEVERITY_CATEGORY) as SEVERITY_CATEGORY,
SOURCE_FILE_NAME,
LOADED_AT_TIMESTAMP,
RECORD_LOADED_TIMESTAMP,
BATCH_ID,
SOURCE_SYSTEM
from {{ source('bronze', 'INJURY_REFERENCE') }}
)
select * from stg_injury_ref