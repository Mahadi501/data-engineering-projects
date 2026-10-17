select 
*
from {{ ref('claims_performance_mart') }}
where avg_lodgement_delay < 0