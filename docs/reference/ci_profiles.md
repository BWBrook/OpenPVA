# CI profiles

Both workflows use Ubuntu and R 4.6.1 and restore the exact runtime and
development closure from the committed lockfile.

## `ci-fast`

File: `.github/workflows/ci-fast.yaml`

Triggers on pull requests and pushes to `main`. It installs system
requirements, restores dependencies, runs `scripts/run_lint.R`, builds the
source tarball and runs ordinary `R CMD check --no-manual`. The package check
executes the installed test suite; CI does not run it a second time through the
local helper.

## `ci-heavy-validation`

File: `.github/workflows/ci-heavy-validation.yaml`

Runs weekly and by manual dispatch. It installs the same system requirements,
restores dependencies, builds the source tarball and runs
`R CMD check --no-manual --as-cran`, including the installed package tests.

The heavy profile is a stricter package check, not a hidden second simulation
pipeline. Neither workflow currently executes targets, YAML scenarios, Quarto,
uncertainty, sensitivity or calibration code.

## Local equivalents

After restoring dependencies:

```sh
Rscript scripts/run_lint.R
Rscript scripts/run_tests.R
R CMD build --no-build-vignettes .
R CMD check --no-manual OpenPVA_*.tar.gz
```

For the heavy check, add `--as-cran`. Use the workflow files themselves as the
authority for triggers, R version and Linux system packages.
