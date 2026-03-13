# Current Public API

This page lists the exported interfaces currently treated as the active
development surface for OpenPVA.

OpenPVA is still a private, pre-release codebase. Cleanups and internal-facing
API breaks are allowed when they improve clarity, provided the repo docs, tests,
and examples move in lockstep.

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

### Demography rate builders and validators

- `validate_survival_table()`
- `build_survival_fun_from_table()`
- `make_default_survival_table()`
- `default_breeding_prob_fun()`
- `validate_breeding_prob_table()`
- `build_breeding_prob_fun_from_table()`
- `make_default_breeding_prob_table()`
- `default_fecundity_lambda_fun()`
- `validate_fecundity_lambda_table()`
- `build_fecundity_lambda_fun_from_table()`
- `make_default_fecundity_lambda_table()`

### Summary/comparison interfaces

- `summarise_extinction()`
- `summarise_harvest_yield()`
- `summarise_final_abundance()`
- `compute_mean_trajectory()`
- `plot_mean_trajectory()`
- `compare_scenarios()`

## Experimental or fast-moving API

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
- Uncertainty/ensemble interfaces:
  - `sample_uncertainty_parameters()`
  - `run_scenario_ensemble()`
  - `summarise_ensemble_outputs()`
  - `summarise_sensitivity_prcc()`
  - `summarise_sensitivity_oat()`
  - `score_hindcast_fit()`
  - `generate_calibration_candidates()`
  - `run_calibration_search()`

## Removed legacy compatibility layer

These interfaces have been intentionally removed from the supported surface in
the current development line:

- `validate_breeding_table()`
- `build_breeding_fun_from_table()`
- `make_default_breeding_table()`
- `validate_fecundity_table()`
- `build_fecundity_fun_from_table()`
- `as_breeding_fun()`
- `as_breeding_prob_fun()`
- `as_fecundity_fun()`
- `as_fecundity_lambda_fun()`

## Internal API rule

Unexported functions (including names prefixed with `.`) are internal and not
covered by any public-API promise.
