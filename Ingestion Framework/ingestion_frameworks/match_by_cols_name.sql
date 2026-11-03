-- create a new table for easier auditability and experimenting 
create table if not exists insurance_dev.dbt_mtest.employer_match_by_name 
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
comment = 'Table to store data ingested using match by column name approach';


-- ingest data into the table using match-by-column-name --> successful loading
copy into insurance_dev.dbt_mtest.employer_match_by_name 
from @INSURANCE_DEV.DBT_MTEST.employer_stage_s3/staging/employers_v1.csv
FILE_FORMAT = (format_name = 'INSURANCE_DEV.DBT_MTEST.CSV_LOADER2')
match_by_column_name = case_insensitive;


-- ingest data into the table using match-by-column-name where ingested file as an extra column but has all other columns.
-- ingest data into the table using match-by-column-name --> unsuccessful loading
COPY INTO INSURANCE_DEV.DBT_MTEST.EMPLOYER_MATCH_BY_NAME
FROM @INSURANCE_DEV.DBT_MTEST.EMPLOYER_STAGE_S3/staging/employers_v2.csv
FILE_FORMAT = (
    FORMAT_NAME = 'INSURANCE_DEV.DBT_MTEST.CSV_LOADER2'
)
force = true
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;


-- ingest data into the table using match-by-column-name where ingested file has columns reordered
-- ingest data into the table using match-by-column-name --> unsuccessful loading
COPY INTO INSURANCE_DEV.DBT_MTEST.EMPLOYER_MATCH_BY_NAME
FROM @INSURANCE_DEV.DBT_MTEST.EMPLOYER_STAGE_S3/staging/employers_v1_reordered.csv
FILE_FORMAT = (
    FORMAT_NAME = 'INSURANCE_DEV.DBT_MTEST.CSV_LOADER2'
)
force = true
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
