-- Per-run model leaderboard: overall pass rate plus head-to-head record.
--
-- Grain: one row per run x model. Ranked by Wilson lower bound, so a model is
-- rewarded for evidence rather than a small-sample headline rate.

with pass_rates as (
    select * from {{ ref('fct_criterion_pass_rates') }}
),

overall as (
    select
        run_id,
        model,
        sum(annotations)                              as annotations,
        sum(passed)                                   as passed,
        sum(passed)::double / sum(annotations)        as pass_rate,
        {{ wilson_lower_bound('sum(passed)', 'sum(annotations)') }} as pass_rate_lower_95
    from pass_rates
    group by run_id, model
),

comparisons as (
    select * from {{ ref('stg_comparisons') }}
),

wins as (
    select run_id, winner as model, count(*) as wins
    from comparisons where winner is not null
    group by run_id, winner
),

losses as (
    select run_id, loser as model, count(*) as losses
    from comparisons where loser is not null
    group by run_id, loser
),

ties as (
    select run_id, model, count(*) as ties from (
        select run_id, model_a as model from comparisons where is_tie
        union all
        select run_id, model_b as model from comparisons where is_tie
    ) t
    group by run_id, model
)

select
    o.run_id,
    o.model,
    o.annotations,
    o.passed,
    o.pass_rate,
    o.pass_rate_lower_95,
    coalesce(w.wins, 0)   as wins,
    coalesce(l.losses, 0) as losses,
    coalesce(t.ties, 0)   as ties,
    case
        when coalesce(w.wins,0) + coalesce(l.losses,0) + coalesce(t.ties,0) = 0 then null
        else (coalesce(w.wins,0) + 0.5 * coalesce(t.ties,0))::double
             / (coalesce(w.wins,0) + coalesce(l.losses,0) + coalesce(t.ties,0))
    end as win_rate,
    row_number() over (
        partition by o.run_id
        order by o.pass_rate_lower_95 desc, o.model
    ) as rank
from overall o
left join wins w   on o.run_id = w.run_id and o.model = w.model
left join losses l on o.run_id = l.run_id and o.model = l.model
left join ties t   on o.run_id = t.run_id and o.model = t.model
