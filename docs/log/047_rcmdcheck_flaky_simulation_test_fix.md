# Log 047 — `R CMD check` flaky simulation-core test fix

## Date
- 2026-04-08

## Trigger
- Latest GitHub Actions failures after switching CI off `devtools`:
  - `ci-fast` run `24114327523`
  - `ci-heavy-validation` run `24114332719`

## Failure summary
- Both workflows progressed through bootstrap, tests, and build setup, then
  failed at `R CMD check`.
- The failure was in package test execution under check-time conditions:
  - `test_simulation_core.R:76`
  - `test_simulation_core.R:77`

## Root-cause analysis
- The test `run_basic_simulation_replicates produces consistent summaries`
  asserted exact `n_alive` and `n_births` values while using the stochastic
  Poisson reproduction pathway with no fixed seed.
- This was an invalid exact-count assumption, not a model bug.
- The looser `pkgload` test run could pass depending on ambient RNG state,
  while `R CMD check` exposed the flakiness consistently.

## Implemented fix
- Updated `tests/testthat/test_simulation_core.R` to assert invariants that are
  actually guaranteed by the model configuration:
  - `n_births >= 0`
  - `n_alive == initial_alive + n_births` when survival is forced to `1`
  - sex counts sum to `n_alive`

## Verification done
- `testthat::test_file('tests/testthat/test_simulation_core.R')` passed.
- `Rscript scripts/run_tests.R` passed (`532` pass).
- `R CMD check --no-manual OpenPVA_*.tar.gz` returned `Status: OK`.

## Follow-up
1. Push the test fix and rerun CI on the latest `main` head.
2. Prefer invariant-based assertions or seeded characterization tests for any
   stochastic simulation pathway going forward.
