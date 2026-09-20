-- Criterion-level change between each run and the one before it, with a
-- two-proportion z test. This is the table a release gate queries.
--
-- Grain: one row per (model, criterion, run) that has a prior run to compare
-- against. A criterion with |z| > 1.96 moved more than sampling noise explains.

with pass_rates as (
    select * from {{ ref('fct_criterion_pass_rates') }}
),

runs as (
    select * from {{ ref('stg_runs') }}
),

ordered as (
    select
        pr.*,
        r.started_at,
        lag(pr.passed)      over w as prev_passed,
        lag(pr.annotations) over w as prev_annotations,
        lag(pr.pass_rate)   over w as prev_pass_rate,
        lag(pr.run_id)      over w as prev_run_id
    from pass_rates pr
    join runs r on pr.run_id = r.run_id
    window w as (partition by pr.model, pr.criterion order by r.started_at)
)

select
    run_id,
    prev_run_id,
    model,
    criterion,
    prev_pass_rate,
    pass_rate,
    pass_rate - prev_pass_rate as delta,
    {{ two_proportion_z('prev_passed', 'prev_annotations', 'passed', 'annotations') }} as z_score,
    case
        when {{ two_proportion_z('prev_passed', 'prev_annotations', 'passed', 'annotations') }} is null
            then 'insufficient_data'
        when abs({{ two_proportion_z('prev_passed', 'prev_annotations', 'passed', 'annotations') }}) <= 1.96
            then 'noise'
        when pass_rate < prev_pass_rate then 'regression'
        else 'improvement'
    end as classification
from ordered
where prev_run_id is not null
