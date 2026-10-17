with int_rtw_journey as 
(
select 
claim.CLAIM_ID,
claim.CLAIM_NUMBER,
claim.WORKER_ID,
claim.AFFLICATION_NATURE_CD,
claim.CLAIM_STATUS,
claim.CLAIM_TYPE,
claim.CLAIM_LIABILITY_STATUS,
rtw.EVENT_ID,
rtw.EVENT_TYPE,
rtw.DAYS_LOST,
rtw.EVENT_DATE,
rtw.CREATED_TIMESTAMP as RTW_EVENT_CREATED_TIMESTAMP,
claim.CREATED_TIMESTAMP,
claim.UPDATED_TIMESTAMP,
claim.SOURCE_FILE_NAME,
claim.LOADED_AT_TIMESTAMP,
claim.RECORD_LOADED_TIMESTAMP,
claim.BATCH_ID,
claim.SOURCE_SYSTEM
FROM {{ ref('stg_rtw_events') }} as rtw
left join {{ ref('stg_claims') }} as claim
on claim.CLAIM_ID = rtw.CLAIM_ID
)
select * from int_rtw_journey
