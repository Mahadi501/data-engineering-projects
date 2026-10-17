-- Stored_Procedure to ingest claims data and audit it into the table 
create procedure if not exists insurance_dev.bronze.SP_INGEST_CLAIMS_DATA(p_batch_id VARCHAR)
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

BEGIN

    V_START_TIME := CURRENT_TIMESTAMP();
    
    -- COPY DATA FROM STAGING INTO BRONZE TABLE
    COPY INTO INSURANCE_DEV.BRONZE.claims
    ( 
        CLAIM_ID, 
        CLAIM_NUMBER, 
        WORKER_ID,
        EMPLOYER_ID,
        INJURY_CODE,
        INJURY_DATE,
        LODGEMENT_DATE,
        CLAIM_STATUS,
        CLAIM_TYPE,
        CLAIM_LIABILITY_STATUS, 
        CLAIM_MANAGER, 
        CREATED_TIMESTAMP, 
        UPDATED_TIMESTAMP, 
        SOURCE_FILE_NAME,
        LOADED_AT_TIMESTAMP,
        RECORD_LOADED_TIMESTAMP,
        BATCH_ID,
        SOURCE_SYSTEM
    )
    FROM 
        (
        SELECT 
                $1 AS CLAIM_ID,
                $2 AS CLAIM_NUMBER,
                $3 AS WORKER_ID,
                $4 AS EMPLOYER_ID,
                $5 AS INJURY_CODE,
                $6 AS INJURY_DATE,
                $7 AS LODGEMENT_DATE,
                $8 AS CLAIM_STATUS,
                $9 AS CLAIM_TYPE,
                $10 AS CLAIM_LIABILITY_STATUS,
                $11 AS CLAIM_MANAGER,
                $12 AS CREATED_TIMESTAMP,
                $13 AS UPDATED_TIMESTAMP,
                METADATA$FILENAME AS SOURCE_FILE_NAME,
                :V_START_TIME AS LOADED_AT_TIMESTAMP,
                CURRENT_TIMESTAMP() AS RECORD_LOADED_TIMESTAMP,
                :p_batch_id AS BATCH_ID,
                'ACCTION' AS SOURCE_SYSTEM
        FROM @"INSURANCE_DEV"."BRONZE"."STAGE_RAW"/claims/
        )    
    PATTERN = '(?i).*\/claims.*\.csv$'
    FILE_FORMAT = (FORMAT_NAME = CSV_FILES);

    -- extract query id
    V_SQL_ID := SQLID;

    -- extracting informations from the copy from stage commmand to store as variant type. 
    SELECT OBJECT_CONSTRUCT(*)
    INTO :V_COPY_RESULT
    FROM TABLE(RESULT_SCAN(:V_SQL_ID))
    LIMIT 1;

    V_FILE_NAME := GET_IGNORE_CASE(V_COPY_RESULT, 'FILE')::STRING;
    V_STATUS := GET_IGNORE_CASE(V_COPY_RESULT, 'STATUS')::STRING;
    V_ROW_COUNT := COALESCE(GET_IGNORE_CASE(V_COPY_RESULT, 'ROWS_LOADED')::NUMBER(20,0),0);

    V_END_TIME := CURRENT_TIMESTAMP();
    
    return object_construct (
        'batch_id', p_batch_id,
        'file_name',V_FILE_NAME ,
        'start_time', V_START_TIME,
        'end_time', V_END_TIME,
        'row_count',V_ROW_COUNT,
        'status',V_STATUS,
        'target_table', 'INSURANCE_DEV.BRONZE.CLAIMS'
    );
END;
$$;

--CALL insurance_dev.bronze.SP_INGEST_CLAIMS_DATA();




