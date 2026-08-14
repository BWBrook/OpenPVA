# YAML Schema Contract (Canonical v3)

This page documents the single supported YAML scenario schema for OpenPVA.

## Versioning rule

- `schema_version: 3` is required.
- Older schema variants are intentionally not supported in the current
  development line.

## Required top-level fields

- `name`
- `n_runs`
- `n_years`
- `initializer.fun`

`initializer.args` is optional and, when present, must be a named mapping.

## Core optional fields

- `survival_fun`
- `lifecycle_steps`
- `mating_fun`
- `dispersal_fun`
- `inherit_fun`
- `env_surv_sd`
- `cat_surv_prob`
- `cat_surv_mult`
- `seed`
- `require_mate`
- `record_population_history`
- `density` (optional density module block; see below)

Management options can also be expressed under `management`:

- `management.harvest_quota`
- `management.supplement_quota`
- `management.supplement_patch`

Canonical reproduction-function fields:

- `breeding_prob_fun`
- `fecundity_lambda_fun`

## Demography table blocks

Supported demography tables:

- `demography.survival.table` (`p_surv`)
- `demography.breeding_prob.table` (`p_breed`)
- `demography.fecundity_lambda.table` (`lambda`)

## Reproduction EV/cat configuration

Canonical form:

- `reproduction_ev.env_repro_p_sd`
- `reproduction_ev.env_repro_lambda_sd`
- `reproduction_ev.cat_repro_prob`
- `reproduction_ev.cat_repro_mult`

## Uncertainty block

`uncertainty` is an optional mapping for ensemble workflows.

Supported forms:

- direct parameter map:
  - `uncertainty.<parameter_name>.<spec_fields>`
- nested parameter map:
  - `uncertainty.params.<parameter_name>.<spec_fields>`

Each parameter spec requires:

- `dist`: one of `fixed`, `uniform`, `normal`, `lognormal`

Distribution-specific required fields:

- `fixed`: `value`
- `uniform`: `min`, `max`
- `normal`: `mean`, `sd`
- `lognormal`: `meanlog`, `sdlog`

Optional fields:

- `lower` (clamp lower bound)
- `upper` (clamp upper bound)
- `integer` (`true`/`false`)

Parameter names must match writable scenario fields (for example
`harvest_quota`, `cat_surv_prob`, `cat_surv_mult`) for use with
`run_scenario_ensemble()`.

## Lifecycle function hooks

Optional function hooks can be supplied by name:

- `mating_fun` (`function(females, males)` used in reproduction),
- `dispersal_fun` (`function(ind, population)` used by `dispersal` lifecycle
  steps).

When omitted, defaults from the core scenario API are used.

## Density configuration

An optional `density` mapping can define channel-specific density multipliers.

Supported channels:

- `density.survival`
- `density.breeding`
- `density.fecundity`

Each channel supports one of:

- function reference:
  - `fun: "<function_name>"`
- constant multiplier:
  - `model: constant`
  - `multiplier: <numeric >= 0>`
- ceiling model:
  - `model: ceiling`
  - `K: <numeric > 0>` or `K_patches: [<numeric > 0>, ...]`

Only the explicit channel form is supported. Shorthand forms such as
top-level `K`, top-level `K_patches`, `density.K`, and `density.K_patches` are
not accepted.

## Deterministic seeding

- `seed` is optional and must be a single integer.
- When set, replicate-level stochasticity is deterministic for demographic and
  EV/cat draws.
- OpenPVA restores caller RNG state after scenario execution so seeded scenario
  runs do not perturb downstream random streams in the same R session.

## Mate requirement control

- `require_mate` is optional and must be a logical scalar.
- `require_mate: false` (default): unmated females may still produce offspring
  (with `father_id = NA`).
- `require_mate: true`: females without an assigned mate produce no offspring.

## Population history capture

- `record_population_history` is optional and must be a logical scalar.
- `record_population_history: false` (default): run outputs contain final
  population and yearly summary only.
- `record_population_history: true`: each run output includes
  `population_history` (one population snapshot per simulated year) for
  legacy time-series summaries.

The returned scenario includes attribute `yaml_schema_version = 3L`.
