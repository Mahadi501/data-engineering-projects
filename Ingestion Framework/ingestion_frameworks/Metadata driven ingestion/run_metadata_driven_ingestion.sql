-- create a bronze table to ingest employer data through metadata driven ingestion 
 create table if not exists insurance_dev.dbt_mtest.employer_metadata_driven_ingest 
(
EMPLOYER_ID VARCHAR,
ABN VARCHAR,
EMPLOYER_NAME STRING(40),
INDUSTRY STRING(40),
REGION STRING(40),
PREMIUM_SEGMENT STRING(30),
EMPLOYEE_COUNT NUMBER(10,0),
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
create or replace procedure insurance_dev.dbt_mtest.sp_orchstrt_metadata_ingstn(p_file_name varchar,p_source varchar,p_file_format_name varchar) 
returns varchar
language sql
as 
$$
declare
v_status varchar;
v_file_ingestion_status varchar;
v_batch_id varchar;
v_ingestion_action varchar;
begin 

--create a batch_id to start with the ingestion process
v_batch_id := uuid_string();
v_status := 'file_received'

-- create entry into the audit table
insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
values
(:v_batch_id,:p_source,:p_file_name,:v_status);

-- check for file validation
call insurance_dev.dbt_mtest.file_validator(:p_file_name,:p_file_format_name) into :v_file_ingestion_status;

if (:v_file_ingestion_status = 'FILE VALIDATION SUCCESS') then 
    v_status := 'file_validated';
    insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
    values
    (:v_batch_id,:p_source,:p_file_name,:v_status);
else 
    v_status := 'file_validation_failed';
    insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
    values
    (:v_batch_id,:p_source,:p_file_name,:v_status);
    return 'Ingestion Failed - Check audit table for batch_id: ' || :v_batch_id;
end if;

-- run schema validation 
call insurance_dev.dbt_mtest.schema_validator
(
:p_file_name,
:p_file_format_name,
:p_source,
:v_batch_id
); 
v_status := 'schema_validated';
insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
values
(:v_batch_id,:p_source,:p_file_name,:v_status);

-- run schema classification
call insurance_dev.dbt_mtest.schema_classifier(:v_batch_id,:p_source);
v_status := 'schema_classified';
insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
values
(:v_batch_id,:p_source,:p_file_name,:v_status);

-- check schema validation decision 
select action 
into :v_ingestion_action
from insurance_dev.dbt_mtest.schema_validation_summary
where batch_id = :v_batch_id and source = :p_source;

v_status := 'decision_inprogress';
insert into insurance_dev.dbt_mtest.audit_table(batch_id,source,file_name,status)
values
(:v_batch_id,:p_source,:p_file_name,:v_status);

-- implement decision 
if :v_ingestion_action = 'load' then 
insert into 

     



returns 'completed';
end;
$$;
