# Reproduction Rate API

This page documents baseline-rate helpers that can be called from a
`reproduction_process()` model function.

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

## Stage 1 boundary

`reproduction_process()` owns Bernoulli breeding and Poisson litter draws.
Project model functions may use these table helpers to provide baseline rates.
The old controller-level reproduction and mate-limiting helpers are retired;
process-native mating constraints belong in a later scientific-module goal.
