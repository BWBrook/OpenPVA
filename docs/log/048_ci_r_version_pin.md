# 048 CI R version pin

## Context

- The scheduled `ci-heavy-validation` run `25309370824` failed during
  `Restore dependencies`, before tests or package checks executed.
- The failing runner installed R `4.6.0` via the default `setup-r` release
  selection.
- `renv.lock` records R `4.5.3`, and locked package versions such as `rlang`,
  `S7`, and `data.table` failed to compile or load under R `4.6.0`.

## Change

- Pinned `r-lib/actions/setup-r@v2` to `r-version: "4.5.3"` in:
  - `.github/workflows/ci-fast.yaml`
  - `.github/workflows/ci-heavy-validation.yaml`
- Updated `docs/reference/ci_profiles.md` to document the CI/lockfile R-version
  contract.

## Rationale

- CI should validate the repository's locked environment, not silently migrate
  to a new R release line on scheduled runs.
- Upgrading OpenPVA to R `4.6.x` remains a deliberate future maintenance task:
  refresh the lockfile, validate locally, then unpin or repin CI to the new
  baseline.
