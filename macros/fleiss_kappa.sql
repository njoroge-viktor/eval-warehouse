{#
  Fleiss' kappa per (run, model, criterion) for a fixed 2 raters per item.

  Inter-annotator agreement matters because a pass rate computed from labels
  the annotators cannot agree on is not a measurement. This is expressed as a
  reusable relation-returning macro so the SQL — which is fiddly — lives in one
  place and the mart just selects from it.

  With exactly two raters per item, Fleiss' kappa reduces to the observed
  agreement corrected for chance:  kappa = (Po - Pe) / (1 - Pe).
#}
{% macro fleiss_kappa_two_rater(relation, partition_by, label_col, item_col) %}

with per_item as (
    -- One row per item: did the two raters agree, and on which label.
    select
        {{ partition_by | join(', ') }},
        {{ item_col }} as item_id,
        count(*)                                         as n_ratings,
        sum(case when {{ label_col }} then 1 else 0 end) as n_true
    from {{ relation }}
    group by {{ partition_by | join(', ') }}, {{ item_col }}
    having count(*) = 2   -- Fleiss' kappa needs a fixed rater count
),

agreement as (
    select
        {{ partition_by | join(', ') }},
        count(*) as items,
        -- Po: proportion of items where both raters agreed (both true or both false).
        avg(case when n_true in (0, 2) then 1.0 else 0.0 end) as p_observed,
        -- Category marginals across all ratings, for the chance term.
        sum(n_true)::double / sum(n_ratings)     as p_true,
        1 - sum(n_true)::double / sum(n_ratings) as p_false
    from per_item
    group by {{ partition_by | join(', ') }}
)

select
    {{ partition_by | join(', ') }},
    items,
    p_observed,
    (p_true * p_true + p_false * p_false) as p_expected,
    case
        when (p_true * p_true + p_false * p_false) >= 1.0 then 1.0
        else (p_observed - (p_true * p_true + p_false * p_false))
             / (1 - (p_true * p_true + p_false * p_false))
    end as fleiss_kappa
from agreement

{% endmacro %}
