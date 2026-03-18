# Log 044 — macOS smoke-default validation pass

## Date
- 2026-03-18

## Summary
- Validated a fresh macOS restore/build path.
- Reduced default demo `_targets.R` ensemble sizes so the baseline pipeline is
  a practical smoke run on a laptop.
- Replaced current operational docs/release commands that assumed `devtools`
  with a package-native `pkgload` + `testthat` test entrypoint.

## Changes made
- Added `scripts/run_tests.R` as the canonical package test command.
- Updated:
  - `README.md`
  - `scripts/build_release_evidence.sh`
  - `docs/reference/release_automation.md`
  - `docs/reference/ci_profiles.md`
  - `docs/dev_conventions_r.md`
- Reduced `_targets.R` default demo workloads to:
  - `sim_basic_reps`: `20` runs x `30` years
  - `sim_basic_dense_harvest`: `15` runs x `30` years
  - `spatial_scenario_two_patch`: `5` runs x `20` years
- Updated repo memory:
  - `docs/plan.md`
  - `docs/interpretation_notes.md`

## Validation and evidence
- `Rscript bootstrap_env.R` -> success.
- `Rscript -e "renv::status()"` -> consistent.
- `Rscript scripts/run_tests.R` -> `PASS 531`, `FAIL 0`.
- `quarto render quarto` -> success (`outputs/quarto_site/index.html`).
- Direct smoke benchmark:
  - `run_basic_simulation_replicates(n_runs = 2, n_years = 5, ...)`
  - success in about `0.16s`.

## Notes
- A direct benchmark of the former larger demo ensemble (`100` runs x `50`
  years) showed expected heavy single-core CPU use on this Mac. That appears to
  be normal IBM-style workload cost for the current individual-based engine, not
  a macOS correctness bug.
- This pass intentionally did not change engine semantics or expose a new
  parallel interface in the default demo path.

## Follow-up
1. If desired later, add an explicit parallel or “heavy validation” profile for
   larger ensemble runs.
2. Optionally capture a full elapsed-time benchmark for the resized default
   `_targets.R` path in a future artefact bundle.
