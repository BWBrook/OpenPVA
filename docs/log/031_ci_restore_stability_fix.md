# Log 031 — CI restore stability fix (gh-fix-ci)

## Date
- 2026-02-09

## Trigger
- GitHub Actions `ci-fast` failure on `main` push run:
  - `https://github.com/BWBrook/OpenPVA/actions/runs/21812901326`

## Failure summary
- Failing step: `Restore dependencies`.
- Error class: `renv::restore()` dependency solver failure in `pak` subprocess.
- Key snippet (from run log):
  - `Error: ! error in pak subprocess`
  - `Could not solve package dependencies`

## Root-cause analysis
- During `Install renv`, project autoloader side effects were triggered in CI,
  causing unexpected renv/pak activity prior to explicit restore.
- This made restore behavior non-deterministic and susceptible to solver
  conflicts in Actions.

## Implemented fix
- Updated both workflow files:
  - `.github/workflows/ci-fast.yaml`
  - `.github/workflows/ci-heavy-validation.yaml`
- Changes:
  - Add `RENV_CONFIG_AUTOLOADER_ENABLED: "FALSE"` at job env level.
  - Make restore command explicitly non-`pak`:
    - `options(renv.config.pak.enabled = FALSE); renv::restore(prompt = FALSE)`
- Updated local CI profile reference docs:
  - `docs/reference/ci_profiles.md`

## Verification done
- Confirmed failing run diagnostics and failing step via `gh run view` logs.
- Validated workflow YAML parsing locally (`python` + `yaml.safe_load`).
- Reproduced and validated that with autoloader disabled, `Install renv`
  behaves cleanly (no project autoload bootstrap side effects).

## Follow-up
1. Push workflow fix and monitor next `ci-fast` run on `main`.
2. If green, close as resolved; if not, capture next failing snippet and iterate.
