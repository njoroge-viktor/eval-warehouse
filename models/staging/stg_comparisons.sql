-- Cleaned pairwise comparison grain: one row per judgement.
--
-- Verdicts are normalised to name the winning and losing model directly, so
-- downstream models never re-implement the a/b/tie decoding.

with source as (
    select * from {{ ref('raw_comparisons') }}
),

decoded as (
    select
        prompt_id,
        annotator_id,
        run_id,
        model_a,
        model_b,
        lower(verdict) as verdict,
        cast(scored_at as timestamp) as scored_at,
        case lower(verdict)
            when 'a' then model_a
            when 'b' then model_b
            else null
        end as winner,
        case lower(verdict)
            when 'a' then model_b
            when 'b' then model_a
            else null
        end as loser,
        lower(verdict) = 'tie' as is_tie
    from source
)

select * from decoded
