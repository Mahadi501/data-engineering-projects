-- create a store procedure to read through the validation results and create a mapping which will be used in the run_metadata_driven_ingestion sp

create or replace procedure insurance_dev.dbt_mtest.sp_generate_load_mapping(p_batch_id varchar,p_source_name varchar)
RETURNS varchar
language sql 
as 
$$ 
declare 
mapping_string varchar;

begin 

-- read through the validation results and create a dynamic mapping

with validation_results as (
        select 
            schema_column_name,
            schema_col_position + 1 as schema_col_position,
    from insurance_dev.dbt_mtest.schema_validation_results
    where batch_id = :p_batch_id and source_name = :p_source_name and MAPPING_STATUS in ('Column Matched','Column Position Mismatched')
        
    ),
    create_mapping as 
    (
        select 
            schema_column_name,
            schema_col_position,
            CONCAT('$', schema_col_position,' ','as ', schema_column_name) AS mapping_code
            from validation_results
    )
    select 
    LISTAGG(mapping_code, ', ')  as mapping_code_string
    into :mapping_string
    FROM create_mapping; 

return mapping_string;
end;
$$;


CALL insurance_dev.dbt_mtest.sp_generate_load_mapping('0cb5bbbe-ce04-46bf-9999-d77ac8540979','employer');

select * from insurance_dev.dbt_mtest.audit_table;