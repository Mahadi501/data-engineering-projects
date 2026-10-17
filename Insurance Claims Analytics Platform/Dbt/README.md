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

## Objective

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
![architecture_diagram](https://github.com/user-attachments/assets/46ad2072-cc66-4979-bd61-4e0e16594e36)


## Environment Architecture
![databases](https://github.com/user-attachments/assets/8280bd86-278f-4396-ac24-b2371778c6f0)
![schemas](https://github.com/user-attachments/assets/8c639abd-1e48-4eb1-87ae-e89665d01aba)

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
- claims_performance_mart
- employer_risk_mart
- provider_performance_mart
- rtw_performance_mart

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

## CI/CD Strategy

Feature Branch
→ Development Validation
→ Merge to Main
→ TEST Deployment
→ UAT Validation
→ PROD Deployment

DEV → TEST → PROD deployment validation
![Environment Schemas](assets/deploy_to_prod_validation.png)

## Rollback Strategy

- Git commit rollback for code defects.
- Snowflake Time Travel for data recovery.

Challenges & Lessons Learned



## Future Enhancements

- Load Audit Framework
- Source Freshness Monitoring
- Automated Alerting
- Data Observability


