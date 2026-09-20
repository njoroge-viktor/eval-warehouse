-- Cleaned annotation grain: one row per (item, annotator, criterion).
--
-- Staging does type-casting and light renaming only. No business logic lives
-- here, so a change to how a metric is defined never means re-deriving the
-- source data.

with source as (
    select * from {{ ref('raw_annotations') }}
),

renamed as (
    select
        item_id,
        annotator_id,
        criterion,
        model,
        run_id,
        cast(raw_score as integer)     as raw_score,
        cast(passed as boolean)        as passed,
        cast(scored_at as timestamp)   as scored_at
    from source
)

select * from renamed
