-- create a bronze table to ingest employer data through metadata driven ingestion 
 create or replace table insurance_dev.dbt_mtest.employer_metadata_driven_ingest 
(
batch_id varchar,
source_name varchar,
EMPLOYER_ID VARCHAR,
ABN VARCHAR,
EMPLOYER_NAME STRING(40),
INDUSTRY STRING(40),
REGION STRING(40),
PREMIUM_SIZE STRING(30),
EMPLOYEE_COUNT NUMBER(10,0),
OFFICES_COUNT NUMBER(10,0),
hazard_material_handle BOOLEAN,
EFFECTIVE_DATE DATETIME,
LAST_UPDATED_DATE DATETIME
)
comment = 'Table to store data ingested using meadata driven ingestion';

-- create an audit table to store the entire ingestion journey of a file
create table if not exists insurance_dev.dbt_mtest.audit_table
(
batch_id varchar,
source varchar,
file_name varchar,
status varchar
)
comment = 'table to store journey of an ingested file through metadata driven ingestion framework';


-- stored procedure to orchestrate the metadata driven ingestion 
create or replace procedure insurance_dev.dbt_mtest.sp_orchstrt_metadata_ingstn(p_file_path varchar,p_source varchar,p_infer_schema_fileformat varchar,p_file_format_name varchar) 
returns varchar
language sql
as 
$$
declare
v_status varchar; -- variable to store interim statuses during the ingestion process

v_file_ingestion_status varchar; --variable to store the result of the file validator stored procedure. 

v_batch_id varchar; -- store the generated batch_id for the ingestion process everytime the sp is run

v_ingestion_action varchar; -- variable to store the decision from schema validation 

v_sql VARCHAR; -- variable to store the dynamic sql for loading the file from stage

v_column_mapping varchar; -- variable to store the dynamic mapping to load the ingested file correctly

v_downstream_table_name varchar; -- variable to store the name of the downstream table 
begin 


-- extracting downstream table name 
select 
downstream_table
into :v_downstream_table_name
from insurance_dev.dbt_mtest.source_to_table_mapping
where source_name = :p_source and CURRENT_FLAG = TRUE;


-- checking if the incoming file has already been loaded 
select status
into :v_status
from insurance_dev.dbt_mtest.ingested_file_registry
where (file_path = :p_file_path) and (source = :p_source) and  (downstream_table = :v_downstream_table_name)
and status = 'loaded'
LIMIT 1;


