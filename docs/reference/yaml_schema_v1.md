# YAML schema contract (v1 + v2)

This page documents the supported YAML scenario schemas for OpenPVA.

## Versioning rules

- `schema_version: 2` is the current schema for reproduction semantics.
- `schema_version: 1` remains supported.
- Missing `schema_version` is treated as legacy schema 0 and migrated to v1.
- Unknown future versions are rejected with a clear error.

## Required top-level fields

- `name`
- `n_runs`
- `n_years`
- `initializer.fun`

`initializer.args` is optional and, when present, must be a named mapping.

## Core optional fields (all versions)

- `survival_fun`
- `K`
- `K_patches`
- `harvest_quota`
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

## Reproduction fields by schema

Schema v1 accepts legacy top-level function names:

- `breeding_fun`
- `fecundity_fun`

Schema v2 prefers baseline-rate channels:

- `breeding_prob_fun`
- `fecundity_lambda_fun`

Schema v2 also supports adaptation from v1-style channels so older YAML can be
upgraded incrementally.

## Demography table blocks

Both versions can include `demography.survival.table` (`p_surv`).

Schema v1 tables:

- `demography.breeding.table` (`can_breed`)
- `demography.fecundity.table` (`lambda`)

Schema v2 tables:

- `demography.breeding_prob.table` (`p_breed`)
- `demography.fecundity_lambda.table` (`lambda`)

When schema v2 input includes v1 demography table keys, OpenPVA adapts them to
v2 channels during parsing.

## Reproduction EV/cat configuration

Schema v2 canonical form:

- `reproduction_ev.env_repro_p_sd`
- `reproduction_ev.env_repro_lambda_sd`
- `reproduction_ev.cat_repro_prob`
- `reproduction_ev.cat_repro_mult`

Legacy top-level forms of those keys are still accepted and migrated.

## Lifecycle function hooks

Optional function hooks can be supplied by name:

- `mating_fun` (`function(females, males)` used in reproduction),
- `dispersal_fun` (`function(ind, population)` used by `dispersal` lifecycle
  steps),
- `inherit_fun` (`function(mother, father)` used for offspring genotype
  inheritance).

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

Legacy shorthand under `density` is also supported:

- `density.K`
- `density.K_patches`

This shorthand maps to `density.survival` with `model: ceiling`.

Compatibility rules:

- top-level legacy `K`/`K_patches` remain supported.
- explicit `density` block cannot be combined with top-level `K` or
  `K_patches` in the same YAML file.

## Deterministic seeding

- `seed` is optional and must be a single integer.
- When set, replicate-level stochasticity is deterministic for demographic and
  EV/cat draws.
- OpenPVA restores caller RNG state after scenario execution so seeded scenario
  runs do not perturb downstream random streams in the same R session.

## Mate requirement control

- `require_mate` is optional and must be a logical scalar.
- `require_mate: false` (default, legacy behavior): unmated females may still
  produce offspring (with `father_id = NA`).
- `require_mate: true`: females without an assigned mate produce no offspring.

## Population history capture

- `record_population_history` is optional and must be a logical scalar.
- `record_population_history: false` (default): run outputs contain final
  population and yearly summary only.
- `record_population_history: true`: each run output includes
  `population_history` (one population snapshot per simulated year) for
  spatial/genetic time-series summaries.

## Migration behavior

Legacy schema 0 and schema v1 remain runnable:

1. Missing `schema_version` is migrated to v1.
2. Schema v2 parsing performs compatibility adaptation for v1-style
   reproduction table and EV fields where possible.
3. The returned scenario includes attribute `yaml_schema_version` set to the
   parsed schema (`1` or `2`).

## Regression gate note

- CI heavy validation includes schema migration snapshot checks to protect
  v1/v2 adaptation behavior against unintended parser drift.
