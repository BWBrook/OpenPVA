# Log 045 — CI `renv` installer hardening (gh-fix-ci follow-up)

## Date
- 2026-04-08

## Trigger
- GitHub Actions `ci-fast` run on commit `2b33e50`:
  - `https://github.com/BWBrook/OpenPVA/actions/runs/24113745139`

## Failure summary
- The earlier `devtools` bootstrap fix got the workflow past test discovery,
  but the next `ci-fast` run failed during `Restore dependencies`.
- Key snippets:
  - `unable to access index for repository https://cloud.r-project.org/src/contrib`
  - `package 'renv' is not available for this version of R`
  - `there is no package called 'renv'`

## Root-cause analysis
- The workflow installed `renv` from a hard-coded CRAN URL and did not verify
  that the package was actually loadable afterward.
- On this runner, `install.packages()` emitted warnings when the CRAN index was
  temporarily unreachable, but the step itself still reported success.
- The subsequent `renv::restore()` step then failed with a misleading missing-
  package error.

## Implemented fix
- Added shared helper script:
  - `scripts/install_renv.R`
- The helper:
  - prefers `RSPM` when present,
  - falls back to `https://cloud.r-project.org`,
  - asserts that `renv` is loadable after installation.
- Updated callers to use the shared helper:
  - `bootstrap_env.R`
  - `.github/workflows/ci-fast.yaml`
  - `.github/workflows/ci-heavy-validation.yaml`

## Verification done
- Confirmed the new failure mode directly from GitHub Actions logs.
- Verified the helper script succeeds locally when `renv` is already present.
- Re-published the workflow patch so the next Actions run uses the hardened
  install path.

## Follow-up
1. Confirm `ci-fast` now gets past `Restore dependencies`.
2. If network flakiness persists, consider retry logic or moving all bootstrap
   packages to a more controlled mirror/cache strategy.
