# Reproduction Rate API

This page documents the reproduction-rate interfaces used by the controller
reproduction pathway.

## Breeding probability API

Primary (new) functions:

- `validate_breeding_prob_table(tbl)`
- `build_breeding_prob_fun_from_table(tbl)`
- `make_default_breeding_prob_table()`

Contract:

- Table columns: `age_min`, `age_max`, `sex`, `p_breed`
- `p_breed` must be in `[0, 1]`
- Age intervals cannot overlap within sex
- Builder returns `p_breed` by age/sex, default `0` when unmatched

- `default_breeding_prob_fun(ind)` provides the package default baseline
  breeding schedule.

## Fecundity lambda API

Primary (new) functions:

- `validate_fecundity_lambda_table(tbl)`
- `build_fecundity_lambda_fun_from_table(tbl)`
- `make_default_fecundity_lambda_table()`

Contract:

- Table columns: `age_min`, `age_max`, `sex`, `lambda`
- `lambda` must be non-negative
- Age intervals cannot overlap within sex
- Builder returns `lambda` by age/sex, default `0` when unmatched

- `default_fecundity_lambda_fun(ind)` provides the package default baseline
  fecundity schedule.

## Implementation note

These APIs are the retained baseline-rate channels for:

- controller-level Bernoulli/Poisson reproduction draws,
- year-level reproduction EV/cat modifiers,
- YAML schema v3 demography tables (`breeding_prob`, `fecundity_lambda`).

## Mating control extension

OpenPVA also provides a mating-control helper for constrained pairing:

- `make_mate_limited_mating_fun(max_mates_per_male = 1L)`

This function can be supplied to `scenario_spec()` / `run_basic_simulation()`
as `mating_fun`. Combined with `require_mate = TRUE`, it enforces per-year mate
scarcity constraints by skipping births for females without available mates.
