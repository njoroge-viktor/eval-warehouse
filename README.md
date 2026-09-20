# eval-warehouse

[![CI](https://github.com/njoroge-viktor/eval-warehouse/actions/workflows/ci.yml/badge.svg)](https://github.com/njoroge-viktor/eval-warehouse/actions/workflows/ci.yml)
[![dbt](https://img.shields.io/badge/dbt-1.9-FF694B)](https://www.getdbt.com/)
[![DuckDB](https://img.shields.io/badge/DuckDB-embedded-FFF000)](https://duckdb.org/)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

An analytics warehouse for LLM evaluation telemetry, built with **dbt** on
**DuckDB**. Turns raw annotation and comparison data into model leaderboards,
inter-annotator agreement and statistical regression detection.

DuckDB is embedded, so the whole warehouse is one file and the project runs
from a clean checkout with no database server:

```bash
pip install -r requirements.txt
dbt deps && dbt seed && dbt build   # DBT_PROFILES_DIR=.
```

## The layered model

```
seeds/         raw_annotations, raw_comparisons, raw_runs   (sample telemetry)
   |
staging/       stg_*  — cast, rename, decode verdicts        (views, no logic)
   |
marts/         fct_*  — the analytics                        (tables)
```

Staging does type-casting and light renaming only — no business logic — so a
change to how a metric is *defined* never means re-deriving the source data.
Every metric lives in exactly one mart.

## What the marts answer

**`fct_criterion_pass_rates`** — pass rate per run × model × criterion, each
with a 95 % **Wilson lower bound**. Wilson rather than the normal approximation
because eval pass rates cluster near 0 % and 100 % on small samples, where the
normal interval misbehaves and can leave `[0, 1]` entirely.

**`fct_model_leaderboard`** — per-run ranking, plus head-to-head W/L/T from the
pairwise comparisons. Ranked by the **Wilson lower bound**, not the raw rate, so
a model is rewarded for evidence rather than a lucky small-sample headline:

```
rank  model               pass_rate  lower_95  W/L/T      win_rate
  1   claude-3-5-sonnet     0.894      0.855    35/5/0      0.875
  2   gpt-4o                0.820      0.774    16/26/0     0.381
  3   llama-3-70b           0.706      0.654     9/29/0     0.237
```

**`fct_agreement`** — Fleiss' kappa per run × model × criterion. A pass rate
computed from labels the annotators cannot agree on is not a measurement, so
agreement is a first-class fact, not an afterthought.

**`fct_run_regressions`** — every criterion's change against the prior run,
classified by a **two-proportion z-test**:

```
model    criterion   before  after   delta    z      classification
gpt-4o   security     0.700   0.475  -0.225  -2.89    regression
...11 other criteria moved within sampling noise and are labelled 'noise'
```

Only statistically significant moves are called regressions. A 2–3 point wobble
that a raw diff would flag is correctly labelled `noise`, because chasing noise
is how a team loses trust in its own dashboards.

## The statistics live in tested macros

The fiddly SQL is in reusable macros, so it exists once and is verified:

- `wilson_lower_bound(successes, total, z)`
- `two_proportion_z(succ_a, tot_a, succ_b, tot_b)` — pooled SE, NULL when a
  group is empty or degenerate rather than returning ±infinity
- `fleiss_kappa_two_rater(...)` — a relation-returning macro the agreement mart
  selects from

## Testing

`dbt build` runs the models and **32 tests** together: schema tests (uniqueness
of every grain, `[0,1]` range on rates, accepted values on verdicts and
classifications) plus three singular data tests that assert behaviour:

- the Wilson lower bound never exceeds the point estimate (guards the macro
  algebra),
- each run's leaderboard ranks are a gapless `1..N`,
- **the known planted regression is still detected** — a canary for the whole
  regression pipeline. This test caught a real problem during development: when
  the sample data was regenerated with realistically *correlated* annotators,
  an 8-point drop stopped being significant, exactly as the statistics should
  behave. The fix was to make the planted regression genuinely large, not to
  weaken the test.

## Sample data

The seeds are generated with a latent per-item quality that both annotators
observe with 90 % reliability, so inter-annotator agreement is realistic
(average kappa ≈ 0.43) rather than the ~0 that independent random labels would
produce. One deliberate regression is planted — a gpt-4o security drop between
the two runs — for the regression mart to find.

## License

MIT — see [LICENSE](LICENSE).
