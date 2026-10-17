select 
*
from {{ ref('employer_risk_mart') }}
where total_payments_amount < 0 