with check_negative_payment_rcrds as 
(
select * from 
{{ ref('silver_payments') }}
where payment_amount < 0
)
select * from check_negative_payment_rcrds