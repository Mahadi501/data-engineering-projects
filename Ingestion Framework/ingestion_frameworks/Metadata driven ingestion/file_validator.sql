-- table to store information on what file have been loaded
create table if not exists insurance_dev.dbt_mtest.ingested_file_registry
(
file_path varchar,
source varchar,
downstream_table varchar,
load_date datetime,
status varchar
)
comment = 'table to store information on the list of files loaded into the downstream table';


-- STORE PROCEDURE to validate the file before checking for schema validation 
CREATE OR REPLACE PROCEDURE insurance_dev.dbt_mtest.file_validator(
    file_path VARCHAR,
    file_format_name VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_row_count INTEGER;
    v_file_size INTEGER;
    v_relative_path VARCHAR;
    v_status VARCHAR;
    -- FILE_METADATA_EXCEPTION EXCEPTION (
    --     -20002,
    --     'File not found in directory table or metadata is unavailable'
    -- );

    -- EMPTY_FILE_EXCEPTION EXCEPTION (
    --     -20001,
    --     'Incoming file is empty (0 bytes)'
    -- );

    -- INVALID_SCHEMA_EXCEPTION EXCEPTION (
    --     -20003,
    --     'Unable to detect file schema'
    -- );

BEGIN

-- extracting the relative path from the complete file path
 v_relative_path := REGEXP_REPLACE(
    file_path,
    '^@[^/]+/',
    '/'
);

-- checking if the file has no data inside it
SELECT
    size
into :v_file_size
FROM DIRECTORY(
    @INSURANCE_DEV.DBT_MTEST.EMPLOYER_STAGE_S3
)
WHERE RELATIVE_PATH = :v_relative_path;

-- Checking if there is schema read error
SELECT COUNT(*)
    INTO :v_row_count
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => :file_path,
            FILE_FORMAT => :file_format_name
        )
    );

IF (v_file_size IS NULL) THEN
        v_status := 'FAILED - file path not found';
        return v_status;

ELSEIF (v_file_size = 0) THEN
        v_status := 'FAILED - incoming file is empty (0 bytes)';
        return v_status;

ELSEIF(v_row_count = 0) THEN
        v_status := 'FAILED - unable to read schema';
        return v_status;

ELSE
        v_status := 'FILE VALIDATION SUCCESS';
        return v_status;

END IF;
END;
$$;

-- CALL insurance_dev.dbt_mtest.file_validator(
--     '@INSURANCE_DEV.DBT_MTEST.EMPLOYER_STAGE_S3/staging/employers_v8.csv',
--     'INSURANCE_DEV.DBT_MTEST.CSV_LOADER2'
-- );

