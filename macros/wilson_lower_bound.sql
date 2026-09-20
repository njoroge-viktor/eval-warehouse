{#
  Wilson score interval lower bound for a binomial proportion.

  Preferred over the normal approximation because eval pass rates cluster near
  0% and 100% and are often computed on small n, where the normal interval
  misbehaves (it can exceed [0,1] and claims certainty at the boundary). The
  Wilson lower bound is what a leaderboard should sort on: it rewards a model
  for evidence, not just a lucky headline rate.

  z = 1.96 gives a 95% interval.
#}
{% macro wilson_lower_bound(successes, total, z=1.96) %}
    case
        when {{ total }} = 0 then 0.0
        else (
            ({{ successes }}::double / {{ total }})
              + ({{ z }} * {{ z }}) / (2.0 * {{ total }})
              - {{ z }} * sqrt(
                    (({{ successes }}::double / {{ total }}) * (1 - ({{ successes }}::double / {{ total }})))
                        / {{ total }}
                    + ({{ z }} * {{ z }}) / (4.0 * {{ total }} * {{ total }})
                )
        ) / (1 + ({{ z }} * {{ z }}) / {{ total }})
    end
{% endmacro %}
