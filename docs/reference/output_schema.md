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

## `run_scenario()`

Returns a list with:

- `scenario`: `openpva_scenario` object.
- `sim_output`: output object from `run_basic_simulation_replicates()`.

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
