# WP-1.3.2 artefact bundle

Date: 2026-02-09

This bundle captures evidence for the spatial/genetic enhancement increment:
`summarise_patch_genetic_diversity_final()`.

## Implementation focus

- Added `summarise_patch_genetic_diversity_final(sim_output, n_patches, alive_only)`.
- Added per-patch aggregation of final-time genotyped counts and diversity metrics
  (`mean_heterozygosity`, `mean_Fhat`) across replicate runs.
- Added input-validation and aggregation tests in `test_spatial_patches.R`.

## Validation logs

- `document.log`: roxygen/man updates.
- `lint.log`: lint pass (`n_lints=0`).
- `tests_targeted.log`: targeted spatial/genetic/schema tests pass (`PASS 115`, `FAIL 0`).
- `tests.log`: full package tests pass (`PASS 501`, `FAIL 0`).
- `targets_smoke.log`: forced `sim_basic` smoke run completed.
- `quarto_render.log`: Quarto render completed.
- `build.log`: tarball build completed.
- `check.log` + `00check.log`: `R CMD check --no-manual --as-cran` completed
  with NOTE-only status.

## Domain sanity outputs

- `spatial_genetic_demo.log`: seeded demo run summary.
- `patch_occupancy_final.csv`: final-time patch occupancy across runs.
- `patch_genetic_diversity_final.csv`: final-time patch genetic diversity summary.

The demo shows both patches retaining occupancy with non-identical diversity
profiles, indicating that patch-level diversity reporting is informative and
stable under seeded dispersal dynamics.
