-- stored procedure to load files from stag into the relevant bronze table and update the audit table.
CREATE or replace procedure INSURANCE_DEV.BRONZE.sp_run_ingestion_process()
returns string 
language sql 
as 
$$
DECLARE 
    BATCH_ID VARCHAR;
    CLAIM_LOAD_RESULT VARIANT;
    PAYMENT_LOAD_RESULT VARIANT;
    EMPLOYERS_LOAD_RESULT VARIANT;
    INJURY_REF_LOAD_RESULT VARIANT;
    PROVIDERS_LOAD_RESULT VARIANT;
    RTW_EVENTS_LOAD_RESULT VARIANT;
    WORKERS_LOAD_RESULT VARIANT;

    -- TRACK INGESTION FAILURES 
    V_FAILURE_COUNT NUMBER DEFAULT 0;
    V_FAILURES VARCHAR DEFAULT '';
BEGIN

        -- generate a unique batch id for each ingestion 
        BATCH_ID := UUID_STRING();

        -- run the claim ingestion process
        BEGIN 
            CALL insurance_dev.bronze.SP_INGEST_CLAIMS_DATA(:BATCH_ID) INTO :CLAIM_LOAD_RESULT;
            -- update the metadata into the audit table 
            CALL insurance_dev.bronze.sp_load_audit_table(:CLAIM_LOAD_RESULT);
        EXCEPTION 
                WHEN OTHER THEN
                V_FAILURE_COUNT := V_FAILURE_COUNT + 1;
                V_FAILURES := V_FAILURES || 'ERROR INGESTING CLAIMS: ' || SQLERRM || ' | ';
        END;

        
        -- run the payment ingestion process 
        BEGIN
            CALL insurance_dev.bronze.SP_INGEST_PAYMENTS_DATA(:BATCH_ID) INTO :PAYMENT_LOAD_RESULT;
            -- update the metadata into the audit table 
            CALL insurance_dev.bronze.sp_load_audit_table(:PAYMENT_LOAD_RESULT);
        EXCEPTION  
              WHEN OTHER THEN
                V_FAILURE_COUNT := V_FAILURE_COUNT + 1;
                V_FAILURES := V_FAILURES || 'ERROR INGESTING PAYMENTS: ' || SQLERRM || ' | ';
        END;

        
        -- run the EMPLOYERS ingestion process 
        BEGIN
            CALL INSURANCE_DEV.BRONZE.SP_INGEST_EMPLOYERS_DATA(:BATCH_ID) INTO :EMPLOYERS_LOAD_RESULT;
            -- update the metadata into the audit table 
            CALL insurance_dev.bronze.sp_load_audit_table(:EMPLOYERS_LOAD_RESULT);
        EXCEPTION 
              WHEN OTHER THEN
                V_FAILURE_COUNT := V_FAILURE_COUNT + 1;
                V_FAILURES := V_FAILURES || 'ERROR INGESTING EMPLOYERS: ' || SQLERRM || ' | ';
        END;


        -- RUN THE INJURY REFERENCE INGESTION PROCESS
        BEGIN
            CALL INSURANCE_DEV.BRONZE.SP_INGEST_INJURY_REF_DATA(:BATCH_ID) INTO :INJURY_REF_LOAD_RESULT;
            -- update the metadata into the audit table 
            CALL insurance_dev.bronze.sp_load_audit_table(:INJURY_REF_LOAD_RESULT);
        EXCEPTION
              WHEN OTHER THEN
                V_FAILURE_COUNT := V_FAILURE_COUNT + 1;
                V_FAILURES := V_FAILURES || 'ERROR INGESTING INJURY REF: ' || SQLERRM || ' | ';
        END;


        -- RUN THE PROVIDERS INGESTION PROCESS
        BEGIN 
            CALL INSURANCE_DEV.BRONZE.SP_INGEST_PROVIDERS_DATA(:BATCH_ID) INTO :PROVIDERS_LOAD_RESULT;
            -- update the metadata into the audit table 
            CALL insurance_dev.bronze.sp_load_audit_table(:PROVIDERS_LOAD_RESULT);
        EXCEPTION
              WHEN OTHER THEN
                V_FAILURE_COUNT := V_FAILURE_COUNT + 1;
                V_FAILURES := V_FAILURES || 'ERROR INGESTING PROVIDERS: ' || SQLERRM || ' | ';
        END;    


        -- RUN THE RTW EVENTS INGESTION PROCESS
        BEGIN
            CALL INSURANCE_DEV.BRONZE.SP_INGEST_RTW_EVENTS_DATA(:BATCH_ID) INTO :RTW_EVENTS_LOAD_RESULT;
            -- update the metadata into the audit table 
            CALL insurance_dev.bronze.sp_load_audit_table(:RTW_EVENTS_LOAD_RESULT);
        EXCEPTION 
           WHEN OTHER THEN 
                V_FAILURE_COUNT := V_FAILURE_COUNT + 1;
                V_FAILURES := V_FAILURES || 'ERROR INGESTING RTW EVENTS: ' || SQLERRM || ' | ';
        END;        

        -- RUN THE WORKERS INGESTION PROCESS
        BEGIN 
            CALL INSURANCE_DEV.BRONZE.SP_INGEST_WORKERS_DATA(:BATCH_ID) INTO :WORKERS_LOAD_RESULT;
            -- update the metadata into the audit table 
            CALL insurance_dev.bronze.sp_load_audit_table(:WORKERS_LOAD_RESULT);
        EXCEPTION 
         WHEN OTHER THEN 
            V_FAILURE_COUNT := V_FAILURE_COUNT + 1;
            V_FAILURES := V_FAILURES || 'ERROR INGESTING WORKERS: ' || SQLERRM || ' | ';
        END;    

IF (V_FAILURE_COUNT = 0) THEN         
    RETURN 'INGESTION COMPLETED! BATCH_ID = ' || BATCH_ID;
ELSE 
    RETURN 'INGESTION FINISHED WITH ' || V_FAILURE_COUNT || ' FAILURES. ' || V_FAILURES || 'BATCH_ID = ' || BATCH_ID;
END IF;

END;
$$;


-- task to run the ingestion of all 7 files into the bronze layer. 
CREATE OR REPLACE TASK INSURANCE_DEV.BRONZE.SCHEDULE_STAGING_INGESTION 
WAREHOUSE = COMPUTE_WH,
SCHEDULE = 'USING CRON 0 9 * * * UTC' 
AS 
-- after task finishes the data is loaded into the audit table: insurance_dev.bronze.load_audit
CALL INSURANCE_DEV.BRONZE.sp_run_ingestion_process();

-- execute task INSURANCE_DEV.BRONZE.SCHEDULE_STAGING_INGESTION;
-- select * from insurance_dev.bronze.load_audit;

