# Log 033 — CI lint bootstrap fix (gh-fix-ci follow-up)

## Date
- 2026-02-09

## Trigger
- GitHub Actions `ci-fast` run on fix commit `4bfc8c1`:
  - `https://github.com/BWBrook/OpenPVA/actions/runs/21813336444`

## Failure summary
- Prior issue (`libglpk` missing) was resolved.
- New failing step: `Lint package`.
- Error class: missing lint dependency.
- Key snippet:
  - `there is no package called 'lintr'`

## Root-cause analysis
- `renv::restore()` succeeded, but current `renv.lock` package set does not
  ensure `lintr` is present in CI runtime library.
- `ci-fast` assumes `lintr` availability for gatekeeping without an explicit
  bootstrap step.

## Implemented fix
- Updated `.github/workflows/ci-fast.yaml`:
  - Added `Ensure lint dependency` step after restore:
    - conditionally installs `lintr` from CRAN if missing.
- Updated `docs/reference/ci_profiles.md` local reproduction docs to include
  conditional `lintr` install.
- Recorded policy in `docs/decisions.md` as `DEC-022`.

## Verification done
- Confirmed failure details via `gh run watch` and annotations for run
  `21813336444`.
- Workflow YAML syntax validated locally after edits.
- Pushed follow-up fix and began monitoring subsequent `ci-fast` run.

## Follow-up
1. Monitor the new run to completion and verify lint/test/check stages.
2. If additional CI tool packages are missing, add explicit bootstrap steps
   with the same conditional pattern.
