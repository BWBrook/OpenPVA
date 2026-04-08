# Log 044 — CI devtools bootstrap fix (gh-fix-ci follow-up)

## Date
- 2026-04-08

## Trigger
- GitHub Actions failures on `main`:
  - `ci-fast` run `23127392872`
  - `ci-heavy-validation` run `24023911259`

## Failure summary
- Both workflows failed before package code was exercised.
- Failing steps:
  - `Run tests` in `ci-fast`
  - `Reproducibility regression tests` in `ci-heavy-validation`
- Key snippet:
  - `there is no package called 'devtools'`

## Root-cause analysis
- Both workflows restored `renv` and then installed missing `DESCRIPTION`
  `Suggests`, but `devtools` was being used as CI/bootstrap tooling without
  being declared in `Suggests`.
- Local developer environments could mask this because `devtools` was already
  present in the project library, while fresh GitHub runners exposed the gap.
- The same bootstrap gap also existed in `bootstrap_env.R`, which restored
  `renv` but did not install the repo's missing `Suggests`.

## Implemented fix
- Added `devtools` to `DESCRIPTION` `Suggests`.
- Added shared helper script:
  - `scripts/install_suggests.R`
- Updated bootstrap and CI to use the shared helper:
  - `bootstrap_env.R`
  - `.github/workflows/ci-fast.yaml`
  - `.github/workflows/ci-heavy-validation.yaml`
- Updated docs to reflect the shared command path:
  - `README.md`
  - `docs/reference/ci_profiles.md`

## Verification done
- Reproduced the GitHub failure mode from Actions logs.
- Verified local bootstrap/CI command paths now install missing `Suggests`
  through the shared helper.
- Re-ran local checks after the fix to confirm the repo remains green.

## Follow-up
1. Push and monitor the next `ci-fast`/`ci-heavy-validation` runs.
2. If additional fresh-run dependency gaps appear, keep fixing them through the
   shared `scripts/install_suggests.R` path rather than inline workflow code.
