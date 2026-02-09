# Public API stability contract (1.0 line)

This page defines which exported interfaces are stable under the 1.x semver
contract and which remain experimental.

## Stable public API (1.x)

Changes to these interfaces are treated as breaking unless backward compatible.

### Core simulation and scenario interfaces

- `run_basic_simulation()`
- `run_basic_simulation_replicates()`
- `scenario_spec()`
- `run_scenario()`
- `read_scenario_yaml()`

### Density interfaces

- `density_spec()`
- `validate_density_spec()`
- `make_ceiling_density_fun()`

### Population/lifecycle interfaces

- `create_individual()`
- `initialize_population()`
- `age_individuals()`
- `apply_survival()`
- `determine_breeding()`
- `apply_reproduction()`
- `make_mate_limited_mating_fun()`
- `apply_harvest_quota()`
- `apply_supplementation()`
- `apply_dispersal()`
- `default_lifecycle_steps()`

### Demography table builders and validators

- `validate_survival_table()`
- `build_survival_fun_from_table()`
- `make_default_survival_table()`
- `validate_breeding_prob_table()`
- `build_breeding_prob_fun_from_table()`
- `make_default_breeding_prob_table()`
- `validate_fecundity_lambda_table()`
- `build_fecundity_lambda_fun_from_table()`
- `make_default_fecundity_lambda_table()`
- Compatibility wrappers retained for 1.x (soft-deprecated for 2.0):
  - `validate_breeding_table()`
  - `build_breeding_fun_from_table()`
  - `make_default_breeding_table()`
  - `validate_fecundity_table()`
  - `build_fecundity_fun_from_table()`
  - `as_breeding_fun()`
  - `as_breeding_prob_fun()`
  - `as_fecundity_fun()`
  - `as_fecundity_lambda_fun()`

### Summary/comparison interfaces

- `summarise_extinction()`
- `summarise_harvest_yield()`
- `summarise_final_abundance()`
- `compute_mean_trajectory()`
- `plot_mean_trajectory()`
- `compare_scenarios()`

## Experimental exported API (may change within 1.x)

These remain exported for active development and may evolve with explicit
release notes.

- Genetics-facing interfaces:
  - `initialize_genotypes()`
  - `inherit_genotype_simple()`
  - `make_inbreeding_survival_fun()`
  - `summarise_genetic_diversity()`
- Spatial convenience interfaces:
  - `make_markov_dispersal_fun()`
  - `dispersal_low_connectivity_fun()`
  - `dispersal_high_connectivity_fun()`
  - `dispersal_asymmetric_flow_fun()`
  - `make_two_patch_spatial_scenario()`
  - `initialize_spatial_population()`
  - `initialize_spatial_genetic_population()`
  - `summarise_patch_occupancy_final()`
  - `summarise_patch_genetic_diversity_final()`
  - `summarise_patch_occupancy_timeseries()`
  - `summarise_patch_genetic_diversity_timeseries()`
  - `summarise_patch_connectivity_timeseries()`
  - `initialize_patches()`
  - `default_dispersal_fun()`

## Internal API rule

Unexported functions (including names prefixed with `.`) are internal and not
covered by semver stability promises.

## Migration note

For currently soft-deprecated wrappers and preferred replacements, see
`docs/reference/migration_1x_to_2x.md`.
