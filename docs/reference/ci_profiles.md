# CI profiles (post-1.0 hardening)

OpenPVA uses two CI validation profiles so pull requests get fast feedback while
heavier reproducibility checks still run continuously.

## `ci-fast` (PR + push gate)

Workflow file: `.github/workflows/ci-fast.yaml`

Triggers:

- `pull_request`
- `push` to `main`

Checks:

- dependency restore (`renv::restore()`),
- lint (`lintr::lint_package()`),
- tests (`devtools::test()`),
- source build (`R CMD build --no-build-vignettes .`),
- package check (`R CMD check --no-manual OpenPVA_*.tar.gz`).

Purpose:

- fail fast for coding regressions,
- gate merges on core package health.

## `ci-heavy-validation` (scheduled + manual)

Workflow file: `.github/workflows/ci-heavy-validation.yaml`

Triggers:

- weekly schedule (`0 6 * * 1`, Mondays 06:00 UTC),
- manual dispatch (`workflow_dispatch`).

Checks:

- reproducibility regression tests:
  - `test_rng_seed.R`
  - `test_output_schema_contract.R`
  - `test_scenario_yaml_demography.R`
  - `test_spatial_patches.R`
  - `test_reproducibility_snapshots.R`
- full package tests,
- `targets` smoke run (forced `sim_basic`),
- Quarto render,
- tarball build + `R CMD check --no-manual --as-cran`.

Purpose:

- continuously verify deterministic behavior and schema contracts,
- detect drift in heavier pipeline/doc rendering paths.

## Local reproduction commands

Fast profile equivalent:

```bash
Rscript -e "renv::restore(prompt = FALSE)"
Rscript -e "lints <- lintr::lint_package(); print(lints); if (length(lints) > 0) quit(status = 1)"
Rscript -e "devtools::test()"
R CMD build --no-build-vignettes .
R CMD check --no-manual OpenPVA_*.tar.gz
```

Heavy profile equivalent:

```bash
Rscript -e "renv::restore(prompt = FALSE)"
Rscript -e "devtools::test(filter = 'rng_seed|output_schema_contract|scenario_yaml_demography|spatial_patches|reproducibility_snapshots')"
Rscript -e "devtools::test()"
Rscript -e "targets::tar_invalidate(names = c('sim_basic')); targets::tar_make(script = '_targets.R', store = '_targets', names = c('sim_basic'))"
quarto render quarto
R CMD build --no-build-vignettes .
R CMD check --no-manual --as-cran OpenPVA_*.tar.gz
```
