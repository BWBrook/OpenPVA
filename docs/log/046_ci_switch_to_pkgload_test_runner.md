# Log 046 — CI switch from `devtools` to pkgload/testthat runner

## Date
- 2026-04-08

## Trigger
- GitHub Actions failures after CI bootstrap hardening:
  - `ci-fast` run `24113909188`
  - `ci-heavy-validation` run `24113776573`

## Failure summary
- Both workflows reached test execution but still failed because `devtools`
  was unavailable.
- Key snippets:
  - `there is no package called 'devtools'`
  - `installation of package 'pkgdown' had non-zero exit status`
  - `installation of package 'devtools' had non-zero exit status`

## Root-cause analysis
- CI no longer failed on `renv`, but it still relied on `devtools::test()` and
  `devtools::load_all()` for test orchestration.
- Installing `devtools` on GitHub runners is heavier than necessary for this
  repo and pulls in extra dependencies (e.g. `pkgdown`) that are not required
  for the package test path itself.
- The repository already had a lighter runner in `scripts/run_tests.R` based on
  `pkgload` + `testthat`, which is better aligned with CI needs.

## Implemented fix
- Removed `devtools` from `DESCRIPTION` `Suggests`.
- Updated `scripts/install_suggests.R` to use `RSPM` when available.
- Expanded `scripts/run_tests.R` to accept an optional test filter.
- Switched workflows away from `devtools`:
  - `.github/workflows/ci-fast.yaml`
  - `.github/workflows/ci-heavy-validation.yaml`
- Replaced `devtools::load_all()` with `pkgload::load_all()` in the heavy smoke
  test and active developer docs.

## Verification done
- Reproduced the GitHub failure mode from Actions logs.
- Verified local test execution through `scripts/run_tests.R`.
- Verified the filtered reproducibility test slice through the same runner.

## Follow-up
1. Confirm the next `ci-fast` run gets through full tests and into build/check.
2. Re-run `ci-heavy-validation` on the latest `main` head after the workflow
   update so the old `devtools`-based failure is superseded.
