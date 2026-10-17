select 
*
from {{ ref('injury_rtw_mart') }}
where avg_rtw_days < 0