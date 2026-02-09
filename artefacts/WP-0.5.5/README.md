# WP-0.5.5 artefact bundle

Date: 2026-02-08

This bundle captures evidence for YAML schema v2 support, including
reproduction-semantics channels and `reproduction_ev` parsing, while retaining
schema v1 compatibility.

## YAML v1/v2 demonstration outputs

- `v1_yaml_summary.csv`
- `v1_yaml_extinction.csv`
  - Produced from `inst/extdata/demo_demography.yaml` (`schema_version: 1`).
- `v2_yaml_summary.csv`
- `v2_yaml_extinction.csv`
  - Produced from `inst/extdata/demo_reproduction_v2.yaml` (`schema_version: 2`).
- `yaml_v1_v2_note.txt`
  - Quick check values from both runs:
    - `v1_schema_attr: 1`
    - `v2_schema_attr: 2`
    - `v1_mean_births: 7.9060`
    - `v2_mean_births: 8.1667`
    - `v2_repro_cat_fraction: 0.0500`

## Build sanity evidence

- `tests.log`: `devtools::test()` passed (`PASS 437`, `FAIL 0`).
- `lint.log`: `lintr::lint_package()` reported no lints.
- `check_stdout.log` + `00check.log`: `R CMD check --no-manual --as-cran`
  completed with `0` errors, `0` warnings (`3` documented notes).
- `quarto_render.log`: `quarto render quarto` succeeded.
- `targets_smoke.log`: minimal targets smoke (`sim_basic`) completed.

## Interpretation

- Schema v2 YAML parses to `yaml_schema_version = 2` and feeds controller-level
  reproduction summary fields.
- Schema v1 YAML remains runnable with `yaml_schema_version = 1`.
- Migration/adaptation pathways keep old and new YAML forms interoperable.
