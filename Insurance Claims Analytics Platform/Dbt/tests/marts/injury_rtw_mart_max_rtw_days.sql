select 
*
from {{ ref('injury_rtw_mart') }}
where max_rtw_days < 0