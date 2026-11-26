# Public API (OpenPVA 2.0.0)

The help pages under `man/` are the reference; this page is the map. Every
entry is exported.

| Area | Functions |
|---|---|
| State | `pva_population()`, `pva_state()`, `add_individuals()` |
| Process contract | `pva_process()`, `pva_result()`, `pva_events()`, `validate_processes()`, `execute_processes()` |
| Demography | `age_process()`, `survival_process()`, `staged_survival_process()`, `reproduction_process()`, `census_process()` |
| Reproduction helpers | `litter_poisson()`, `litter_binomial()`, `litter_categorical()`, `offspring_sex_bernoulli()`, `mate_random()`, `mate_from_field()` |
| Management and limits | `removal_process()`, `ceiling_process()`, `introduction_process()`, `pairing_process()` |
| Environment | `environment_process()`, `catastrophe_process()`, `beta_shapes()`, `shift_logit()` |
| Density feedback | `ceiling_density_multiplier()`, `beverton_holt_multiplier()`, `ricker_multiplier()` |
| Inbreeding | `summarise_pedigree()`, `kinship_matrix()`, `inbreeding_multiplier()`, `inbreeding_proxy_process()`, `sex_ratio_effective_size()` |
| Rates | `validate_age_sex_table()`, `age_sex_rate()` |
| Space | `patch_counts()`, `dispersal_process()`, `markov_dispersal_process()` |
| Scenarios | `scenario_spec()`, `run_scenario()` |
| Summaries and ensembles | `summarise_pva()`, `summarise_trajectory()`, `summarise_accounting()`, `run_pva_ensemble()` |

## Outputs of `run_scenario()`

A `pva_run` is a list with:

- `census`: one row per run, census process and time, with `run`, `time`,
  `phase` (`initial` or `interval`), `process_name`, `occurrence` and one numeric column per
  metric;
- `events`: `run`, `time`, `phase`, `process_index`, `process_name`,
  `occurrence`, `event_type`, `value`, `label`, `origin_patch_id` and `destination_patch_id`;
- `accounting`: one row per run, interval and process, with `n_before`,
  `births`, `introductions`, `deaths_*` and `removals_*` by cohort, `n_after`;
- `states`: the final `pva_state` of each run;
- `ledgers`: for each run, every individual that ever lived, with `exit_time`,
  `exit_process` and `exit_type` (`NA` for survivors);
- `provenance`: root seed, generator kinds, the replicate streams, validation
  mode, the process plan and package and R versions.

The default retains census, events and accounting. Include `"state"` for final states and `"ledger"` for full histories. Provenance is always available. Whole-run risk summaries validate the selected census against every scheduled run and interval. Specify `process_name` if several censuses run per interval, and `occurrence` if a name repeats. Both summaries include a scheduled year-zero census by default.

## Event vocabulary

`death`, `removal`, `birth` and `introduction` are accounting events: their
values must equal the state change. Built-in processes also emit
`breeding_females`, `removal_shortfall`, `death_shortfall` (from a ceiling,
always zero), `pairs_formed`, `unpaired_eligible`, `catastrophe` and
`dispersal`. The latter counts movers. Each `patch_transition` row records an origin, destination and count, including stays among eligible individuals. Other event rows have missing patch IDs.

## Composing a species model

Use `mate_random()` for fresh two-sex mating or `mate_from_field()` for a recorded sire. Mating can precede a mortality process in the same interval. Use `mate_from_field(stale = "unpaired")` to treat a sire lost in a previous interval as absent for breeding. With `mate = NULL`, fecundity is female-dominant. A one-sex rate table requires `missing_sex = "zero"` to assign zero when the omitted sex is present. Environment variables evaluate in their listed order, so a shared weather draw can affect several rates.

Use `pva_state(pedigree = TRUE)` when known parentage or supplementation matters. Inspect `pedigree_F` for individual fitness costs and `kinship_matrix(state, ids)` for selected living pairs. A supplied matrix specifies related or inbred initial animals. The scalar effective-size approximation instead requires generation time in model intervals and explicit migration when introductions occur.

`run_pva_ensemble()` accepts one design row per model and a builder and summary function. Fixed seeds reproduce the member and replicate streams across worker counts. Use `cache_key` to identify revisions of external data read by callbacks. See the [grizzly](../../inst/examples/grizzly/README.md) and [woodhen](../../inst/examples/woodhen/README.md) projects for runnable lifecycles.

## Documentation source

`scripts/rd_topics.R` holds the text and `scripts/build_rd.R` writes `man/`,
building every usage section from the function's formals.
