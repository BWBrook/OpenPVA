# Output schema contract (v0.5.4)

This page documents the expected structure of key OpenPVA outputs.

## `run_basic_simulation()`

Returns a list with:

- `population`: list of individual objects.
- `summary`: tibble with required columns:
  - `year` (integer)
  - `n_alive` (integer)
  - `n_female_alive` (integer)
  - `n_male_alive` (integer)
  - `n_births` (integer)
  - `n_harvested` (integer)
  - `n_supplemented` (integer)
  - `survival_scale` (numeric)
  - `env_surv_mult` (numeric)
  - `cat_surv_mult` (numeric)
  - `catastrophe` (logical)
  - `env_repro_p_mult` (numeric)
  - `env_repro_lambda_mult` (numeric)
  - `cat_repro_mult` (numeric)
  - `repro_catastrophe` (logical)
- Optional field when `record_population_history = TRUE`:
  - `population_history`: list of per-year population snapshots.

## `run_basic_simulation_replicates()`

Returns a list with:

- `runs`: list of per-run outputs from `run_basic_simulation()`.
- `summary`: tibble with required columns:
  - `run` (integer)
  - plus all required per-year columns listed above.
- `extinction`: tibble with required columns:
  - `run` (integer)
  - `went_extinct` (logical)
  - `time_to_extinction` (integer)
- Optional per-run field when `record_population_history = TRUE`:
  - `runs[[i]]$population_history`: list of per-year population snapshots.

## `run_scenario()`

Returns a list with:

- `scenario`: `openpva_scenario` object.
- `sim_output`: output object from `run_basic_simulation_replicates()`.

## Uncertainty ensemble interfaces

### `sample_uncertainty_parameters(uncertainty_spec, n_draws, seed = NULL)`

Returns a tibble with required columns:

- `draw_id` (integer)
- one column per named uncertainty parameter in `uncertainty_spec`.

### `run_scenario_ensemble(scenario, uncertainty_spec = NULL, n_draws, seed = NULL)`

Returns a list with required fields:

- `scenario`: input `openpva_scenario`.
- `uncertainty_spec`: normalized uncertainty specification list. When function
  input `uncertainty_spec = NULL`, this is sourced from
  `scenario$uncertainty_spec`.
- `sampled_parameters`: tibble returned by `sample_uncertainty_parameters()`.
- `draw_results`: list of length `n_draws`; each element contains:
  - `draw_id` (integer),
  - `scenario` (`openpva_scenario` with draw-specific parameters applied),
  - `sim_output` (output from `run_scenario()` for that draw).
- `seed`: normalized integer seed or `NULL`.

### `summarise_ensemble_outputs(ensemble_output, extinction_threshold = 0, final_n_floor = extinction_threshold)`

Returns a list with required fields:

- `per_draw`: tibble with required columns:
  - `draw_id`
  - `p_extinction`
  - `mean_time_to_extinction`
  - `median_time_to_extinction`
  - `mean_final_n_alive`
  - `median_final_n_alive`
  - `p_final_below_floor`
  - `p_any_below_floor`
  - plus sampled uncertainty parameter columns joined from `sampled_parameters`.
- `overall`: one-row tibble with required columns:
  - `n_draws`
  - `extinction_threshold`
  - `final_n_floor`
  - `mean_p_extinction`
  - `sd_p_extinction`
  - `mean_mean_final_n_alive`
  - `sd_mean_final_n_alive`
  - `mean_p_final_below_floor`
  - `sd_p_final_below_floor`
  - `mean_p_any_below_floor`
  - `sd_p_any_below_floor`

### `summarise_sensitivity_prcc(ensemble_data, response_col = "p_extinction", parameter_cols = NULL)`

Returns a tibble with one row per analyzed parameter and required columns:

- `parameter`
- `prcc`
- `p_value`
- `n_obs`
- `n_controls`
- `abs_prcc`

### `summarise_sensitivity_oat(scenario, oat_spec, metric_fun = NULL, metric_name = "p_extinction", seed = NULL)`

Returns a tibble with one row per OAT parameter and required columns:

- `parameter`
- `metric_name`
- `baseline_value`
- `low_value`
- `high_value`
- `baseline_metric`
- `low_metric`
- `high_metric`
- `local_slope`
- `elasticity`
- `pct_change_low`
- `pct_change_high`

## Summary helpers

### `summarise_extinction(sim_output, threshold = 0)`

Returns a tibble with required columns:

- `n_runs` (integer)
- `p_extinct` (numeric)
- `mean_time_to_extinction` (numeric)
- `median_time_to_extinction` (numeric)

### `compute_mean_trajectory(sim_output)`

Returns a tibble with required columns:

- `year` (integer)
- `mean_n_alive` (numeric)
- `sd_n_alive` (numeric)
- `p_extant` (numeric)

### `summarise_harvest_yield(sim_output)`

Returns a list with:

- `per_run`: tibble with required columns `run`, `total_harvest`, `mean_annual_harvest`.
- `overall`: tibble with required columns:
  - `mean_total_harvest`
  - `sd_total_harvest`
  - `mean_mean_annual_harvest`
  - `n_runs`

### `summarise_final_abundance(sim_output, floor = 0)`

Returns a list with:

- `per_run`: tibble with required columns:
  - `run`
  - `final_year`
  - `final_n_alive`
  - `min_n_alive`
- `overall`: one-row tibble with required columns:
  - `n_runs`
  - `floor_threshold`
  - `mean_final_n_alive`
  - `median_final_n_alive`
  - `q05_final_n_alive`
  - `q95_final_n_alive`
  - `p_final_below_floor`
  - `p_any_below_floor`

### `compare_scenarios(scenarios, extinction_threshold = 0, final_n_floor = extinction_threshold)`

Returns a tibble with one row per scenario and required columns:

- `scenario_name`
- `extinction_threshold`
- `final_n_floor`
- `p_extinction`
- `mean_time_to_extinction`
- `mean_total_harvest`
- `sd_total_harvest`
- `mean_mean_annual_harvest`
- `mean_final_n_alive`
- `median_final_n_alive`
- `q05_final_n_alive`
- `q95_final_n_alive`
- `p_final_below_floor`
- `p_any_below_floor`

### `summarise_patch_genetic_diversity_final(sim_output, n_patches)`

Returns a tibble with required columns:

- `patch_id` (integer)
- `n_runs` (integer)
- `mean_n_genotyped` (numeric)
- `p_patch_genotyped` (numeric)
- `mean_heterozygosity` (numeric)
- `mean_Fhat` (numeric)
- `alive_only` (logical)

### `summarise_patch_occupancy_timeseries(sim_output, n_patches)`

Returns a list with:

- `per_run`: tibble with required columns:
  - `run`
  - `year`
  - `patch_id`
  - `n_alive`
  - `occupied`
  - `alive_only`
- `overall`: tibble with required columns:
  - `year`
  - `patch_id`
  - `n_runs`
  - `mean_n_alive`
  - `p_occupied`
  - `n_extinct`
  - `alive_only`

### `summarise_patch_genetic_diversity_timeseries(sim_output, n_patches)`

Returns a list with:

- `per_run`: tibble with required columns:
  - `run`
  - `year`
  - `patch_id`
  - `n_genotyped`
  - `mean_heterozygosity`
  - `mean_Fhat`
  - `alive_only`
- `overall`: tibble with required columns:
  - `year`
  - `patch_id`
  - `n_runs`
  - `mean_n_genotyped`
  - `p_patch_genotyped`
  - `mean_heterozygosity`
  - `mean_Fhat`
  - `alive_only`

### `summarise_patch_connectivity_timeseries(sim_output, n_patches)`

Returns a list with:

- `transitions`: tibble with required columns:
  - `run`
  - `year_from`
  - `year_to`
  - `origin_patch`
  - `destination_patch`
  - `n_individuals`
  - `alive_only`
- `transitions_overall`: tibble with required columns:
  - `origin_patch`
  - `destination_patch`
  - `mean_n_individuals`
  - `total_n_individuals`
  - `p_transition_given_origin`
  - `alive_only`
- `net_patch_change`: tibble with required columns:
  - `run`
  - `year`
  - `patch_id`
  - `n_alive`
  - `alive_only`
  - `delta_n_alive`
- `turnover`: tibble with required columns:
  - `run`
  - `year`
  - `patch_id`
  - `colonized`
  - `extirpated`
  - `alive_only`

## Compatibility note

Fields listed above are treated as required contract fields for regression testing.
Additional fields may be added in future versions if additive and documented.

## Determinism note

- `run_basic_simulation_replicates(seed = <integer>)` provides deterministic
  stochastic realizations in a fixed software/RNG environment.
- `run_scenario()` inherits deterministic behavior when `scenario$seed` is set
  (including YAML `seed`).
- Seeding affects demographic stochasticity and year-level EV/cat draws, but
  does not alter schema shape.
- Reproduction EV/cat multipliers are exposed in summary outputs through
  `env_repro_p_mult`, `env_repro_lambda_mult`, `cat_repro_mult`, and
  `repro_catastrophe`.

## Regression gate note

- CI heavy validation includes seeded snapshot-style regression checks over
  representative summary/extinction slices to detect unintended behavioral
  drift while preserving deterministic reproducibility expectations.
