-- create a table to load employer data
create table if not exists insurance_dev.dbt_mtest.employer_tradional_loading (
EMPLOYER_ID VARCHAR,
ABN VARCHAR,
EMPLOYER_NAME STRING(40),
INDUSTRY STRING(40),
REGION STRING(40),
PREMIUM_SEGMENT STRING(30),
EMPLOYEE_COUNT NUMBER(10,0),
EFFECTIVE_DATE DATETIME,
LAST_UPDATED_DATE DATETIME,
FILE_NAME VARCHAR,
LOAD_TIMESTAMP DATETIME,
LOAD_ID VARCHAR
)
COMMENT = 'Table to store the employer data from stage without any schema handling';



--traditional file ingestion using copy into 
COPY INTO insurance_dev.dbt_mtest.employer_tradional_loading 
(
EMPLOYER_ID,
ABN, 
EMPLOYER_NAME,
INDUSTRY,
REGION,
PREMIUM_SEGMENT, 
EMPLOYEE_COUNT,
EFFECTIVE_DATE, 
LAST_UPDATED_DATE, 
FILE_NAME,
LOAD_TIMESTAMP,
LOAD_ID
)
FROM (
SELECT 
$1 as EMPLOYER_ID,
$2 as ABN,
$3 as EMPLOYER_NAME, 
$4 as INDUSTRY, 
$5 as REGION,
$6 as PREMIUM_SEGMENT, 
$7 as EMPLOYEE_COUNT,
TO_DATE($8, 'YYYY-MM-DD') as EFFECTIVE_DATE,
TO_DATE($9, 'YYYY-MM-DD') as LAST_UPDATED_DATE, 
METADATA$FILENAME AS FILE_NAME, 
CURRENT_TIMESTAMP() AS LOAD_TIMESTAMP,
md5(METADATA$FILENAME) AS LOAD_ID
FROM @INSURANCE_DEV.DBT_MTEST.employer_stage_s3/staging/employers_v1.csv
)
FILE_FORMAT = (format_name = 'INSURANCE_DEV.DBT_MTEST.CSV_LOADER');

--select * from insurance_dev.dbt_mtest.employer_tradional_loading limit 10;



--loading a file with a different file structure to see what type of error it generates
COPY INTO insurance_dev.dbt_mtest.employer_tradional_loading 
(
EMPLOYER_ID,
ABN, 
EMPLOYER_NAME,
INDUSTRY,
REGION,
PREMIUM_SEGMENT, 
EMPLOYEE_COUNT,
EFFECTIVE_DATE, 
LAST_UPDATED_DATE, 
FILE_NAME,
LOAD_TIMESTAMP,
LOAD_ID
)
FROM (
SELECT 
$1 as EMPLOYER_ID,
$2 as ABN,
$3 as EMPLOYER_NAME, 
$4 as INDUSTRY, 
$5 as REGION,
$6 as PREMIUM_SEGMENT, 
$7 as EMPLOYEE_COUNT,
TO_DATE($8, 'YYYY-MM-DD')  as EFFECTIVE_DATE,
TO_DATE($9, 'YYYY-MM-DD')  as LAST_UPDATED_DATE, 
METADATA$FILENAME AS FILE_NAME, 
CURRENT_TIMESTAMP() AS LOAD_TIMESTAMP,
md5(METADATA$FILENAME) AS LOAD_ID
FROM @INSURANCE_DEV.DBT_MTEST.employer_stage_s3/staging/employers_v3.csv
)
force = true
FILE_FORMAT = (format_name = 'INSURANCE_DEV.DBT_MTEST.CSV_LOADER');
