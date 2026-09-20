-- A ready-to-run analytical query: the full leaderboard for the latest run,
-- joined to its agreement floor so a reader sees both the ranking and whether
-- to trust it. Compile with `dbt compile` and run the result, or paste into
-- any DuckDB session against the built warehouse.

with latest as (
    select run_id from {{ ref('stg_runs') }} order by started_at desc limit 1
),

agreement_floor as (
    select run_id, model, min(fleiss_kappa) as worst_criterion_kappa
    from {{ ref('fct_agreement') }}
    group by run_id, model
)

select
    lb.rank,
    lb.model,
    round(lb.pass_rate, 3)          as pass_rate,
    round(lb.pass_rate_lower_95, 3) as lower_95,
    lb.wins, lb.losses, lb.ties,
    round(lb.win_rate, 3)           as win_rate,
    round(af.worst_criterion_kappa, 3) as worst_agreement,
    case when af.worst_criterion_kappa < 0.4 then 'CAUTION: low agreement' else 'ok' end as trust
from {{ ref('fct_model_leaderboard') }} lb
join latest using (run_id)
join agreement_floor af using (run_id, model)
order by lb.rank
