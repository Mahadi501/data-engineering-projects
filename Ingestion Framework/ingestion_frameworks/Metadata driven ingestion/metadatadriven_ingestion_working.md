# Purpose
The purpose of the documentation is to document the detailed process on how the metadata driven ingestion framework work. What are the key stored procedures used and their working. It also documents the overall flow from incoming file -> file ingested/rejected

## Overall Flow
The main store procedure 'insurance_dev.dbt_mtest.sp_orchstrt_metadata_ingstn' calls the following store procedure to run the ingestion process:

**File Validation || Completed through calling store procedure: insurance_dev.dbt_mtest.file_validator** 

↓

**Schema Validation || Completed through calling store procedure: insurance_dev.dbt_mtest.schema_validator**

↓

**Schema Classification || Completed through calling store procedure: insurance_dev.dbt_mtest.schema_classifier**

↓

**Generate Dynamic Load Mapping || Completed through calling store procedure: insurance_dev.dbt_mtest.sp_generate_load_mapping**

↓↓

**File ingested or rejected and audit table + relevant downstream table are updated**




## Explanation of the key store procedure

### 1) File Validation || insurance_dev.dbt_mtest.file_validator

**Inputs:**
- file_path: Location of the file which needs to be ingested from the external stage
- file_format_name: The required file format which should be able read a .csv file and parse the header of the file    

**Process:**

The store procedure takes in a file from the external stage and checks through if/else to determine if the file is readable and schema validation on the file can be performed. The file validation checks include - checking if the file path exists, IS empty file, issue reading file header etc

**Outputs:**

Returns a varchar - If the file contain any of the issues such as file path not accessible, empty file or issue reading file header then output will not be 'FILE VALIDATION SUCCESS' and schema validation will not be performed. 

RETURNS:
- 'FAILED - file path not found' if invalid file path
- 'FAILED - incoming file is empty (0 bytes)' if incoming file is empty
- 'FAILED - unable to read schema' if returned row count is 0
- 'FILE VALIDATION SUCCESS' if file validation is success



### 2) Schema Validation || insurance_dev.dbt_mtest.schema_validator

**Inputs:**

- File_path: Location of the file which needs to be ingested from the external stage
- source_type: refers to data entity for the incoming file such as employer, customer etc
- batch_id VARCHAR: refers to the unique ingestion batch id generated at the start of ingestion process inside the sp_orchstrt_metadata_ingstn.
- file_format: The required file format which should be able read a .csv file and parse the header of the file 

**Process:**

The purpose of this store procedure is to perform a comparison between the file header of the incoming file which has passed file validation and the current active information inside the schema registry for the incoming source. Based on the comparison it tells if a new column has been added into the incoming file, detect missing columns inside the incoming file, detect data type changes.  

**Outputs:**

Writes into the insurance_dev.dbt_mtest.schema_validation_results table the results of the schema validation for the batch_id and source combo. The results are at a column level. Against every column the two essential key outputs are recorded inside: 

- mapping_status column: 'Column Matched', 'Column Type Mismatched','Column Renamed','Column Position Mismatched'
- column_mapping_status: if mapping_status not in ('Column Matched')  then 'Failed' else 'Passed'



### 3) Schema Classification || insurance_dev.dbt_mtest.schema_classifier

**Inputs:**

- source: refers to data entity for the incoming file such as employer, customer etc
- batch_id VARCHAR: refers to the unique ingestion batch id generated at the start of ingestion process inside the sp_orchstrt_metadata_ingstn.


**Process:**

The results produced by the schema validator are on a column level which does not tell us the final verdict on if the incoming file should be ingested or not. Therefore the Schema classifier helps us compile up the results from a column level to a file level.  

**Outputs:**

The file level results are written in a table called insurance_dev.dbt_mtest.schema_validation_summary. The action column within the table contains the result compiled at the file level. The possible values for 'action' column are: 

- load
- load_with_position_mismatch_warning
- reject_column_missing
- reject_data_type_mismatch
- reject_column_renamed
- load_with_warning_new_column_found


### 4) Generate Load Mapping || insurance_dev.dbt_mtest.sp_generate_load_mapping

**Inputs:**

- p_batch_id: refers to data entity for the incoming file such as employer, customer etc
- p_source_name VARCHAR: refers to the unique ingestion batch id generated at the start of ingestion process inside the sp_orchstrt_metadata_ingstn.


**Process:**

