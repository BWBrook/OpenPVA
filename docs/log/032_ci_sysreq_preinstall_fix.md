# Log 032 — CI system requirements preinstall fix (gh-fix-ci)

## Date
- 2026-02-09

## Trigger
- Follow-up GitHub Actions `ci-fast` failure on `main` push run:
  - `https://github.com/BWBrook/OpenPVA/actions/runs/21813246123`

## Failure summary
- Failing step: `Restore dependencies`.
- Error class: package load failure during `renv::restore()` validation.
- Key snippet (from run log):
  - `unable to load shared object ... igraph.so`
  - `libglpk.so.40: cannot open shared object file: No such file or directory`

## Root-cause analysis
- The workflow runtime did not include required Ubuntu system libraries needed
  by restored R packages.
- `renv` surfaced missing apt packages, and `igraph` load validation failed
  because `libglpk` runtime was unavailable.

## Implemented fix
- Updated both workflow files:
  - `.github/workflows/ci-fast.yaml`
  - `.github/workflows/ci-heavy-validation.yaml`
- Added explicit pre-restore system dependency install step:
  - `sudo apt-get update`
  - `sudo apt-get install -y ...` for:
    - `libcurl4-openssl-dev`
    - `libfontconfig1-dev`
    - `libfreetype6-dev`
    - `libgit2-dev`
    - `libglpk-dev`
    - `libx11-dev`
    - `pandoc`
- Updated CI profile docs:
  - `docs/reference/ci_profiles.md`
- Recorded architectural decision:
  - `DEC-021` in `docs/decisions.md`.

## Verification done
- Confirmed failure details via `gh run view --job ... --log`.
- Validated workflow YAML syntax locally after edits.
- Pushed workflow changes and monitored new `ci-fast` run start for the fix
  commit.

## Follow-up
1. Monitor the new `ci-fast` run through completion.
2. If successful, close this incident as resolved.
3. If a new system dependency is missing, add it to the shared apt install step
   and keep list synchronized with `renv` diagnostics.
