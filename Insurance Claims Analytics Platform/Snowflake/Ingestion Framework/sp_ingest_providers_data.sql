CREATE OR REPLACE PROCEDURE insurance_dev.bronze.sp_ingest_providers_data(p_batch_id VARCHAR)
returns variant
language sql
as
$$
declare
    V_FILE_NAME STRING;
    V_START_TIME TIMESTAMP_NTZ;
    V_END_TIME TIMESTAMP_NTZ;
    V_ROW_COUNT NUMBER(20,0);
    V_SQL_ID VARCHAR;
    V_STATUS STRING;
    V_COPY_RESULT VARIANT;
begin

V_START_TIME := current_timestamp();

COPY INTO INSURANCE_DEV.BRONZE.PROVIDERS
( 
    PROVIDER_ID,
    PROVIDER_NAME,
    PROVIDER_TYPE,
    SPECIALITY,
    REGION,
    PROVIDER_STATUS,
    SOURCE_FILE_NAME,
    LOADED_AT_TIMESTAMP,
    RECORD_LOADED_TIMESTAMP,
    BATCH_ID,
    SOURCE_SYSTEM
)
FROM 
    (
    SELECT 
            $1 AS PROVIDER_ID,
            $2 AS PROVIDER_NAME,
            $3 AS PROVIDER_TYPE,
            $4 AS SPECIALITY,
            $5 AS REGION,
            $6 AS PROVIDER_STATUS,
            METADATA$FILENAME AS SOURCE_FILE_NAME,
            :V_START_TIME AS LOADED_AT_TIMESTAMP,
            CURRENT_TIMESTAMP() AS RECORD_LOADED_TIMESTAMP,
            :p_batch_id AS BATCH_ID,
            'ACCTION' AS SOURCE_SYSTEM
    FROM  @"INSURANCE_DEV"."BRONZE"."STAGE_RAW"/providers/
    )
PATTERN = '(?i).*\/providers.*\.csv$'
FILE_FORMAT = (FORMAT_NAME = CSV_FILES);

V_SQL_ID := SQLID;

SELECT OBJECT_CONSTRUCT(*)
INTO :V_COPY_RESULT
FROM TABLE(RESULT_SCAN(:V_SQL_ID));

V_FILE_NAME := GET_IGNORE_CASE(V_COPY_RESULT,'FILE');
V_STATUS := GET_IGNORE_CASE(V_COPY_RESULT, 'STATUS')::STRING;
V_ROW_COUNT := COALESCE(GET_IGNORE_CASE(V_COPY_RESULT, 'ROWS_LOADED')::NUMBER(20,0),0);

V_END_TIME := current_timestamp();

RETURN OBJECT_CONSTRUCT(
        'batch_id', p_batch_id,
        'file_name',V_FILE_NAME ,
        'start_time', V_START_TIME,
        'end_time', V_END_TIME,
        'row_count',V_ROW_COUNT,
        'status',V_STATUS,
        'target_table', 'INSURANCE_DEV.BRONZE.PROVIDERS'
);
end;
$$;


--CALL insurance_dev.bronze.sp_ingest_providers_data();