Based on the file level verdict stored in the action column the generate mapping takes place. The reason for doing it that when loading from stage the harcoding is done such as $1 as employer_id, $2 as abn..... which defeats the purpose of the dynamic element inside the metadata driven ingestion framework. By generating a dynamic level mapping based on the batch_id and column level validation results the harcoding can be avoided. Within the metadata driven framework, the sp_generate_load_mapping procedure is only called when the file level action is 'load' or 'load_with_warning' or 'load_with_warning_new_column_found'. For all other actions the generate mapping will not be generated as file will not be ingested.   

**Outputs:**


Uses the LISTAGG(mapping_code, ', ')  function to join all the row level data as one long string. This will then be used as the mapping string. Here is what the LISTAGG generates: 
$1 as employer_id, $2 as abn, $3 as employer_name, $4 as industry, $5 as region, $7 as employee_count, $10 as effective_date, $11 as last_updated_date

This string is then returned through a varchar variable and used within the sp_orchstrt_metadata_ingstn store procedure




## Important tables in the background
### 1) insurance_dev.dbt_mtest.schema_validation_results 

**Description:** 

This table stores the comparison results at a column level between the incoming file schema header and active schema inside the schema registry table. The comparison is done both ways from active schema to incoming file header and file header to active schema. This allows in understanding both missing column missings in the incoming file  and also any additional columns coming inside the file. 
For understanding if a column mismatched column is a potnetial renamed column, the code uses: JAROWINKLER_SIMILARITY() funcation to understand similarity between two columns. For example, JAROWINKLER_SIMILARITY() will give a very high scrore when run on employer_name and employer_nm and a very low score on employer_name and branch_name. The JAROWINKLER_SIMILARITY comes with a risk that a high score does not necassirily mean that the column will always be a rename. For example, address_1 and address_2 are not rename column but two separate columns. Therefore the metadata frameworks flags such renames for further review rather than automatically fixing rename and loading the file incorrectly. 
Two important columns in this table are: 
- mapping_status with values: 'Column Matched','Column Type Mismatched','Column Renamed','Column Position Mismatched','Column Added'
- column_mapping_status: 'Failed' and 'Passed'


### 2) insurance_dev.dbt_mtest.schema_validation_summary


**Description:** 

This table stores the compiled file level comparison results into the table. This table provides the final action on what needs to be done with the incoming file. This action is stored in the following column: 
- action: 'load','load_with_position_mismatch_warning','reject_column_missing','reject_data_type_mismatch','reject_column_renamed','load_with_warning_new_column_found'

### 3) insurance_dev.dbt_mtest.SCHEMA_REGISTRY_TABLE


**Description:** 

This table stores the all the schema versions of all the sources. It contains the EFFECTIVE_FROM_DATE,EFFECTIVE_TO_DATE and CURRENT_FLAG column which basically helps identify which is the current schema format for the source. At any given point only one schema format will have the CURRENT_FLAG = 'Y'. 
However, keeping all the format inside the table helps answers the business question, that lets say a employer source file was ingested in 2017-09-01, was the file format valid for the valid? Were there any differences between the schema format and incoming file


### 4) insurance_dev.dbt_mtest.audit_table


**Description:** 

This table stores the entire lifecycle of the incoming file from file_received -> loaded. If the file ingestion fails due to any ingestion this audit table explains at which step error has occured. This helps with debugging. 

**Successful Load looks like:**

file_received

↓

file_validated

↓

schema_validated

↓

loading or load_with_position_mismatch_warning or load_with_warning_new_column_found

↓


mapping_generated

↓

loaded

↓

SP returns:  'metadata ingestion process completed - check audit table for batch_id: ' || v_batch_id;


**Unsuccessful Load with file validation failed looks like:**

file_received

↓

file_validation_failed

↓

SP returns:  'Ingestion Failed - Check audit table for batch_id: ' || v_batch_id;

**Unsuccessful Load because of column missing in incoming file**

file_received

↓

file_validated

↓

schema_validated

↓

reject_column_missing

↓

SP returns:  'metadata ingestion process completed - check audit table for batch_id: ' || v_batch_id;


**Unsuccessful Load because of column data type mismatch in incoming file**

file_received

↓

file_validated

↓

schema_validated

↓

reject_data_type_mismatch
↓

SP returns:  'metadata ingestion process completed - check audit table for batch_id: ' || v_batch_id;


**Unsuccessful Load because of column potential column rename in incoming file**

file_received

↓

file_validated

↓

schema_validated

↓

reject_column_renamed

↓

SP returns:  'metadata ingestion process completed - check audit table for batch_id: ' || v_batch_id;


**Unsuccessful Load because of unknown issues during ingestion process**
file_received

↓

file_validated

↓

schema_validated

↓

Failed - Unknown reason

↓

SP returns:  'metadata ingestion process completed - check audit table for batch_id: ' || v_batch_id;