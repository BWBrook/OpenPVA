# Removed Legacy Interfaces

OpenPVA now treats the explicit rate-based API as the only supported path.

Removed interfaces:

- `validate_breeding_table()`
- `make_default_breeding_table()`
- `build_breeding_fun_from_table()`
- `validate_fecundity_table()`
- `build_fecundity_fun_from_table()`
- `as_breeding_fun()`
- `as_breeding_prob_fun()`
- `as_fecundity_fun()`
- `as_fecundity_lambda_fun()`

Use these retained interfaces instead:

- `validate_breeding_prob_table()`
- `make_default_breeding_prob_table()`
- `build_breeding_prob_fun_from_table()`
- `validate_fecundity_lambda_table()`
- `make_default_fecundity_lambda_table()`
- `build_fecundity_lambda_fun_from_table()`

For YAML scenarios, use `schema_version: 3` with:

- `demography.breeding_prob.table`
- `demography.fecundity_lambda.table`
- `reproduction_ev`
- `density`
- `management`
