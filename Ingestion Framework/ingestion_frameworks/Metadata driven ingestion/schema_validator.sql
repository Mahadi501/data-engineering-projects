-- created a table to store column level schema validation results
create or replace table insurance_dev.dbt_mtest.schema_validation_results 
(
batch_id varchar,
source_name varchar,
file_path varchar,
SCHEMA_COLUMN_NAME varchar,
HEADER_COLUMN_NAME varchar,
SCHEMA_COL_POSITION number,
HEADER_COL_POSITION number,
SCHEMA_DATATYPE varchar,
HEADER_DATATYPE varchar,
POTENTIAL_RENAMED_COLUMN varchar,
COLUMNS_SIMILARITY_SCORE number,
MAPPING_STATUS varchar,
column_mapping_status varchar
)
comment = 'Table to store the column level schema validation results';

-- create a store procedure that takes a file as input,reads its header and determines if it matches the schema registry table
CREATE OR REPLACE PROCEDURE insurance_dev.dbt_mtest.schema_validator
(
FILE_PATH VARCHAR, -- refers to complete file_path of the source file
source_type VARCHAR, -- refers to data entity for the incoming file such as employer, customer etc
batch_id VARCHAR, -- refers to the ingestion batch,
file_format varchar
)
returns string
language sql
as 
$$
BEGIN 

-- cte will load the schema validation results into the table
insert into insurance_dev.dbt_mtest.schema_validation_results  
(
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
    column_mapping_status
)    
-- reading the file header using infer_schema function
with file_header as (
    select 
        lower(COLUMN_NAME) as COLUMN_NAME,
        trim(REGEXP_REPLACE(lower(TYPE), '[0-9(),]', '')) as TYPE,
        ORDER_ID,
        lower(FILENAMES) 
        from table(
            infer_schema (
                -- '@INSURANCE_DEV.DBT_MTEST.EMPLOYER_STAGE_S3/staging/employers_v4.csv',
                location => :FILE_PATH, 
                -- 'INSURANCE_DEV.DBT_MTEST.CSV_LOADER2'
                FILE_FORMAT => :file_format
            )
        )
),
-- getting current schema information for the entity
active_schema_registry as (
    select 
    lower(COLUMN_NAME) as COLUMN_NAME,
    trim(REGEXP_REPLACE(lower(DATA_TYPE), '[0-9(),]', '')) as DATA_TYPE,
    COLUMN_POSITION as COLUMN_POSITION
    from INSURANCE_DEV.DBT_MTEST.SCHEMA_REGISTRY_TABLE
    where CURRENT_FLAG = TRUE and source_name = :source_type
),
-- comparing the schema information with the file header
comparison_from_schema_to_header as (
    SELECT 
        COALESCE(schema_registry.COLUMN_NAME,'missing') as schema_column_name,
        COALESCE(header.COLUMN_NAME,'missing') as header_column_name,
        COALESCE(schema_registry.DATA_TYPE,'missing') as schema_datatype,
        COALESCE(header.TYPE,'missing') as header_datatype,
        schema_registry.COLUMN_POSITION as schema_col_position,
        header.ORDER_ID as header_col_position
    from active_schema_registry as schema_registry
    left join file_header as header 
        on lower(schema_registry.COLUMN_NAME) = lower(header.COLUMN_NAME)   
),
-- comparing the file header information with the schema
comparison_from_header_to_schema as (
    SELECT 
        COALESCE(schema_registry.COLUMN_NAME,'missing') as schema_column_name,
        COALESCE(header.COLUMN_NAME,'missing') as header_column_name,
        COALESCE(schema_registry.DATA_TYPE,'missing') as schema_datatype,
        COALESCE(header.TYPE,'missing') as header_datatype,
        schema_registry.COLUMN_POSITION as schema_col_position,
        header.ORDER_ID as header_col_position
    from file_header as header 
    left join active_schema_registry as schema_registry
        on lower(schema_registry.COLUMN_NAME) = lower(header.COLUMN_NAME)   
),
-- finding which column are present in schema register but not in file header --> useful for renaming logic
unmatched_schema_columns as (
select 
    s.COLUMN_NAME,
    s.DATA_TYPE,
    s.COLUMN_POSITION
FROM active_schema_registry s  
left join file_header h
ON s.COLUMN_NAME = h.COLUMN_NAME
WHERE h.COLUMN_NAME IS NULL
),
-- finding which column are present in file header but not in schema registry--> useful for renaming logic
unmatched_header_columns as (
SELECT
    h.COLUMN_NAME,
    h.TYPE,
    h.ORDER_ID
FROM file_header h
LEFT JOIN active_schema_registry s
    ON h.COLUMN_NAME = s.COLUMN_NAME
WHERE s.COLUMN_NAME IS NULL
),
-- cross join schema registry with file header for identifying renamed columns 
comparison_col_renamed AS (
SELECT
    s.COLUMN_NAME AS SCHEMA_COLUMN_NAME,
    h.COLUMN_NAME AS HEADER_COLUMN_NAME,

    JAROWINKLER_SIMILARITY(
        s.COLUMN_NAME,
        h.COLUMN_NAME
    ) AS SIMILARITY_MATCH

FROM unmatched_schema_columns s
CROSS JOIN unmatched_header_columns h
),
-- applying transformations to enable correct comparison between data type columns inside comparison_from_schema_to_header
results as (
    select 
    schema_column_name,
    header_column_name,
    schema_col_position,
    header_col_position,
    case when 
        (schema_datatype in ('text','string','char','character','varbinary','binary')) then 'varchar'
        else schema_datatype end as schema_datatype,
    case 
        when (header_datatype in ('text','string','char','character','varbinary','binary')) then 'varchar'
        else header_datatype end as header_datatype_transformed
    from comparison_from_schema_to_header
),
-- applying transformations to enable correct comparison between data type columns inside comparison_from_header_to_schema
results_2 as (
    select 
    schema_column_name,
    header_column_name,
    schema_col_position,
    header_col_position,
    case when 
        (schema_datatype in ('text','string','char','character','varbinary','binary')) then 'varchar'
        else schema_datatype end as schema_datatype,
    case 
        when (header_datatype in ('text','string','char','character','varbinary','binary')) then 'varchar'
        else header_datatype end as header_datatype_transformed
    from comparison_from_header_to_schema
),
-- removing all rows where similarity score was calculated for matching columns such as abn inside schema with abn inside header
results_col_renamed as (
    select  
        schema_column_name,
        header_column_name as renamed_column,
        similarity_match
    from  comparison_col_renamed
    where similarity_match between 90 and 99
),
results_col_renamed2 as (
    select  
        header_column_name,
        schema_column_name as renamed_column,
        similarity_match
    from  comparison_col_renamed
    where similarity_match between 90 and 99
),

