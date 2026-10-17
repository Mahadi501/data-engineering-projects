select 
*
from {{ ref('injury_rtw_mart') }}
where min_rtw_days < 0