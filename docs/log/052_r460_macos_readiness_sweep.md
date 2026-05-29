# 052 R 4.6.0 macOS readiness sweep

## Context

- The previous Mac adoption pass used rig-managed R `4.5.3` because
  `renv.lock` was pinned there.
- Barry clarified that this is early-stage work and the R `4.5.3` pin should be
  treated as stale.
- This pass migrates OpenPVA onto Homebrew R `4.6.0` as the active local and CI
  baseline.

## Changes

- Refreshed `renv.lock` under R `4.6.0`.
- Updated the locked `renv` version from `1.1.5` to `1.2.3`.
- Updated package versions to current CRAN builds available for the R `4.6.0`
  stack, including `Matrix` `1.7-5`, `dplyr` `1.2.1`, `ggplot2` `4.0.3`,
  `targets` `1.12.0`, and `testthat` `3.3.2`.
- Updated `renv/activate.R` through `renv`.
- Updated CI R pins from `4.5.3` to `4.6.0`.
- Raised package metadata and README badge from R `4.5+` to R `4.6+`.
- Moved Quarto rendered site output from `outputs/quarto_site` to
  `quarto/_site` to avoid Quarto 1.9's warning about an output directory
  outside the Quarto project root.

## Verification

- `renv::status()` under Homebrew R `4.6.0`: no issues found.
- CI-style restore:
  - `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript scripts/install_renv.R`
  - `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript scripts/ci_restore.R`
  - `Rscript scripts/install_suggests.R`
- Static checks:
  - `lintr::lint_package()` passed with no lints.
  - `actionlint .github/workflows/*.yaml` passed.
  - `shellcheck scripts/build_release_evidence.sh` passed after replacing an
    `ls | head` tarball selection with an R-based mtime selection.
- Tests:
  - Focused reproducibility/schema suite passed (`172` pass).
  - Full suite passed (`532` pass).
- Uncertainty workflow smoke:
  - Serial and parallel sampled parameters matched.
  - PRCC output had `2` rows.
  - Calibration score output had `4` rows.
- Targets:
  - `targets::tar_destroy(store = "_targets", destroy = "all")`
    followed by full `targets::tar_make()` completed `14` targets.
- Quarto:
  - `quarto render quarto` completed without the former external output-dir
    warning.
  - Output is now `quarto/_site/index.html`.
- Package build/check:
  - `R CMD build --no-build-vignettes .` produced `OpenPVA_1.0.0.tar.gz`.
  - `R CMD check --no-manual --as-cran OpenPVA_1.0.0.tar.gz` completed with
    `0` errors, `0` warnings, and `2` notes (`New submission`, non-standard
    top-level project files).
- Release evidence:
  - `scripts/build_release_evidence.sh rc3` completed.
  - The release toy scenario now uses explicit `density_spec()` and completed
    with `p_extinct = 0`.

## Artefacts

- `artefacts/macos_r460_readiness/`
- `artefacts/release_1.0.0-rc3/`