results_compiled as 
(
    select 
        result_set1.schema_column_name,
        result_set1.header_column_name,
        result_set1.schema_col_position,
        result_set1.header_col_position,
        result_set1.schema_datatype,
        result_set1.header_datatype_transformed,
        case 
          when  (result_set1.schema_column_name = result_set1.header_column_name) and (result_set1.schema_col_position = result_set1.header_col_position) then null
        else result_set2.renamed_column end as renamed_column,
        case when (result_set1.schema_column_name = result_set1.header_column_name) then 0
        else result_set2.similarity_match end as columns_similarity_score,
        case 
            when 
                (result_set1.schema_column_name = result_set1.header_column_name) and
                (result_set1.schema_col_position = result_set1.header_col_position) and 
                (result_set1.schema_datatype = result_set1.header_datatype_transformed)  then 'Column Matched'
            when     
                (result_set1.schema_column_name = result_set1.header_column_name) and 
                (result_set1.schema_col_position = result_set1.header_col_position) and 
                (result_set1.schema_datatype != result_set1.header_datatype_transformed) then 'Column Type Mismatched'
            when   
                (result_set1.schema_column_name != result_set1.header_column_name) and 
                (result_set2.renamed_column IS NOT NULL) and 
                (result_set2.similarity_match between 90 and 99) then 'Column Renamed'

            when 
                (result_set1.schema_column_name = result_set1.header_column_name) and
                result_set1.schema_col_position is not null and
                result_set1.header_col_position is not null and
                (result_set1.schema_col_position != result_set1.header_col_position) and 
                (result_set1.schema_datatype = result_set1.header_datatype_transformed) then 'Column Position Mismatched'
            else 'Column Not Found' end as mapping_status 
    from results as result_set1
    left join results_col_renamed as result_set2 
    on result_set1.schema_column_name = result_set2.schema_column_name
),
result_compiled_2 as 
(
     select 
        result_set1.schema_column_name,
        result_set1.header_column_name,
        result_set1.schema_col_position,
        result_set1.header_col_position,
        result_set1.schema_datatype,
        result_set1.header_datatype_transformed,
        case 
          when  (result_set1.schema_column_name = result_set1.header_column_name) and (result_set1.schema_col_position = result_set1.header_col_position) then null
        else result_set2.renamed_column end as renamed_column,
        case when (result_set1.schema_column_name = result_set1.header_column_name) then 0
        else result_set2.similarity_match end as columns_similarity_score,
        case 
            when 
                (result_set1.schema_column_name = result_set1.header_column_name) and
                (result_set1.schema_col_position = result_set1.header_col_position) and 
                (result_set1.schema_datatype = result_set1.header_datatype_transformed)  then 'Column Matched'
            when     
                (result_set1.schema_column_name = result_set1.header_column_name) and 
                (result_set1.schema_col_position = result_set1.header_col_position) and 
                (result_set1.schema_datatype != result_set1.header_datatype_transformed) then 'Column Type Mismatched'
            when   
                (result_set1.schema_column_name != result_set1.header_column_name) and 
                (result_set2.renamed_column IS NOT NULL) and (result_set2.similarity_match between 90 and 99) then 'Column Renamed'

            when 
                (result_set1.schema_column_name = result_set1.header_column_name) and
                (result_set1.schema_col_position != result_set1.header_col_position) and 
                (result_set1.schema_col_position is not null) and
                (result_set1.header_col_position is not null) and
                (result_set1.schema_datatype = result_set1.header_datatype_transformed) then 'Column Position Mismatched'
            else 'Column Added' end as mapping_status
    from results_2 as result_set1
    left join results_col_renamed2 as result_set2 
    on result_set1.header_column_name = result_set2.header_column_name 
    where result_set1.schema_column_name = 'missing'
),
result_combined as (
  select 
  *
  from results_compiled 
union all 
  select 
  * 
  from result_compiled_2
),

