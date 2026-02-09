# Hindcast and Calibration Scaffold (WP-2B.5)

This page documents the bounded calibration scaffold introduced for Line 2B.

## Exported functions

- `score_hindcast_fit(observed, simulated, weights = NULL)`
- `generate_calibration_candidates(parameter_space, method = c("grid", "random"), n_candidates = 50, seed = NULL)`
- `run_calibration_search(scenario, candidates, observed_targets, simulate_targets_fun = NULL, seed = NULL)`

## Scoring helper

`score_hindcast_fit()` computes transparent objective metrics:

- `rmse`
- `mae`
- `bias`
- `mape` (reported as `NA` when any observed target equals zero)

Inputs can be named vectors. When both vectors are named, `simulated` is
aligned to `observed` names.

## Candidate generation

`generate_calibration_candidates()` supports bounded candidate creation:

- `method = "grid"`: Cartesian grid from parameter-specific `grid_values` or
  `n_grid` fallback between `lower` and `upper`.
- `method = "random"`: uniform random draws in bounded ranges with optional
  integer rounding and deterministic seeds.

`parameter_space` is a named list where each parameter entry includes:

- required: `lower`, `upper`
- optional: `integer`, `grid_values`, `n_grid`

## Calibration search

`run_calibration_search()` evaluates each candidate against observed targets and
returns:

- `scores`: candidate table with objective/error diagnostics,
- `best_fit`: one-row best candidate summary,
- `observed_targets`: one-row table of provided observed targets.

Default `simulate_targets_fun` emits:

- `p_extinction`
- `mean_final_n_alive`

Objective minimization is based on `rmse` (`objective_score`).

## Caveats and limits

- This is a bounded scaffold, not full statistical inference.
- Search methods are intentionally simple (`grid`/`random`) and transparent.
- Results depend on selected targets, bounds, and simulation stochasticity.
- Calibration outputs should be interpreted with domain context and validated
  against independent scenarios where possible.
