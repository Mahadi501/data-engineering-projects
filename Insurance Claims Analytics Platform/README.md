# Production-Grade Insurance Claims Analytics Platform

## Author
Mahad Rashid


## Overview

This demo project implements an end-to-end Insurance Claims Analytics Platform using Snowflake and dbt Cloud.

The platform ingests raw insurance data into Snowflake, applies a Medallion Architecture (Bronze → Staging → Intermediate → Silver → Gold), and produces business-ready analytical data products for reporting and analytics.

The solution includes:

- Multi-environment architecture (DEV, TEST, PROD)
- Incremental Data Processing
- Snapshot Management
- Data Quality Framework
- Dimensional Modelling
- Gold Reporting Marts
- CI/CD Release Management
- Deployment Promotion Strategy

## Business Objective

The platform was designed to support analysis of:

- Claims performance
- Employer risk exposure
- Provider performance
- Return-to-work outcomes

## Technology Stack

- Snowflake
- dbt Cloud
- Git
- dbt Generic & Singular Tests
- dbt Snapshots

## Architecture Diagram 
<img width="1574" height="704" alt="architecture_diagram" src="https://github.com/user-attachments/assets/ba14eaa3-c26d-4ab5-a73e-1075b8998d1e" />

## Environment Architecture
<img width="1832" height="204" alt="databases" src="https://github.com/user-attachments/assets/142b46de-ea21-45fe-996d-969a696e28c8" />
<img width="1138" height="388" alt="schemas" src="https://github.com/user-attachments/assets/1526211e-71b6-4261-9445-767b7d2420ab" />
## Environment Architecture

- INSURANCE_DEV
- INSURANCE_TEST
- INSURANCE_PROD

Each environment contains:

- BRONZE
- STAGING
- INTERMEDIATE
- SNAPSHOTS
- SILVER
- GOLD

## Medallion Architecture

### Bronze
Raw ingestion layer preserving source data and auditability.

### Staging
Source standardisation including column renaming, datatype standardisation and validation.

### Intermediate
Reusable enrichment and business-context models.

### Silver
Trusted business entities with deduplication, incremental processing and business rules.

### Gold
Dimensions, facts and business marts optimized for reporting and analytics.

## Project Outcomes
- Number of models built
Sources: 7 sources
Staging: 7 Staging models
Intermediate: 4 Intermediate models
Snapshot: 1 snapshot model 
Silver: 6 Silver Models
Gold: 4 data marts, 2 fact obects and 4 dimension models

- Number of tests implemented
12 singular test & 20+ generic test

- DEV → TEST → PROD deployment validation
![Environment Schemas](assets/deploy_to_prod_validation.png)

## Gold Objects

### Dimensions
- dim_worker
- dim_employer
- dim_provider
- dim_injury

### Facts
- fact_claim
- fact_payment
- fact_rtw_event

### Marts
- claims_performance_mart:
  1) How many claims per month?
  2) Claims by gender?
  3) Claims by employer type?
  4) Claims by status?
  5) Claims by Employer Size?
  6) What type of claims cost the most?
  7) AVG/MAX Delay between injury date to claim lodgement date
     
- employer_risk_mart
  1) Claims by Employer
  2) Injury Distribution across employers
  and much more...
   
- provider_performance_mart
  1) Active vs inactive providers
  2) Provider specialities
  3) Which type of providers have received the most amount of money?
  4) Provider Claim Volume
     
- rtw_performance_mart
  1) AVG/MAX/MIN RTW duration segmented by various cohorts such as injury_type, employer_size and claim_type

## Incremental Strategy

Incremental MERGE models were implemented for key Silver entities. Business-key based deduplication retains the latest version of records.

## Data Quality Framework

Generic Tests:
- not_null
- unique
- accepted_values
- relationships

Singular Tests:
- injury_date <= lodgement_date
- claim_count >= 0
- avg_lodgement_delay >= 0
- avg_rtw_days >= 0


## Load Audit Framework
The load audit frameworks maintains information about the files ingested into the audit table inside bronze table. It basically answers the fundamental question - was todays ingestion successful? If not which file loading failed? 
Every day ingestion of the 7 files are assigned a unique batch_id along with following columns: 
source_file_name: The name of the loaded source file
target Table: Name of the target table inside the bronze table
row_count: Number of records loaded during file ingestion
load_start_time: Load start time
load_end_time: load end time
load_status: status of the load

## CI/CD Strategy

Feature Branch
→ Development Validation
→ Merge to Main
→ TEST Deployment
→ UAT Validation
→ PROD Deployment
<img width="1850" height="332" alt="deploy_to_prod_validation" src="https://github.com/user-attachments/assets/b41248da-054d-4e86-824e-446e911a594d" />
## Rollback Strategy

- Git commit rollback for code defects.
- Snowflake Time Travel for data recovery.

Challenges & Lessons Learned
1) Lessons Learnt: Exception handling within the stored procedure was an important learning from this project. Ensuring that the remainder of the code runs if an exception is thrown by previous sql cammand.
2) Challenges: Returning multiple values from a store procedure as a variant object type and accssing it inside another store procedure. 
3) Challenges:Writing custom macros inside DBT so that when running dbt build command, dbt builds the objects inside the correct schema  mentioned inside the dbt_project.yml file. 
4) Challenges: Implementing how to handle late arriving data inside incremental models.
5) Lesson Learnt: Understanding that incrmental model does not automatically implement deduplication logic. Deduplication needs to be implemented separately. 
6) Lesson Learnt: Importance of adding singular and generic test, what needs to be tested? 
7) Lesson Learnt: Code does not move between envionments when deploying models into prod environment. Setting up separate envionment and snowflake connections for dev, test and prod and then orchestrating the execution of code through scheduled jobs within dbt.  
8) Documentation is important!! Always document what is the grain of your model, what does it represent so that the next developer's life becomes easy. 

## Future Enhancements

- Source Freshness Monitoring
- Automated Alerting
- Data Observability


