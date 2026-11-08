-- create the design of table to store raw payload
create table if not exists insurance_dev.DBT_MTEST.raw_employer_payload (
raw_payload variant,
file_name varchar,
load_timestamp datetime,
batch_id varchar,
file_row_number number(20,0)
)
comment =  'Table to load employer data as raw payload';


-- loading data into the table
COPY INTO insurance_dev.DBT_MTEST.raw_employer_payload 
( 
raw_payload,
file_name, 
load_timestamp,
batch_id,
file_row_number
) 
from (
select 
OBJECT_CONSTRUCT_KEEP_NULL(
'col1',$1,
'col2',$2,
'col3',$3,
'col4',$4,
'col5',$5,
'col6',$6,
'col7',$7,
'col8',$8,
'col9',$9,
'col10',$10,
'col11',$11,
'col14',$14,
'col15',$15
) as raw_payload,
metadata$FILENAME as file_name,
current_timestamp() as load_timestamp,
md5(metadata$FILENAME) as batch_id,
METADATA$FILE_ROW_NUMBER as file_row_number
FROM @INSURANCE_DEV.DBT_MTEST.employer_stage_s3/staging/employers_v1.csv 
)
FILE_FORMAT = (format_name = 'INSURANCE_DEV.DBT_MTEST.CSV_LOADER');


select * from insurance_dev.DBT_MTEST.raw_employer_payload limit 5;

-- unpacking the variant column
select 
raw_payload:col1::varchar as employer_id,
raw_payload:col2::varchar as ABN
from insurance_dev.DBT_MTEST.raw_employer_payload
limit 5;
