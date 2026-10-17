with check_incorrect_afflication_dates as 
(
select 
*
from 
{{ ref('int_claim_master') }}
where afflication_date > LODGEMENT_DATE
)
select * from check_incorrect_afflication_dates