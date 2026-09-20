-- Pass rate per (run, model, criterion), with a Wilson lower bound.
--
-- This is the fact table the leaderboard and regression views build on. Grain:
-- one row per run x model x criterion.

with annotations as (
    select * from {{ ref('stg_annotations') }}
),

aggregated as (
    select
        run_id,
        model,
        criterion,
        count(*)                                as annotations,
        count(distinct item_id)                 as items,
        sum(case when passed then 1 else 0 end) as passed,
        avg(raw_score)                          as mean_raw_score
    from annotations
    group by run_id, model, criterion
)

select
    run_id,
    model,
    criterion,
    annotations,
    items,
    passed,
    annotations - passed                                  as failed,
    passed::double / annotations                          as pass_rate,
    {{ wilson_lower_bound('passed', 'annotations') }}     as pass_rate_lower_95,
    mean_raw_score
from aggregated
