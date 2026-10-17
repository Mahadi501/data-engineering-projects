with
    fact_rtw_events as (
        select
            rtw.event_id,
            rtw.event_type,
            rtw.days_lost,
            rtw.event_date,
            rtw.claim_id,
            rtw.claim_number,
            worker.worker_sk,
            injury.afflication_nature_cd_sk,
            rtw.claim_status,
            rtw.claim_type,
            rtw.claim_liability_status
        from {{ ref("silver_rtw_events") }} as rtw
        inner join
            {{ ref("dim_worker") }} as worker
            on rtw.worker_id = worker.worker_id
        inner join
            {{ ref("dim_injury") }} as injury
            on rtw.afflication_nature_cd = injury.afflication_nature_cd
    )
select *
from fact_rtw_events
