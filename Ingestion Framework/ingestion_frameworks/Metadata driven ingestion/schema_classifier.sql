-- create table to store the classification and action of the schema validation 
create or replace table insurance_dev.dbt_mtest.schema_validation_summary
(
batch_id varchar,
source varchar,
validation_date date,
classification varchar,
action varchar
)
comment = 'Rolled up version of the schema validation column level datasets and creates schema validation classification and action';

-- store procedure to determine the final ingestion action for the incoming source file
create or replace procedure insurance_dev.dbt_mtest.schema_classifier(batch_id varchar,source varchar) 
returns varchar
language sql 
as
$$
declare
v_status varchar;
v_row_count number;
v_validation_time date;

begin 

v_validation_time := current_timestamp();

-- reading the schema validation results 
select 
    count(*) as total_rows
into  :v_row_count   
from insurance_dev.dbt_mtest.schema_validation_results  
where batch_id = :batch_id and source_name = :source;

-- condition to check for missing batch_id or source and raising an error.
IF (:v_row_count = 0) then 
insert into insurance_dev.dbt_mtest.schema_validation_summary 
values(:batch_id,:source,:v_validation_time,'schema validation information not found','reject');
return 'Error - batch_id or source not found!';

--extract the schema validation information and provide a final classification and action on the incoming source file
else  
    insert into insurance_dev.dbt_mtest.schema_validation_summary 
    (
    batch_id,
    source,
    validation_date,
    classification,
    action
    )
    with schema_validation AS
    (
        SELECT
            batch_id,
            source_name,
            file_path,
            SCHEMA_COLUMN_NAME,
            HEADER_COLUMN_NAME,
            SCHEMA_COL_POSITION,
            HEADER_COL_POSITION,
            SCHEMA_DATATYPE,
            HEADER_DATATYPE,
            POTENTIAL_RENAMED_COLUMN,
            COLUMNS_SIMILARITY_SCORE,
            MAPPING_STATUS,
            column_mapping_status,
            -- creating a severity rating for the source file to determine final action on the file
            CASE
                WHEN MAPPING_STATUS = 'Column Matched' THEN 0
                WHEN MAPPING_STATUS = 'Column Not Found' THEN 5
                WHEN MAPPING_STATUS = 'Column Type Mismatched' THEN 3
                WHEN MAPPING_STATUS = 'Column Renamed' THEN 4
                WHEN MAPPING_STATUS = 'Column Position Mismatched' THEN 1
                WHEN MAPPING_STATUS = 'Column Added' THEN 2
            END AS severity,
    
            CASE
                WHEN MAPPING_STATUS = 'Column Matched' THEN 'schema_match'
                WHEN MAPPING_STATUS = 'Column Not Found' THEN 'schema_removed_column'
                WHEN MAPPING_STATUS = 'Column Type Mismatched' THEN 'schema_data_type_change'
                WHEN MAPPING_STATUS = 'Column Renamed' THEN 'schema_renamed_column'
                WHEN MAPPING_STATUS = 'Column Position Mismatched' THEN 'schema_match_with_reordering'
                WHEN MAPPING_STATUS = 'Column Added' THEN 'schema_evolution_new_column'
            END AS classification,
    
            CASE
                WHEN MAPPING_STATUS IN (
                    'Column Matched'
                ) THEN 'load'

                when MAPPING_STATUS = 'Column Position Mismatched' then 
                'load_with_position_mismatch_warning'
    
                WHEN MAPPING_STATUS IN (
                    'Column Not Found',
                    'Column Type Mismatched',
                    'Column Renamed'
                ) THEN 'reject'
    
                WHEN MAPPING_STATUS = 'Column Added' THEN 'load with warning'
            END AS action
    
        FROM insurance_dev.dbt_mtest.schema_validation_results
        where batch_id = :batch_id and source_name = :source
    )
    
    SELECT
        batch_id,
        source_name,
        current_timestamp() as validation_date,
        classification,
        action
    FROM schema_validation
    QUALIFY row_number() OVER (
        PARTITION BY batch_id, source_name
        ORDER BY severity DESC
    ) = 1;
    return 'Incoming File Classification Completed';
    
END IF;
end;
$$;

call insurance_dev.dbt_mtest.schema_classifier('batch1223','employer');
select * from insurance_dev.dbt_mtest.schema_validation_summary;
