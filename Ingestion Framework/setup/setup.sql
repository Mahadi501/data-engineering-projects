use database insurance_dev;
use warehouse compute_wh;
use schema dbt_mtest;

-- file format 
create file format if not exists INSURANCE_DEV.DBT_MTEST.csv_loader 
FIELD_DELIMITER = ','
skip_header = 1
TYPE = 'CSV'
comment = 'File format for loading CSV files';


--create an external stage within s3
CREATE OR REPLACE STAGE insurance_dev.dbt_mtest.employer_stage_s3
URL='s3://bronze-employer-ingestion/bronze'
    CREDENTIALS = (
        AWS_KEY_ID = 'enter-id'
        AWS_SECRET_KEY = 'enter-key'
    )
file_format = csv_loader;

--view files
list @insurance_dev.dbt_mtest.employer_stage_s3;














 