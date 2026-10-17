select 
*
from {{ ref('injury_rtw_mart') }}
where (full_rtw_count+ partial_rtw_count) != claim_count