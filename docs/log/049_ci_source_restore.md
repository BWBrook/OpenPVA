# 049 CI source restore

## Context

- The scheduled `ci-heavy-validation` run `26027478512` failed on commit
  `7166fc8`, which had already passed `ci-heavy-validation` as run
  `25663120789`.
- The new failure occurred during `Restore dependencies`, before tests or
  package checks ran.
- R was still correctly pinned to `4.5.3`; this was not the earlier R `4.6.0`
  drift.
- The changed behaviour was package installation mode:
  - the passing run built restored packages from source;
  - the failing run installed Posit Package Manager Linux binaries and then
    reported dependency failures for packages including `dplyr`, `magrittr`,
    `tibble`, `targets`, and `testthat`.

## Change

- Removed `use-public-rspm: true` from both GitHub Actions workflows.
- Set `RENV_CONFIG_REPOS_OVERRIDE` to `https://cloud.r-project.org`.
- Set `R_PKG_TYPE` to `source`.
- Added `scripts/ci_restore.R` so restore explicitly clears ambient `RSPM`
  and disables `renv` PPM/RSPM transforms before calling `renv::restore()`.
- Updated `scripts/install_renv.R` and `scripts/install_suggests.R` so explicit
  repo overrides take precedence over runner-provided `RSPM`.
- Updated `scripts/install_renv.R` to install the exact `renv` version recorded
  in `renv.lock`, avoiding drift to a newer restore engine before lockfile
  restoration begins.

## Rationale

- OpenPVA CI should validate the lockfile under a stable R/source-package
  restore path.
- This avoids weekly drift caused by changing Linux binary availability or
  binary-install behaviour in external package repositories.
- A future intentional migration to binary restores should be done as a
  dedicated environment change with a refreshed lockfile and CI evidence.
