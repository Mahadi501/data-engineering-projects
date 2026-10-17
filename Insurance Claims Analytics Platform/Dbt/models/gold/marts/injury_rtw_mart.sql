with rtw_details_per_injury as 
(
select 
AFFLICATION_NATURE_CD,
EVENT_ID,
EVENT_TYPE,
DAYS_LOST,
CLAIM_ID
from {{ ref('silver_rtw_events') }}
where EVENT_TYPE in ('FULL RETURN','PARTIAL RETURN')
),
full_rtw_type_agg as 
(
select 
AFFLICATION_NATURE_CD,
count(EVENT_ID) as full_rtw_count 
from rtw_details_per_injury
where EVENT_TYPE = 'FULL RETURN'
group by AFFLICATION_NATURE_CD
),
partial_rtw_type_agg as 
(
select 
AFFLICATION_NATURE_CD,
count(EVENT_ID) as partial_rtw_count 
from rtw_details_per_injury
where EVENT_TYPE = 'PARTIAL RETURN'
group by AFFLICATION_NATURE_CD
),
rtw_duration_agg as 
(
select 
AFFLICATION_NATURE_CD,
count(claim_id) as claim_count,
avg(DAYS_LOST)  as avg_rtw_days,
min(DAYS_LOST)  as min_rtw_days,
max(DAYS_LOST)  as max_rtw_days
from rtw_details_per_injury
group by AFFLICATION_NATURE_CD
),
rtw_complete as 
(
select 
rtw.AFFLICATION_NATURE_CD,
rtw.claim_count,
rtw.avg_rtw_days,
rtw.min_rtw_days,
rtw.max_rtw_days,
frtw.full_rtw_count,
prtw.partial_rtw_count
from rtw_duration_agg as rtw
left join full_rtw_type_agg as frtw
on rtw.AFFLICATION_NATURE_CD = frtw.AFFLICATION_NATURE_CD
left join partial_rtw_type_agg as prtw
on rtw.AFFLICATION_NATURE_CD = prtw.AFFLICATION_NATURE_CD
)
select * from  rtw_complete
