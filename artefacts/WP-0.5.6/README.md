# WP-0.5.6 artefact bundle

Date: 2026-02-08

This bundle captures evidence for docs/demo refresh after the reproduction
refactor, including explicit schema v2 guidance and v1 compatibility examples.

## Demo evidence (YAML v1 vs v2 reproduction behaviour)

- `repro_yaml_metrics.csv`
  - Side-by-side metrics for packaged YAML demos:
    - `demo_demography_v1` (`schema_version: 1`)
    - `demo_reproduction_v2` (`schema_version: 2`)
- `v1_summary_head.csv`
- `v2_summary_head.csv`
  - Summary excerpts highlighting reproduction EV/cat diagnostic fields.

## Build sanity evidence

- `tests.log`: `devtools::test()` passed (`PASS 437`, `FAIL 0`).
- `lint.log`: `lintr::lint_package()` reported no lints.
- `check_stdout.log` + `00check.log`: `R CMD check --no-manual --as-cran`
  completed with `0` errors, `0` warnings (`3` documented notes).
- `quarto_render.log`: `quarto render quarto` succeeded.
- `targets_smoke.log`: minimal targets smoke (`sim_basic`) completed.

## Interpretation

- README and Quarto now explicitly document:
  - preferred breeding/fecundity channels (`breeding_prob_fun`,
    `fecundity_lambda_fun`),
  - reproduction EV/cat parameters and summary diagnostics,
  - v1 compatibility and v2 schema migration expectations.
- Demonstration outputs confirm schema v2 EV/cat behaviour while preserving
  schema v1 execution paths.
