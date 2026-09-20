with source as (
    select * from {{ ref('raw_runs') }}
)

select
    run_id,
    suite,
    cast(started_at as timestamp) as started_at
from source
