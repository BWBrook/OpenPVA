# OpenPVA 1.0.0-rc1 release evidence pack

Date: 2026-02-08

This folder contains reproducibility evidence for the OpenPVA `1.0.0` release
candidate.

## Package/check evidence

- `OpenPVA_1.0.0.tar.gz` (built package artefact)
- `build_stdout.log`
- `check_stdout.log`
- `00check.log`

Status summary:

- `R CMD check --no-manual --as-cran`: `0` errors, `0` warnings (`3` notes).

## Runtime evidence

- `tests.log`: full `devtools::test()` run (`PASS 437`, `FAIL 0`)
- `lint.log`: `lintr::lint_package()` (`No lints found`)
- `targets_smoke.log`: minimal targets smoke (`sim_basic`) completed

## Quarto evidence

- `quarto_render.log`: `quarto render quarto` execution log
- `quarto_output_manifest.txt`: rendered site output listing

## Toy scenario evidence

- `toy_scenario_output.rds`
- `toy_scenario_summary.csv`
- `toy_scenario_extinction.csv`
- `toy_interpretation_note.txt`

The toy run used deterministic seed `20260208L` and a simple replicated
demographic scenario with density, harvest, and survival EV/cat parameters.
