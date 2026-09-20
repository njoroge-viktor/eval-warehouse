-- A confidence lower bound that sits above the point estimate is a math error.
-- This guards the Wilson macro against a sign or algebra regression.
select
    run_id,
    model,
    criterion,
    pass_rate,
    pass_rate_lower_95
from {{ ref('fct_criterion_pass_rates') }}
where pass_rate_lower_95 > pass_rate + 1e-9