results_categorise as 
(  
select 
    SCHEMA_COLUMN_NAME,
    HEADER_COLUMN_NAME,
    SCHEMA_COL_POSITION,
    HEADER_COL_POSITION,
    SCHEMA_DATATYPE,
    HEADER_DATATYPE_TRANSFORMED,
    RENAMED_COLUMN as POTENTIAL_RENAMED_COLUMN,
    COLUMNS_SIMILARITY_SCORE,
    MAPPING_STATUS,
    case 
        when mapping_status not in ('Column Matched')  then 'Failed'
        else 'Passed'
        end as column_mapping_status
from result_combined     
)
select 
    :batch_id as batch_id,
    :source_type as source_name, 
    :file_path as file_path,
    SCHEMA_COLUMN_NAME,
    HEADER_COLUMN_NAME,
    SCHEMA_COL_POSITION,
    HEADER_COL_POSITION,
    SCHEMA_DATATYPE,
    HEADER_DATATYPE_TRANSFORMED as HEADER_DATATYPE,
    POTENTIAL_RENAMED_COLUMN,
    COLUMNS_SIMILARITY_SCORE,
    MAPPING_STATUS,
    column_mapping_status
from results_categorise; 

RETURN 'Schema Validation Completed';
END;
$$;


call insurance_dev.dbt_mtest.schema_validator('@INSURANCE_DEV.DBT_MTEST.EMPLOYER_STAGE_S3/staging/employers_v3.csv','employer','batch1224','INSURANCE_DEV.DBT_MTEST.CSV_LOADER2');

delete from insurance_dev.dbt_mtest.schema_validation_results;



