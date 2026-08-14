# Demographic table helpers

OpenPVA retains small compilers for modeller-supplied age- and sex-specific
tables. They are ingredients for process callbacks, not packaged biological
models.

## Survival

- `validate_survival_table(tbl)`
- `build_survival_fun_from_table(tbl)`

Required columns are `age_min`, `age_max`, `sex`, and `p_surv`.
Probabilities must lie in `[0, 1]`, ages must be non-negative, and intervals
must not overlap within sex.

## Reproduction

- `validate_breeding_prob_table(tbl)`
- `build_breeding_prob_fun_from_table(tbl)`
- `validate_fecundity_lambda_table(tbl)`
- `build_fecundity_lambda_fun_from_table(tbl)`

Breeding tables use `p_breed` in `[0, 1]`; fecundity tables use non-negative
finite `lambda`. Both use the same age/sex interval rules.

## Lookup contract

Each builder returns `function(individual)`. The individual must supply one
non-missing character `sex` and one finite non-negative numeric `age`, and the
table must contain exactly one matching row. Missing sex or age coverage fails
clearly. The package does not silently return zero, extrapolate a terminal age
class, or provide default tables.

The modeller may call these lookups inside the corresponding callback of
`survival_process()` or `reproduction_process()`. The process remains
responsible for stochastic draws, state transitions and event accounting.
