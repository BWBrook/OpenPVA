# Log 036 — CI heavy `targets` smoke invalidate fix

## Date
- 2026-02-09

## Trigger
- Manual `ci-heavy-validation` run:
  - `https://github.com/BWBrook/OpenPVA/actions/runs/21814066813`

## Failure summary
- Failing step: `targets heavy smoke`.
- Key snippet:
  - `No local metadata. Did you remember to run tar_meta_download()?`
  - `Error: ! names must be a character.`

## Root-cause analysis
- The heavy smoke command ran:
  - `targets::tar_invalidate(names = c('sim_basic')); targets::tar_make(...)`
- On fresh CI stores with no local target metadata yet, `tar_invalidate()`
  failed before `tar_make()` could run.
- This is an ordering/initial-state issue, not a model pipeline failure.

## Implemented fix
- Updated `.github/workflows/ci-heavy-validation.yaml`:
  - removed pre-invalidate call from `targets heavy smoke`.
  - now runs:
    - `targets::tar_make(script = '_targets.R', store = '_targets', names = c('sim_basic'))`
- Updated local reproduction docs in `docs/reference/ci_profiles.md`.
- Recorded policy in `docs/decisions.md` as `DEC-024`.

## Verification done
- Reproduced failure locally on a fresh temporary targets store.
- Verified direct `tar_make(... names = c('sim_basic'))` succeeds in a clean
  store.
- Re-ran heavy workflow after patch and verified full success:
  - `https://github.com/BWBrook/OpenPVA/actions/runs/21814222587`
  - `targets heavy smoke`, `Quarto render`, and heavy `R CMD check` all passed.

## Follow-up
1. Keep heavy smoke focused on execution of a bounded target subset.
2. Revisit invalidate semantics only if a persistent stale-cache issue is
   demonstrated in scheduled runs.
