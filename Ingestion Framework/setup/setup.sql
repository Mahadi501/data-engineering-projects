-- CREATE DATABASE
CREATE DATABASE IF NOT EXISTS INSURANCE_DEV;

-- CREATE SCHEMA 
create schema if not exists insurance_dev.DBT_MTEST;


-- CREATE XS WAREHOUSE 
CREATE WAREHOUSE IF NOT EXISTS MY_XS_WH
WITH WAREHOUSE_SIZE = 'XSMALL'
AUTO_SUSPEND = 60
AUTO_RESUME = TRUE
INITIALLY_SUSPENDED = TRUE;

-- github connection through api 
CREATE OR REPLACE API INTEGRATION GIT_OAUTH_INTEGRATION2
    API_PROVIDER = GIT_HTTPS_API
    API_ALLOWED_PREFIXES = (
        'https://github.com/Mahadi501'
    )
    API_USER_AUTHENTICATION = (
        TYPE = SNOWFLAKE_GITHUB_APP
    )
    ENABLED = TRUE;


use database INSURANCE_DEV;
use warehouse MY_XS_WH;
use schema BRONZE;

-- file format for file ingestion by column position
create file format if not exists INSURANCE_DEV.DBT_MTEST.csv_loader 
FIELD_DELIMITER = ','
skip_header = 1
TYPE = 'CSV'
comment = 'File format for loading CSV files';

-- file format for file ingestion by match by column name
create file format if not exists INSURANCE_DEV.DBT_MTEST.csv_loader2 
FIELD_DELIMITER = ','
parse_header = true
TYPE = 'CSV'
comment = 'File format for loading CSV files';

--create an external stage within s3
CREATE OR REPLACE STAGE insurance_dev.DBT_MTEST.employer_stage_s3
URL='s3://bronze-employer-ingestion/bronze'
    CREDENTIALS = (
        AWS_KEY_ID = 'enter here'
        AWS_SECRET_KEY = 'enter here'
    )
file_format = csv_loader;

--view files
list @insurance_dev.DBT_MTEST.employer_stage_s3;














 