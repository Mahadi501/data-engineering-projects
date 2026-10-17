with claims_derived_fields as (

    select
        claim.claim_id,
        worker.gender,
        injury.afflication_category as injury_type,
        employer.employer_size,
        claim.claim_status,

        datediff(
            'day',
            claim.afflication_date,
            claim.lodgement_date
        ) as lodgement_delay,

        date_trunc(
            'month',
            claim.lodgement_date
        ) as lodgement_month

    from {{ ref('fact_claim') }} as claim

    left join {{ ref('dim_injury') }} as injury
        on claim.afflication_nature_cd_sk = injury.afflication_nature_cd_sk

    left join {{ ref('dim_worker') }} as worker
        on claim.worker_sk = worker.worker_sk

    left join {{ ref('dim_employer') }} as employer
        on claim.employer_sk = employer.employer_sk
),

monthly_metrics as (

    -- Overall
    select
        lodgement_month,
        'OVERALL' as dimension_name,
        'ALL' as dimension_value,
        count(claim_id) as total_claims_received,
        avg(lodgement_delay) as avg_lodgement_delay
    from claims_derived_fields
    group by lodgement_month

    union all

    -- Gender
    select
        lodgement_month,
        'GENDER' as dimension_name,
        coalesce(gender, 'UNKNOWN') as dimension_value,
        count(claim_id) as total_claims_received,
        avg(lodgement_delay) as avg_lodgement_delay
    from claims_derived_fields
    group by
        lodgement_month,
        gender

    union all

    -- Injury type
    select
        lodgement_month,
        'INJURY_TYPE' as dimension_name,
        coalesce(injury_type, 'UNKNOWN') as dimension_value,
        count(claim_id) as total_claims_received,
        avg(lodgement_delay) as avg_lodgement_delay
    from claims_derived_fields
    group by
        lodgement_month,
        injury_type

    union all

    -- Claim status
    select
        lodgement_month,
        'CLAIM_STATUS' as dimension_name,
        coalesce(claim_status, 'UNKNOWN') as dimension_value,
        count(claim_id) as total_claims_received,
        avg(lodgement_delay) as avg_lodgement_delay
    from claims_derived_fields
    group by
        lodgement_month,
        claim_status

    union all

    -- Employer size
    select
        lodgement_month,
        'EMPLOYER_SIZE' as dimension_name,
        coalesce(employer_size, 'UNKNOWN') as dimension_value,
        count(claim_id) as total_claims_received,
        avg(lodgement_delay) as avg_lodgement_delay
    from claims_derived_fields
    group by
        lodgement_month,
        employer_size
)

select *
from monthly_metrics