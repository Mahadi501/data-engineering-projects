{% snapshot employer_snapshot %}
    {{
        config(
            unique_key='Employer_id',
            strategy='timestamp',
            invalidate_hard_deletes=false,
            updated_at='LAST_UPDATED_DATE'
        )
    }}

    select * 
    from {{ ref('stg_employers') }}
 {% endsnapshot %}