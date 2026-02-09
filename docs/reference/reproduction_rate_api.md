# Reproduction rate API (0.5.x)

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

Compatibility adapters:

- `as_breeding_fun(breeding_prob_fun)` maps probabilities to legacy eligibility
  (`p_breed > 0`).
- `as_breeding_prob_fun(breeding_fun)` wraps legacy logical interfaces as
  numeric probabilities (`0`/`1`).

Legacy wrapper retained:

- `build_breeding_fun_from_table(tbl)` still accepts `can_breed` tables and
  returns logical eligibility.

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

Compatibility adapters:

- `as_fecundity_fun(fecundity_lambda_fun)` maps lambda to legacy realized counts
  through `Poisson(lambda)` draws.
- `as_fecundity_lambda_fun(fecundity_fun)` wraps legacy realized-count functions
  as non-negative numeric outputs.

Legacy wrapper retained:

- `build_fecundity_fun_from_table(tbl)` still returns realized counts from
  `lambda` tables (`Poisson(lambda)`).

## Implementation note

These APIs are now the preferred baseline-rate channels for:

- controller-level Bernoulli/Poisson reproduction draws,
- year-level reproduction EV/cat modifiers,
- YAML schema v2 demography tables (`breeding_prob`, `fecundity_lambda`).

Legacy builders and adapters remain available for backward compatibility.

## Mating control extension

OpenPVA also provides a mating-control helper for constrained pairing:

- `make_mate_limited_mating_fun(max_mates_per_male = 1L)`

This function can be supplied to `scenario_spec()` / `run_basic_simulation()`
as `mating_fun`. Combined with `require_mate = TRUE`, it enforces per-year mate
scarcity constraints by skipping births for females without available mates.
