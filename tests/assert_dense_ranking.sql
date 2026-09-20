-- Every run's leaderboard ranks must be a gapless 1..N with no duplicates.
with ranks as (
    select run_id, count(*) as models, max(rank) as max_rank, count(distinct rank) as distinct_ranks
    from {{ ref('fct_model_leaderboard') }}
    group by run_id
)
select * from ranks
where models != max_rank or models != distinct_ranks
