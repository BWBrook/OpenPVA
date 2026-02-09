# Log 034 — CI `Suggests` bootstrap hardening (gh-fix-ci follow-up)

## Date
- 2026-02-09

## Trigger
- GitHub Actions `ci-fast` run on commit `81d9112`:
  - `https://github.com/BWBrook/OpenPVA/actions/runs/21813421492`

## Failure summary
- Prior failures (`libglpk` and missing `lintr`) were resolved.
- New failing step: `Run R CMD check (fast profile)`.
- Error class: missing suggested package at check time.
- Key snippet:
  - `Package suggested but not available: 'quarto'`

## Root-cause analysis
- `renv::restore()` succeeded, but lockfile contents did not guarantee
  full `DESCRIPTION` `Suggests` coverage for CI check phases.
- Previous targeted bootstrap (`lintr`) fixed lint only, leaving check-time
  `Suggests` gaps possible for other packages.

## Implemented fix
- Updated `.github/workflows/ci-fast.yaml`:
  - Replaced lint-only bootstrap with generalized `Ensure suggested packages`
    step that parses `DESCRIPTION` `Suggests` and installs missing packages.
- Updated `.github/workflows/ci-heavy-validation.yaml`:
  - Added same generalized `Ensure suggested packages` step for consistency.
- Updated docs:
  - `docs/reference/ci_profiles.md` local commands and check lists.
  - `docs/decisions.md`:
    - marked `DEC-022` superseded,
    - added `DEC-023` for generalized policy.

## Verification done
- Confirmed `quarto` package availability on CRAN from CI-equivalent environment.
- Validated workflow YAML syntax locally after edits.
- Pushed follow-up patch and started monitoring subsequent `ci-fast` run.

## Follow-up
1. Confirm next `ci-fast` run reaches green across lint/tests/check.
2. If a package becomes unavailable upstream, evaluate pinning/mirroring strategy
   or selective `_R_CHECK_FORCE_SUGGESTS_` policy for fast lane only.
