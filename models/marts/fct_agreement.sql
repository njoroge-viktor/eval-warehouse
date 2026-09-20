-- Inter-annotator agreement per (run, model, criterion).
--
-- Surfaced as its own fact so a reviewer can see, before trusting any pass
-- rate, whether the annotators behind it actually agreed. Agreement below
-- ~0.67 means the numbers above it are unreliable.

{{ fleiss_kappa_two_rater(
    relation=ref('stg_annotations'),
    partition_by=['run_id', 'model', 'criterion'],
    label_col='passed',
    item_col='item_id'
) }}
