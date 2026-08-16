# Public API

OpenPVA exposes one active product: a generic process engine, reusable ordinary
processes, explicit scientific helpers, and a canonical synthetic benchmark.

## Process engine

- `pva_state()`, `pva_process()`, `pva_result()`
- `validate_processes()`, `allocate_ids()`, `execute_processes()`
- `scenario_spec()`, `run_scenario()`

A lifecycle is a direct ordered list of process objects. Community processes
compose through the same state, context, result, field and event contracts as
package processes; there is no controller dispatcher or registration layer.

## Reusable processes

- `age_process()`
- `survival_process()`
- `reproduction_process()`
- `introduction_process()`
- `density_snapshot_process()`, `patch_density_snapshot_process()`
- `dispersal_process()`, `markov_dispersal_process()`
- `census_process()`

Survival and reproduction callbacks in one execution see one common
pre-process state. Reproduction requires an explicit `offspring_sex` callback.
Introduction requires explicit count, source and newcomer state. The package
does not supply species biology, a sex ratio, an introduction quota, patch
allocation or connectivity defaults.

## Explicit scientific helpers

- `create_individual()`
- `validate_survival_table()`, `build_survival_fun_from_table()`
- `validate_breeding_prob_table()`, `build_breeding_prob_fun_from_table()`
- `validate_fecundity_lambda_table()`, `build_fecundity_lambda_fun_from_table()`
- `ceiling_density_multiplier()`, `patch_density_multiplier()`
- `initialize_patches()`

Demographic tables are modeller-supplied callback ingredients. Every lookup
must match exactly one age/sex row; missing coverage is an error, not an
implicit zero or extrapolation. Density helpers are pure rate multipliers, not
population caps or carrying-capacity estimators.

## Optional pedigree ancestry

- `initialize_pedigree()`, `validate_pedigree()`
- `pedigree_founder_fields()`, `pedigree_newborn_fields()`
- `pedigree_parentage_fields()`
- `pedigree_ledger()`, `summarise_pedigree()`

Pedigree is complete when enabled. `pedigree_F` is exact conditional pedigree
IBD under the declared founder horizon; it is not marker heterozygosity.

## Canonical benchmark

The `grizzly_benchmark_*()` builders, `run_grizzly_benchmark()` and
`summarise_grizzly_benchmark()` provide a source-labelled synthetic acceptance
fixture. Its parameters are illustrative and uncalibrated, not species defaults
or management advice. `grizzly_density_extension_scenario()` is a separate
non-canonical demonstration of explicit density feedback.

## Deferred interfaces

Harvest/removal, YAML compilation, uncertainty, sensitivity and calibration are
possible Stage 4 interfaces, not current runtime APIs. Orchestration and
reporting tools will be chosen only for an executable consumer rather than
treated as fixed requirements. Former controller-era and old-output
implementations were removed rather than preserved behind adapters.
