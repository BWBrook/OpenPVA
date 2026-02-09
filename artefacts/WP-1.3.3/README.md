# WP-1.3.3 artefact bundle

Date: 2026-02-09

This bundle captures evidence for decision-support output expansion.

## Implementation focus

- Added `summarise_final_abundance(sim_output, floor = 0)` for per-run and
  overall final-abundance risk/resilience metrics.
- Extended `compare_scenarios()` with additive final-abundance columns and
  optional `final_n_floor` input.
- Preserved existing output fields while adding new, documented metrics.

## Validation logs

- `document.log`: roxygen/man updates.
- `lint.log`: lint pass (`n_lints=0`).
- `tests_targeted.log`: targeted management/summary/schema/spatial tests pass
  (`PASS 130`, `FAIL 0`).
- `tests.log`: full package tests pass (`PASS 531`, `FAIL 0`).
- `targets_smoke.log`: forced `sim_basic` smoke run completed.
- `quarto_render.log`: Quarto render completed.
- `build.log`: tarball build completed.
- `check.log` + `00check.log`: `R CMD check --no-manual --as-cran` completed
  with NOTE-only status.

## Demonstration outputs

- `scenario_decision_comparison.csv`: side-by-side scenario metrics including
  extinction and final-abundance floor risk.
- `final_abundance_per_run.csv`: per-run final-year and minimum abundance.
- `final_abundance_overall.csv`: aggregated final-abundance decision metrics.
- `decision_demo.log`: seeded demo console output.

The demo indicates that higher harvest intensity increases both extinction risk
and floor-breach risk, while lower carrying capacity reduces final abundance,
matching expected management trade-offs.