if (:v_status is null) then 

    --create a batch_id to start with the ingestion process
    v_batch_id := uuid_string();
    v_status := 'file_received';
    
    
    -- create entry into the audit table
    insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
    values
    (:v_batch_id,:p_source,:p_file_path,:v_status);
    
    -- perform file validation checks 
    call insurance_dev.dbt_mtest.file_validator(:p_file_path,:p_infer_schema_fileformat) into :v_file_ingestion_status;
    
    if (:v_file_ingestion_status = 'FILE VALIDATION SUCCESS') then 
        v_status := 'file_validated';
        insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
        values
        (:v_batch_id,:p_source,:p_file_path,:v_status);
    else 
        v_status := 'file_validation_failed';
        insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
        values
        (:v_batch_id,:p_source,:p_file_path,:v_status);
        return 'Ingestion Failed - Check audit table for batch_id: ' || v_batch_id;
    END IF;
    
    -- perform  schema validation 
    call insurance_dev.dbt_mtest.schema_validator(:p_file_path,:p_source,:v_batch_id,:p_infer_schema_fileformat); 
    
    v_status := 'schema_validated';
    insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
    values
    (:v_batch_id,:p_source,:p_file_path,:v_status);
    
    -- perform schema classification and get the final ingestion decision on the incoming file
    call insurance_dev.dbt_mtest.schema_classifier(:v_batch_id,:p_source);
    v_status := 'schema_classified';
    
    insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
    values
    (:v_batch_id,:p_source,:p_file_path,:v_status);
    
    -- check schema validation decision 
    select action 
    into :v_ingestion_action
    from insurance_dev.dbt_mtest.schema_validation_summary
    where batch_id = :v_batch_id and source = :p_source;
    
    v_status := 'loading';
    insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
    values
    (:v_batch_id,:p_source,:p_file_path,:v_status);
    
    
    --if decision is load or load_with_position_mismatch then load the file from stage into the bronze folder using dynamic sql 
    if (:v_ingestion_action in ('load')) then 
    
        --generate dynamic mapping for loading file from stage
        call insurance_dev.dbt_mtest.sp_generate_load_mapping(:v_batch_id,:p_source) into :v_column_mapping;
    
        v_status := 'mapping_generated';
    
        insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
        values
        (:v_batch_id,:p_source,:p_file_path,:v_status);
    
        v_sql :=
        'COPY INTO ' || v_downstream_table_name || '
        ( 
            batch_id,
            source_name,
            employer_id,
            abn,
            employer_name,
            industry,
            region,
            premium_size,
            employee_count,
            offices_count,
            hazard_material_handle,
            effective_date,
            last_updated_date
        )
        FROM
        (
            SELECT
                ? as batch_id,
                ? as source_name,
                ' || v_column_mapping || '
            FROM ' || p_file_path || '
        )
        force = true
        FILE_FORMAT = (FORMAT_NAME = ''' || p_file_format_name || ''')';
    
    
        EXECUTE IMMEDIATE :v_sql USING (v_batch_id, p_source);
        
        v_status := 'loaded';
        
        insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
        values
        (:v_batch_id,:p_source,:p_file_path,:v_status);

        -- update file ingestion registry table 
        insert into insurance_dev.dbt_mtest.ingested_file_registry
        (file_path,source,downstream_table,load_date,status)
        values
        (:p_file_path,:p_source,:v_downstream_table_name,current_timestamp(),'loaded');
    
    elseif (:v_ingestion_action in ('load_with_position_mismatch_warning')) then 
    
        --generate dynamic mapping for loading file from stage
        call insurance_dev.dbt_mtest.sp_generate_load_mapping(:v_batch_id,:p_source) into :v_column_mapping;
        
        v_status := 'mapping_generated';
        
        insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
        values
        (:v_batch_id,:p_source,:p_file_path,:v_status);
    
    
        v_sql :=
        'COPY INTO ' || v_downstream_table_name || '
        ( 
            batch_id,
            source_name,
            employer_id,
            abn,
            employer_name,
            industry,
            region,
            premium_size,
            employee_count,
            offices_count,
            hazard_material_handle,
            effective_date,
            last_updated_date
        )
        FROM
        (
            SELECT
                ? as batch_id,
                ? as source_name,
                ' || v_column_mapping || '
            FROM ' || p_file_path || '
        )
        force = true
        FILE_FORMAT = (FORMAT_NAME = ''' || p_file_format_name || ''')';
    
    
    
    
        EXECUTE IMMEDIATE :v_sql USING (v_batch_id, p_source);
        
        v_status := 'load_with_position_mismatch_warning';
        
        insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
        values
        (:v_batch_id,:p_source,:p_file_path,:v_status);

        -- update file ingestion registry table 
        insert into insurance_dev.dbt_mtest.ingested_file_registry
        (file_path,source,downstream_table,load_date,status)
        values
        (:p_file_path,:p_source,:v_downstream_table_name,current_timestamp(),'loaded');
    
    elseif (:v_ingestion_action in ('load_with_new_column_added_warning')) then 
    
        --generate dynamic mapping for loading file from stage
        call insurance_dev.dbt_mtest.sp_generate_load_mapping(:v_batch_id,:p_source) into :v_column_mapping;
        
        v_status := 'mapping_generated';
        
        insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
        values
        (:v_batch_id,:p_source,:p_file_path,:v_status);
        
        v_sql :=
            'COPY INTO ' || v_downstream_table_name || '
            ( 
                batch_id,
                source_name,
                employer_id,
                abn,
                employer_name,
                industry,
                region,
                premium_size,
                employee_count,
                offices_count,
                hazard_material_handle,
                effective_date,
                last_updated_date
            )
            FROM
            (
                SELECT
                    ? as batch_id,
                    ? as source_name,
                    ' || v_column_mapping || '
                FROM ' || p_file_path || '
            )
            force = true
            FILE_FORMAT = (FORMAT_NAME = ''' || p_file_format_name || ''')';
        
            EXECUTE IMMEDIATE :v_sql USING (v_batch_id, p_source);
            
            v_status := 'load_with_warning_new_column_found';
            
            insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
            values
            (:v_batch_id,:p_source,:p_file_path,:v_status);
            
            -- update file ingestion registry table 
            insert into insurance_dev.dbt_mtest.ingested_file_registry
            (file_path,source,downstream_table,load_date,status)
            values
            (:p_file_path,:p_source,:v_downstream_table_name,current_timestamp(),'loaded');    
    
    elseif (:v_ingestion_action in ('reject_column_missing')) then 
        v_status := 'Failed_column_missing';
        insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
        values
        (:v_batch_id,:p_source,:p_file_path,:v_status);
    
    elseif (:v_ingestion_action in ('reject_data_type_mismatch')) then 
        v_status := 'Failed_datatype_mismatch';
        insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
        values
        (:v_batch_id,:p_source,:p_file_path,:v_status);
    
    elseif (:v_ingestion_action in ('reject_column_renamed')) then 
        v_status := 'Failed_column_rename_detected';
        insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
        values (:v_batch_id,:p_source,:p_file_path,:v_status);
    
    else 
        v_status := 'Failed - Unknown reason';
        insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
        values
        (:v_batch_id,:p_source,:p_file_path,:v_status);
    
    END IF;
    return 'metadata ingestion process completed - check audit table for batch_id: ' || v_batch_id;

else 
    return 'ingestion skipped - file already exists ';
END IF;    

end;
$$;


call insurance_dev.dbt_mtest.sp_orchstrt_metadata_ingstn('@INSURANCE_DEV.DBT_MTEST.EMPLOYER_STAGE_S3/staging/employers_v4.csv', 'employer','INSURANCE_DEV.DBT_MTEST.CSV_LOADER2','INSURANCE_DEV.DBT_MTEST.CSV_LOADER');



delete from insurance_dev.dbt_mtest.employer_metadata_driven_ingest;
delete from insurance_dev.dbt_mtest.schema_validation_results;
delete from insurance_dev.dbt_mtest.schema_validation_summary;
delete  from insurance_dev.dbt_mtest.audit_table;


select * from insurance_dev.dbt_mtest.employer_metadata_driven_ingest;


select * from insurance_dev.dbt_mtest.audit_table;
select * from insurance_dev.dbt_mtest.schema_validation_summary
where batch_id = 'fb573495-2bc5-49ca-83e3-c31179456429';

select * from insurance_dev.dbt_mtest.schema_validation_results
where batch_id = 'fb573495-2bc5-49ca-83e3-c31179456429';

select * from insurance_dev.dbt_mtest.audit_table
where batch_id = '29a66453-4a3b-4e49-b57e-b76177047884';

select * from insurance_dev.dbt_mtest.employer_metadata_driven_ingest
where batch_id = '7f541efe-ad98-4b4e-9d9c-1c23dbe91c45';



select
status 
from insurance_dev.dbt_mtest.ingested_file_registry;