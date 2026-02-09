# WP-1.1.3 artefact bundle

Date: 2026-02-09

This bundle captures YAML density support evidence (schema, parser behavior,
compatibility, and runtime sanity outputs).

## Build and quality evidence

- `document.log`: roxygen regeneration completed.
- `tests_yaml.log`: focused YAML parser/migration tests passed.
- `tests.log`: full test suite passed (`PASS 481`, `FAIL 0`).
- `lint.log`: no lints.
- `build_stdout.log`: package tarball built.
- `check_stdout.log` + `00check.log`: `R CMD check --no-manual --as-cran`
  passed (`0` errors, `0` warnings; `3` notes).

## Runtime/repro evidence

- `quarto_render.log`: Quarto render succeeded.
- `targets_smoke.log`: minimal targets smoke invocation completed.
- `OpenPVA_1.0.0.tar.gz`: built package tarball.

## YAML density behavior evidence

- `yaml_density_metrics.csv`: small seeded metrics comparing:
  - schema v2 with explicit `density` block,
  - schema v2 without `density` block using legacy top-level `K`,
  - schema v1 legacy density YAML.
- `density_v2_summary.csv`: per-year summary output from density-block YAML run.
- `legacy_density_summary.csv`: per-year summary output from legacy v1 YAML run.
- `yaml_density_note.txt`: interpretation note.
- `domain_sanity.log`: execution log for sanity script.

## Validation summary

See `check_summary.txt` for one-page status.
