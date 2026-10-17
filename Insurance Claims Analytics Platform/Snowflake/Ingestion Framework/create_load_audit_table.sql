-- create SEQUENCE to use inside the audit table
CREATE OR REPLACE SEQUENCE insurance_dev.bronze.audit_id_seq
  START WITH 1
  INCREMENT BY 1
  ORDER;


-- creating the  table to store information for auditing the ingestion of data
create table if not exists insurance_dev.bronze.load_audit
(
audit_id integer default insurance_dev.bronze.audit_id_seq.NEXTVAL,
batch_id varchar,
source_file_name varchar,
target_table varchar,
row_count number(20,0),
load_start_time timestamp,
load_end_time timestamp,
load_status varchar,
error_message varchar,
loaded_by varchar,
created_timestamp timestamp
)
comment =  'Table to store information of data ingestion, helpful for auditing if load was successful or not';


create or replace procedure insurance_dev.bronze.sp_load_audit_table(INGESTION_LOAD_RESULT VARIANT) 
RETURNS STRING
LANGUAGE SQL

AS
$$
    DECLARE
        V_BATCH_ID STRING;
        V_FILE_NAME STRING;
        V_ROW_COUNT NUMBER(20,0);
        V_START_TIME TIMESTAMP_NTZ;
        V_END_TIME TIMESTAMP_NTZ;
        V_STATUS STRING;
        V_ERROR_MESSAGE STRING;
        V_LOADED_BY STRING;
        V_TARGET_TABLE varchar;
    
    BEGIN
       -- extract values from the variant object
        V_BATCH_ID := INGESTION_LOAD_RESULT:batch_id::STRING;
        V_FILE_NAME := INGESTION_LOAD_RESULT:file_name::STRING;
        V_TARGET_TABLE := INGESTION_LOAD_RESULT:target_table::STRING;
        V_ROW_COUNT := INGESTION_LOAD_RESULT:row_count::NUMBER(20,0);
        V_START_TIME := INGESTION_LOAD_RESULT:start_time::TIMESTAMP_NTZ;
        V_END_TIME := INGESTION_LOAD_RESULT:end_time::TIMESTAMP_NTZ;
        V_STATUS := INGESTION_LOAD_RESULT:status::STRING;
    
        insert into insurance_dev.bronze.load_audit
        (
        BATCH_ID,
        SOURCE_FILE_NAME,
        TARGET_TABLE,
        ROW_COUNT,
        LOAD_START_TIME,
        LOAD_END_TIME,
        LOAD_STATUS,
        ERROR_MESSAGE,
        LOADED_BY,
        CREATED_TIMESTAMP
        )
        values
        (
        :V_BATCH_ID,
        :V_FILE_NAME,
        :V_TARGET_TABLE,
        :V_ROW_COUNT,
        :V_START_TIME,
        :V_END_TIME,
        :V_STATUS,
        'N/A',
        'INGESTION_TASK',
        CURRENT_TIMESTAMP()
    ); 
END;
$$;




