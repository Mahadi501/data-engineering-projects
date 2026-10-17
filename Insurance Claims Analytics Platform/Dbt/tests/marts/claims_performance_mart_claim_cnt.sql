select 
*
from {{ ref('claims_performance_mart') }}
where total_claims_received < 0