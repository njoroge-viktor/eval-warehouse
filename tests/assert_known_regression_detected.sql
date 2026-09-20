-- The seed data contains a deliberate gpt-4o security drop between runs.
-- If the regression logic stops flagging it, this fails — a canary for the
-- two-proportion test and the run-over-run join.
select 1 as failure
where not exists (
    select 1
    from {{ ref('fct_run_regressions') }}
    where model = 'gpt-4o'
      and criterion = 'security'
      and classification = 'regression'
)
