SELECT
*
from {{ ref('silver_rtw_events') }}
where DAYS_LOST < 0
