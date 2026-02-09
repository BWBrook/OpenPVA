# WP-0.5.3 artefact bundle

Date: 2026-02-08

This bundle captures evidence for the new fecundity-lambda API and legacy
realized-count wrapper compatibility.

## Demonstration artefacts

- `fecundity_lambda_table.csv`
  - Example age/sex lambda table (`lambda >= 0`).
- `fecundity_lambda_demo.csv`
  - Probe individuals evaluated through `build_fecundity_lambda_fun_from_table()`
    and legacy `build_fecundity_fun_from_table()` wrapper.
  - Observed:
    - female age 1 -> `lambda = 0`, legacy draw `0`
    - female age 5 -> `lambda = 2`, legacy draw `2`
    - male age 5 -> `lambda = 0`, legacy draw `0`

## Build sanity evidence

- `tests.log`: `devtools::test()` passed (`PASS 383`, `FAIL 0`).
- `lint.log`: `lintr::lint_package()` reported no lints.
- `00check.log`: `R CMD check --no-manual --as-cran` completed (`0` errors, `0` warnings, notes only).
- `quarto_render.log`: `quarto render quarto` succeeded.

## Interpretation

- Lambda semantics are explicit and non-negative.
- Legacy realized-count behavior remains available via wrappers (`Poisson(lambda)` draws).
