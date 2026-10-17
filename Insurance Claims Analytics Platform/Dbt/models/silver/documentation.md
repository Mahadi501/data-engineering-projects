{% docs docs_silver_claims %}
### Purpose
Current-state trusted claims entity used as the source of claim information across the platform. It basically consolidates claim information 
into a single business-trusted dataset containing the latest information of each claim. 

### Grain 
One row per claim

### Business Rules
- dedduplication performed using claim_id
- Retains the latest record based on the updated timestamp
- where duplicate updated time stamp exists, the latest record_loaded_timestamp is retained. 
- Preserve audit metadata columns

### Incremental strategy
- Incremental Merge Matarialisation used 
- Uses claim_id as the unique business key
- Processes new and updated changed records using updated_timestamp with a late arriving data buffer of 2 days. 


### Consumers
- fact_claim
- claims_performance_mart
- employer_risk_mart

### columns
## claim_id
- name: claim_id
- decription: Unique business identifier for the claim
- tests: not null & unique

## created_timestamp
- name: created_timestamp
- decription: Original created date from the source system

## updated_timestamp
- name: updated_timestamp
- decription: Latest source-system update timestamp used for deduplication and change processing

## source_file_name
- name: source_file_name
- decription: Name of the source file ingested in bronze from where the record originated

## batch_id
- name: batch_id
- decription: created using a md5 hash function on TO_VARCHAR(CURRENT_TIMESTAMP()). (Not ideal and something else should be used as 
we want to have one consistent hash value against the entire batch) 

{% enddocs %}


{% docs docs_silver_payments %}
### Purpose
Current-state trusted payments entity used as the source of payment information against a claim across the platform. It basically consolidates payment information 
into a single business-trusted dataset containing the latest information of each claim. 

### Grain 
One row per payment

### Business Rules
- dedduplication performed using payment_id
- Retains the latest record based on the updated timestamp
- where duplicate updated time stamp exists, the latest record_loaded_timestamp is retained. 
- Preserve audit metadata columns

### Incremental strategy
- Incremental Merge Matarialisation used 
- Uses payment_id as the unique business key
- Processes new and updated changed records using updated_timestamp with a late arriving data buffer of 2 days. 


### Consumers
- fact_payment
- provider_performance_mart
- employer_risk_mart

### columns
## payment_id
- name: claim_id
- decription: Unique business identifier for the payment
- tests: not null & unique

## created_timestamp
- name: created_timestamp
- decription: Original created date from the source system

## updated_timestamp
- name: updated_timestamp
- decription: Latest source-system update timestamp used for deduplication and change processing

## source_file_name
- name: source_file_name
- decription: Name of the source file ingested in bronze from where the record originated

## batch_id
- name: batch_id
- decription: created using a md5 hash function on TO_VARCHAR(CURRENT_TIMESTAMP()). (Not ideal and something else should be used as 
we want to have one consistent hash value against the entire batch) 

{% enddocs %}