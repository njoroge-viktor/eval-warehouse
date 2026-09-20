{#
  Two-proportion z statistic for comparing two pass rates (e.g. across runs).

  Uses the pooled standard error. A NULL is returned when either group is empty
  or the pooled rate is degenerate (all-pass or all-fail), because there is no
  variance to test and a z of ±infinity would be meaningless.
#}
{% macro two_proportion_z(succ_a, tot_a, succ_b, tot_b) %}
    case
        when {{ tot_a }} = 0 or {{ tot_b }} = 0 then null
        when ({{ succ_a }} + {{ succ_b }}) = 0
          or ({{ succ_a }} + {{ succ_b }}) = ({{ tot_a }} + {{ tot_b }}) then null
        else (
            ({{ succ_b }}::double / {{ tot_b }}) - ({{ succ_a }}::double / {{ tot_a }})
        ) / sqrt(
            (({{ succ_a }} + {{ succ_b }})::double / ({{ tot_a }} + {{ tot_b }}))
            * (1 - ({{ succ_a }} + {{ succ_b }})::double / ({{ tot_a }} + {{ tot_b }}))
            * (1.0 / {{ tot_a }} + 1.0 / {{ tot_b }})
        )
    end
{% endmacro %}
