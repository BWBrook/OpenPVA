# CI profiles (post-1.0 hardening)

OpenPVA uses two CI validation profiles so pull requests get fast feedback while
heavier reproducibility checks still run continuously.

## `ci-fast` (PR + push gate)

Workflow file: `.github/workflows/ci-fast.yaml`

Triggers:

- `pull_request`
- `push` to `main`

Checks:

- Ubuntu system requirements install (`apt`) for R package runtime/link deps,
- dependency restore (`renv::restore()`),
- shared `DESCRIPTION` `Suggests` bootstrap (`scripts/install_suggests.R`),
- lint (`lintr::lint_package()`),
- tests (`Rscript scripts/run_tests.R`),
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

- Ubuntu system requirements install (`apt`) for R package runtime/link deps,
- dependency restore (`renv::restore()`),
- shared `DESCRIPTION` `Suggests` bootstrap (`scripts/install_suggests.R`),
- reproducibility regression tests:
  - `test_rng_seed.R`
  - `test_output_schema_contract.R`
  - `test_scenario_yaml_demography.R`
  - `test_spatial_patches.R`
  - `test_reproducibility_snapshots.R`
- full package tests,
- bounded uncertainty workflow smoke:
  - ensemble serial/parallel reproducibility check,
  - PRCC sensitivity helper smoke,
  - calibration scaffold smoke,
- `targets` smoke run (forced `sim_basic`),
- Quarto render,
- tarball build + `R CMD check --no-manual --as-cran`.

Purpose:

- continuously verify deterministic behavior and schema contracts,
- detect drift in heavier pipeline/doc rendering paths.

## Local reproduction commands

Fast profile equivalent:

```bash
sudo apt-get update
sudo apt-get install -y libcurl4-openssl-dev libfontconfig1-dev libfreetype6-dev libgit2-dev libglpk-dev libx11-dev pandoc
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript -e "options(renv.config.pak.enabled = FALSE); renv::restore(prompt = FALSE)"
Rscript scripts/install_suggests.R
Rscript -e "lints <- lintr::lint_package(); print(lints); if (length(lints) > 0) quit(status = 1)"
Rscript scripts/run_tests.R
R CMD build --no-build-vignettes .
R CMD check --no-manual OpenPVA_*.tar.gz
```

Heavy profile equivalent:

```bash
sudo apt-get update
sudo apt-get install -y libcurl4-openssl-dev libfontconfig1-dev libfreetype6-dev libgit2-dev libglpk-dev libx11-dev pandoc
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript -e "options(renv.config.pak.enabled = FALSE); renv::restore(prompt = FALSE)"
Rscript scripts/install_suggests.R
Rscript scripts/run_tests.R "rng_seed|output_schema_contract|scenario_yaml_demography|spatial_patches|reproducibility_snapshots"
Rscript scripts/run_tests.R
Rscript - <<'EOF'
pkgload::load_all(quiet = TRUE)
sc <- scenario_spec(
  name = "ci_uncertainty_smoke",
  n_runs = 4,
  n_years = 6,
  init_fun = function() initialize_population(24),
  seed = 20260408L
)
spec <- list(
  harvest_quota = list(dist = "uniform", min = 0, max = 4, integer = TRUE),
  cat_surv_prob = list(dist = "uniform", min = 0, max = 0.2)
)
ens_serial <- run_scenario_ensemble(sc, spec, n_draws = 6, seed = 20260408L, parallel = FALSE)
ens_parallel <- run_scenario_ensemble(sc, spec, n_draws = 6, seed = 20260408L, parallel = TRUE, n_cores = 2L)
stopifnot(identical(ens_serial$sampled_parameters, ens_parallel$sampled_parameters))
prcc <- summarise_sensitivity_prcc(ens_serial)
obs <- c(
  p_extinction = summarise_extinction(run_scenario(sc)$sim_output, threshold = 0)$p_extinct,
  mean_final_n_alive = summarise_final_abundance(run_scenario(sc)$sim_output)$overall$mean_final_n_alive
)
cand <- generate_calibration_candidates(
  list(
    harvest_quota = list(lower = 1, upper = 3, integer = TRUE, n_grid = 3),
    cat_surv_prob = list(lower = 0.05, upper = 0.15, n_grid = 3)
  ),
  method = "grid"
)
cal <- run_calibration_search(sc, dplyr::slice(cand, 1:4), observed_targets = obs, seed = 20260408L)
stopifnot(nrow(prcc) > 0, nrow(cal$scores) > 0)
EOF
Rscript -e "targets::tar_make(script = '_targets.R', store = '_targets', names = c('sim_basic'))"
quarto render quarto
R CMD build --no-build-vignettes .
R CMD check --no-manual --as-cran OpenPVA_*.tar.gz
```
