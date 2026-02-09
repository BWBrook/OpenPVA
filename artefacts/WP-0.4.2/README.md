# WP-0.4.2 artefact bundle

This bundle captures output-schema contract documentation and regression-test evidence.

## Implemented outcomes

- Added `docs/reference/output_schema.md` documenting required output object shapes.
- Added regression tests in `tests/testthat/test_output_schema_contract.R` for:
  - `run_basic_simulation()`
  - `run_basic_simulation_replicates()`
  - `run_scenario()`
  - summary helpers (`summarise_extinction()`, `compute_mean_trajectory()`, `summarise_harvest_yield()`)
- Added serialized example output and structure dump:
  - `output_schema_example.rds`
  - `output_schema_structure.txt`

## Verification

- `devtools::test()` passed (`346` tests total).
- Tarball `R CMD check` passed (`0` errors, `0` warnings, notes only).

## Evidence files

- `tests.log`, `tests_summary.txt`
- `build.log`, `rcmdcheck.log`, `check_summary.txt`
- `output_schema_example.rds`, `output_schema_structure.txt`
- `OpenPVA.Rcheck/00check.log`
- `session_info.txt`
