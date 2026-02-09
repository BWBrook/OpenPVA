# WP-1.3.1 artefact bundle

Date: 2026-02-09

This bundle captures reproduction feature-extension evidence for mate-required
and mate-limited controls.

## Implementation focus

- Added `make_mate_limited_mating_fun()`.
- Added `require_mate` control through reproduction/controller/scenario/YAML
  pathways with backward-compatible default (`FALSE`).

## Build/test evidence

- `document.log`: roxygen/man updates.
- `lint.log`: lint pass (`n_lints=0`).
- `tests_targeted.log`: targeted reproduction/scenario/YAML tests pass.
- `tests.log`: full package tests pass (`PASS 493`, `FAIL 0`).
- `targets_smoke.log`: forced `sim_basic` smoke run completed.
- `quarto_render.log`: Quarto render completed.
- `build.log`: tarball build completed.
- `check.log` + `00check.log`: `R CMD check --no-manual --as-cran`
  completed with NOTE-only status.

## Domain sanity evidence

- `mating_control_metrics.csv`: seeded comparison across:
  - `limited_require_mate_false`,
  - `limited_require_mate_true`,
  - `unlimited_require_mate_true`.
- `mating_control_note.txt`: interpretation summary of observed differences.
