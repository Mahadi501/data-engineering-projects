-- create a store procedure that takes a file as input and determines if it matches the schema registry table
CREATE OR REPLACE PROCEDURE insurance_dev.dbt_mtest.schema_validator(FILE_PATH VARCHAR,FILE_FORMAT_NAME VARCHAR)
returns VARCHAR 
language sql
as 
$$
DECLARE
    v_ingestion_results RESULTSET;
    v_status VARCHAR;

BEGIN 

v_ingestion_results :=
(
    -- EXTRACTING THE FILE HEADER FROM THE FILE
    with file_header as (
        select 
            lower(COLUMN_NAME) as COLUMN_NAME,
             REGEXP_REPLACE(lower(TYPE), '[0-9(),]', '') as TYPE,
            ORDER_ID,
            lower(FILENAMES) 
            from table(
                infer_schema (
                    -- '@INSURANCE_DEV.DBT_MTEST.EMPLOYER_STAGE_S3/staging/employers_v4.csv',
                    location => :FILE_PATH, 
                    -- 'INSURANCE_DEV.DBT_MTEST.CSV_LOADER2'
                    FILE_FORMAT =>  :FILE_FORMAT_NAME
                )
            )
    ),
    active_schema_registry as (
        select 
        lower(COLUMN_NAME) as COLUMN_NAME,
        trim(lower(DATA_TYPE)) as DATA_TYPE,
        COLUMN_POSITION as COLUMN_POSITION
        from INSURANCE_DEV.DBT_MTEST.SCHEMA_REGISTRY_TABLE
        where CURRENT_FLAG = TRUE
    ),
    comparison as (
        SELECT 
            schema_registry.COLUMN_NAME as schema_column_name,
            COALESCE(header.COLUMN_NAME,'missing') as header_column_name,
            schema_registry.DATA_TYPE as schema_datatype,
            COALESCE(header.TYPE,'missing') as header_datatype,
            schema_registry.COLUMN_POSITION as schema_col_position,
            COALESCE(header.ORDER_ID,99999) as header_col_position
        from active_schema_registry as schema_registry
        left join file_header as header 
            on lower(schema_registry.COLUMN_NAME) = lower(header.COLUMN_NAME)   
    ),
    comparison_col_renamed as (
    select 
        COALESCE(schema_registry.COLUMN_NAME,'missing') as schema_column_name,
        COALESCE(header.COLUMN_NAME,'missing') as header_column_name,
        COALESCE(JAROWINKLER_SIMILARITY(schema_registry.COLUMN_NAME,header.COLUMN_NAME),0) as similarity_match
    from active_schema_registry as schema_registry
    cross join file_header as header 
    ),
    results as (
        select 
        schema_column_name,
        header_column_name,
        schema_col_position,
        header_col_position,
        schema_datatype,
        case 
            when (header_datatype in ('text','string','CHAR','CHARACTER','VARBINARY','BINARY')) then 'varchar'
            when (header_datatype in ('time','timestamp','TIMESTAMP_LTZ','TIMESTAMP_NTZ','TIMESTAMP_TZ')) then 'date' else header_datatype end as header_datatype_transformed
        from comparison
    ),
    results_col_renamed as (
        select  
            schema_column_name,
            header_column_name as renamed_column,
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
            result_set2.renamed_column,
            case when (result_set1.schema_column_name = result_set1.header_column_name) then 0
            else result_set2.similarity_match end as columns_similarity_score,
            case 
                when 
                    (result_set1.schema_column_name = result_set1.header_column_name) and
                    (result_set1.schema_col_position = result_set1.header_col_position) and 
                    (JAROWINKLER_SIMILARITY(result_set1.schema_datatype, result_set1.header_datatype_transformed)) > 95  then 'Column Matched'
                when     
                    (result_set1.schema_column_name = result_set1.header_column_name) and 
                    (result_set1.schema_col_position = result_set1.header_col_position) and 
                    (JAROWINKLER_SIMILARITY(result_set1.schema_datatype, result_set1.header_datatype_transformed)) < 95 then 'Column Type Mismatched'
                when   
                    (result_set1.schema_column_name != result_set1.header_column_name) and 
                    (result_set1.schema_col_position != result_set1.header_col_position) and 
                    (result_set2.renamed_column IS NOT NULL) and (result_set2.similarity_match between 90 and 99) then 'Column Renamed'
    
                when 
                    (result_set1.schema_column_name = result_set1.header_column_name) and
                    (result_set1.schema_col_position != result_set1.header_col_position) and 
                    (JAROWINKLER_SIMILARITY(result_set1.schema_datatype, result_set1.header_datatype_transformed)) > 95  then 'Column Position Mismatched'
                else 'Column Not Found' end as mapping_status,
            case 
                when  mapping_status not in ('Column Matched')  then 'Failed'
                else 'Passed'
                end as column_mapping_status    
        from results as result_set1
        left join results_col_renamed as result_set2 
        on result_set1.schema_column_name = result_set2.schema_column_name
    ),
    results_categorise as 
    (  
    select 
        header_column_name,
        schema_col_position
        header_col_position,
        schema_datatype,
        header_datatype_transformed,
        columns_similarity_score,
        mapping_status,
        case 
            when mapping_status not in ('Column Matched')  then 'Failed'
            else 'Passed'
            end as column_mapping_status
    from results_compiled     
    )
);    

-- reading results to set the status value
select 
        schema_column_name,
        header_column_name,
        schema_col_position,
        header_col_position,
        schema_datatype,
        header_datatype_transformed,
        renamed_column,
        columns_similarity_score,
        mapping_status,
        column_mapping_status
from table(v_ingestion_results)   
where column_mapping_status = 'Failed';
    
-- copying results into variable
select 
    case 
        when count(*) > 0 then 'Failed'
        else 'Passed'
        end as result
    into  :v_status   
from TABLE(RESULT_SCAN(LAST_QUERY_ID()));
        
RETURN 'Ingested File Schema: ' || v_status;
END;
$$;
