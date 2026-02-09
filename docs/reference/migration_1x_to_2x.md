# Migration Guide (1.x to 2.0)

This page tracks soft deprecations introduced in the 1.x line and the
preferred migration targets for OpenPVA 2.0.

## Deprecation lifecycle states

- `active`: fully supported, no migration needed.
- `soft-deprecated`: still supported in 1.x; warning may be emitted with
  migration guidance.
- `hard-deprecated`: reserved for future use; not currently used in 1.x.
- `removed`: interface no longer available (target state for selected legacy
  wrappers in 2.0).

## Current soft-deprecated interfaces (1.x)

Legacy reproduction table wrappers are soft-deprecated for 2.0 and remain
runtime-compatible in 1.x:

- `validate_breeding_table()` -> use `validate_breeding_prob_table()`
- `make_default_breeding_table()` -> use `make_default_breeding_prob_table()`
- `build_breeding_fun_from_table()` -> use
  `build_breeding_prob_fun_from_table()`
- `validate_fecundity_table()` -> use `validate_fecundity_lambda_table()`
- `build_fecundity_fun_from_table()` -> use
  `build_fecundity_lambda_fun_from_table()`

## Warning behavior

- Soft-deprecation warnings are emitted at most once per session per function.
- Warnings can be suppressed when needed (for CI/tests or controlled
  compatibility workflows) with:

```r
options(openpva.deprecation_warnings = FALSE)
```

## Migration defaults

- Prefer baseline-rate channels:
  - breeding probability (`p_breed`)
  - fecundity mean (`lambda`)
- Keep adapters only at explicit compatibility boundaries.
- For new YAML/R scenarios, prefer v2 demography channels:
  - `demography.breeding_prob.table`
  - `demography.fecundity_lambda.table`

## Notes

- No runtime removals are planned within 1.x.
- Any 2.0 removals must be announced in `NEWS.md` with migration examples.
