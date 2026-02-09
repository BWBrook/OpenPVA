# WP-1.2.2 artefact bundle

Date: 2026-02-09

This bundle captures reproducibility gate tightening evidence for seeded
snapshot regressions and schema migration regression protections.

## Regression gate implementation evidence

- `tests/testthat/test_reproducibility_snapshots.R`: seeded snapshot-style
  regression tests for replicate outputs and YAML migration behavior.
- `tests/testthat/_snaps/reproducibility_snapshots.md`: committed snapshot
  fixtures used by the reproducibility gate.
- `snapshot_fixtures.md`: copy of the committed snapshot fixture file included
  in this artefact bundle.

## Validation logs

- `lint.log`: lint pass (`n_lints=0`).
- `repro_regression_tests.log`: focused reproducibility/schema test filter pass
  (`PASS 131`, `FAIL 0`).
- `tests.log`: full package tests pass (`PASS 483`, `FAIL 0`).
- `targets_smoke.log`: forced seeded smoke run for `_targets.R` (`sim_basic`).
- `quarto_render.log`: Quarto render completed.
- `build.log`: tarball build completed.
- `check.log` + `00check.log`: `R CMD check --no-manual --as-cran` completed
  with NOTE-only status.

## Notes

- Snapshot fixtures are deterministic under seeded runs and intentionally scoped
  to stable output slices to avoid brittle noise while still detecting
  behavioral drift.
