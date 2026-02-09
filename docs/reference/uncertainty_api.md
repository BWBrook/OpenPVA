# Uncertainty Ensemble API (WP-2B.2/WP-2B.3)

This page documents the R-level uncertainty ensemble interfaces introduced in
`WP-2B.2` and schema-linked behavior added in `WP-2B.3`.

## Exported functions

- `sample_uncertainty_parameters(uncertainty_spec, n_draws, seed = NULL)`
- `run_scenario_ensemble(scenario, uncertainty_spec = NULL, n_draws, seed = NULL)`
- `summarise_ensemble_outputs(ensemble_output, extinction_threshold = 0, final_n_floor = extinction_threshold)`

## `uncertainty_spec` format

`uncertainty_spec` is a named list. Each name must correspond to a writable
field on a scenario object (for example `cat_surv_prob`, `cat_surv_mult`,
`harvest_quota`).

If `run_scenario_ensemble()` is called with `uncertainty_spec = NULL`, it will
use `scenario$uncertainty_spec` when present (for example from schema v3 YAML).

Each parameter spec supports:

- Required `dist`: one of `"fixed"`, `"uniform"`, `"normal"`, `"lognormal"`.
- Distribution fields:
  - `"fixed"`: `value`
  - `"uniform"`: `min`, `max`
  - `"normal"`: `mean`, `sd`
  - `"lognormal"`: `meanlog`, `sdlog`
- Optional fields:
  - `lower`: clamp lower bound
  - `upper`: clamp upper bound
  - `integer`: logical; rounds draws to nearest integer when `TRUE`

## Reproducibility behavior

- All three functions accept optional integer `seed`.
- When a seed is provided, caller RNG state is restored on exit.
- `run_scenario_ensemble()` uses one seed stream for:
  - uncertainty parameter draws, and
  - stochastic simulation outcomes within each draw.

## Example

```r
spec <- list(
  harvest_quota = list(dist = "uniform", min = 0, max = 6, integer = TRUE),
  cat_surv_prob = list(dist = "uniform", min = 0, max = 0.2),
  cat_surv_mult = list(dist = "lognormal", meanlog = log(0.8), sdlog = 0.1, upper = 1)
)

sc <- scenario_spec(
  name = "uncertainty_demo",
  n_runs = 10,
  n_years = 30,
  init_fun = function() initialize_population(50),
  harvest_quota = 0
)

ens <- run_scenario_ensemble(sc, spec, n_draws = 20, seed = 20260211L)
ens_summary <- summarise_ensemble_outputs(ens, extinction_threshold = 0, final_n_floor = 10)
```

## Notes and caveats

- YAML schema v3 can populate `scenario$uncertainty_spec` via the
  `uncertainty` block consumed by `read_scenario_yaml()`.
- Schema v2 intentionally rejects `uncertainty` blocks with explicit guidance
  to migrate to `schema_version: 3`.
- Draw-level uncertainty values are fixed across replicate runs inside each draw
  by design in 2B.
- Full statistical calibration/inference remains out of scope for `WP-2B.2`.
