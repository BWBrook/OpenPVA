# WP-0.5.4 artefact bundle

Date: 2026-02-08

This bundle captures evidence for the controller-level reproduction draw
pathway and reproduction EV/cat integration.

## Demonstration artefacts

- `repro_controller_demo_summary.csv`
- `repro_controller_demo_extinction.csv`
  - Generated from `run_basic_simulation_replicates()` using
    `breeding_prob_fun` + `fecundity_lambda_fun` with reproduction EV/cat
    parameters.
- `repro_controller_note.txt`
  - Quick statistics from the demo run:
    - `mean_env_repro_p_mult: 0.9852`
    - `mean_env_repro_lambda_mult: 0.9696`
    - `catastrophe_fraction: 0.3062`
- `legacy_yaml_demo_summary.csv`
- `legacy_yaml_demo_extinction.csv`
  - Confirms legacy YAML v1 scenarios still execute under compatibility
    pathways.

## Build sanity evidence

- `tests.log`: `devtools::test()` passed (`PASS 405`, `FAIL 0`).
- `lint.log`: `lintr::lint_package()` reported no lints.
- `00check.log`: `R CMD check --no-manual --as-cran` completed (`0` errors, `0` warnings, notes only).
- `quarto_render.log`: `quarto render quarto` succeeded.

## Interpretation

- New controller pathway exposes year-level reproduction multiplier/flag columns
  in summary output.
- Legacy scenario pathways remain runnable without YAML schema changes.
