# WP-0.3.4 artefact bundle

This bundle captures CI baseline implementation evidence for `WP-0.3.4`.

## CI assets added

- `.github/workflows/ci.yaml`
- `.lintr`

## CI behaviour

Workflow (`ubuntu-latest`) runs:
1. `renv::restore(prompt = FALSE)` (with `RENV_CONFIG_PAK_ENABLED=FALSE`)
2. `lintr::lint_package()` and explicit fail on non-zero lint count
3. `R CMD build --no-build-vignettes .`
4. `R CMD check --no-manual --as-cran OpenPVA_*.tar.gz`

## Local CI-equivalent validation

Executed locally with logs captured in this folder:
- Restore dependencies (`restore.log`) -> pass
- Lint gate (`lint.log`) -> pass (`No lints found.`)
- Build (`build.log`) -> pass
- R CMD check (`rcmdcheck.log`) -> pass with `0` errors, `0` warnings, `3` notes

## Notes

- The workflow file is present and locally validated; remote GitHub Actions run status will appear after push/PR execution.
