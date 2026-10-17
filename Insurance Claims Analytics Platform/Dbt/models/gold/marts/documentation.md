{% docs docs_claims_performance_mart %}
### Purpose
Provides monthly claims metrics using the silver_claims object

### Grain 
One row represnts unique combination of month,dimension,dimension_value

### Business Question Answered
- number of claims received each month  and avg delay between injury date and claim lodgement date segmented by 
    - gender
    - claim_status
    - employer_size
    - injury_type

### Input Models
fact_claim, dim_worker, dim_injury,


### Consumers
- Claims Management Team Dashboard


### columns
## dimension_name
- name: dimension_name
- decription: Represents what dimension is the aggreation being performed on. If it is overall then, then there is no segmentation otherwise
represents segmented by injury_type, employer_size etc. 
- tests: not null & accepted values

## dimension_value
- name: dimension_value
- decription: Represents what dimension value for which the aggregation values are displayed. For example when dimension is Employer_Size then 
dimension value will be Large, Small etc. 
- tests: not null

## total_claims_received
- name: total_claims_received
- decription: Represents total count of claims for the aggregation combination. 
- tests: not null & singular tests on total_claims_received cant be less than 0

## avg_lodgement_delay
- name: avg_lodgement_delay
- decription: Represents delay between injury_date and claim odgement date for the aggregated combination
- tests: not null & singular tests on avg_lodgement_delay cant be less than 0

{% enddocs %}





{% docs injury_rtw_mart %}
### Purpose
Provides analysis on number of claims received across different injury_types and avg/min/max time it takes for the person to make a full 
or partial rtw.


### Grain 
One row represnts one injury_type

### Business Question Answered
- Claims across each injury_type where person rtw fully or partially 
- Avg/Max/Min time it takes across injury for injured worker to get back to work paertially or fully

### Input Models
silver_rtw_events


### Consumers
- RTW Management Dashboard


### columns
## AFFLICATION_NATURE_CD
- name: AFFLICATION_NATURE_CD
- decription: Represents the unique injury_type
- tests: not null & unique

## claim_count
- name: claim_count
- decription: Count of claims recevied against the injury where person had full rtw or partial.
- tests: not null & singular test claim_count < 0

## full_rtw_count
- name: full_rtw_count
- decription: Out of the total claims received against the claim, how many rtw fully
- tests: not null & singular test full_rtw_count < 0
## partial_rtw_count
- name: partial_rtw_count
- decription: Out of the total claims received against the claim, how many rtw partialy
- tests: not null & singular test full_rtw_count < 0

## avg_rtw_days
- name: avg_rtw_days
- decription: Avg of the days lost across the claim cohort for the particular injury type
- tests: not null & singular test avg_rtw_days < 0

## max_rtw_days
- name: max_rtw_days
- decription: max of the days lost across the claim cohort for the particular injury type
- tests: not null & singular test max_rtw_days < 0

## min_rtw_days
- name: max_rtw_days
- decription: min of the days lost across the claim cohort for the particular injury type
- tests: not null & singular test min_rtw_days < 0

{% enddocs %}



