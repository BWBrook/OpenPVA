# WP-0.5.2 artefact bundle

Date: 2026-02-08

This bundle captures evidence for the new breeding-probability API and legacy
wrapper compatibility.

## Demonstration artefacts

- `breeding_prob_table.csv`
  - Example age/sex probability table (`p_breed` in `[0, 1]`).
- `breeding_prob_demo.csv`
  - Probe individuals evaluated through `build_breeding_prob_fun_from_table()`
    and legacy `build_breeding_fun_from_table()` wrapper.
  - Observed:
    - female age 1 -> `p_breed = 0.05`, legacy eligibility `FALSE`
    - female age 5 -> `p_breed = 0.8`, legacy eligibility `TRUE`
    - male age 5 -> `p_breed = 0.0`, legacy eligibility `FALSE`

## Build sanity evidence

- `tests.log`: `devtools::test()` passed (`PASS 383`, `FAIL 0`).
- `lint.log`: `lintr::lint_package()` reported no lints.
- `00check.log`: `R CMD check --no-manual --as-cran` completed (`0` errors, `0` warnings, notes only).
- `quarto_render.log`: `quarto render quarto` succeeded.

## Interpretation

- Probability semantics are explicit and bounded.
- Legacy eligibility behavior remains available via wrappers.
