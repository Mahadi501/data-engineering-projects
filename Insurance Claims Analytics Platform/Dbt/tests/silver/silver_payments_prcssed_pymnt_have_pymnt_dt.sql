select 
* 
from {{ ref('silver_payments') }}
where (PAYMENT_STATUS = 'PROCESSED') AND (PAYMENT_DATE IS NULL)
