# WP-1.2.1 artefact bundle

Date: 2026-02-09

This bundle captures evidence for the CI profile split between:

- fast PR/push gating checks (`ci-fast`), and
- scheduled/manual heavy validation (`ci-heavy-validation`).

## Fast profile evidence

- `fast_lint.log`: lint command output (no lints).
- `fast_tests.log`: full package tests passed (`PASS 481`, `FAIL 0`).
- `fast_build.log`: tarball build completed.
- `fast_check.log` + `fast_00check.log`: `R CMD check --no-manual` completed
  with NOTE-only status.

## Heavy profile evidence

- `heavy_repro_tests.log`: reproducibility/schema regression tests passed
  (`PASS 129`, `FAIL 0`).
- `heavy_full_tests.log`: full package tests passed (`PASS 481`, `FAIL 0`).
- `heavy_targets.log`: minimal targets smoke run (`sim_basic`) completed.
- `heavy_quarto.log`: Quarto render completed.
- `heavy_build.log`: tarball build completed.
- `heavy_check.log` + `heavy_00check.log`: `R CMD check --no-manual --as-cran`
  completed with NOTE-only status.

## Notes

- Heavy targets smoke was intentionally constrained to `sim_basic` to keep
  scheduled runtime predictable while preserving full-model coverage via the
  heavy full test suite.
