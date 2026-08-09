# Design: global density feedback

## Status and boundary

Goal 004 replaces the disconnected controller-era density specification with
ordinary process composition. This tranche implements global abundance only.
Patch-specific density follows spatial migration; no compatibility adapter or
privileged density channel remains.

## Measurement process

`density_snapshot_process()` counts living individual records at its exact
position in the modeller's ordered process list. It:

- requires `population.id` and `population.alive`;
- writes the integer count to `globals.density_n_alive`;
- emits one `density_snapshot` event containing `n_alive`;
- changes neither population records nor `next_id`.

The engine stamps run, time, phase and process provenance. Process position is
scientific structure: measuring before reproduction records pre-birth
abundance, while measuring after reproduction includes that interval's births.
A downstream process that declares `globals.density_n_alive` but has no
upstream writer fails field-dependency preflight.

## Pure multiplier

For non-negative whole-number abundance `N` and positive modeller-supplied
capacity `K`, `ceiling_density_multiplier(N, K)` returns

```text
1       when N <= K
K / N   when N > K
```

The zero-abundance result is therefore exactly one. The multiplier is a pure
calculation with no population, state, event or RNG effect.

## Modeller-owned composition

Density is not an engine channel. A callback states explicitly which vital
rate is affected and how all terms compose. For example:

```r
survival_process(
  probability = function(individual, state, context, params) {
    params$base_survival *
      state$globals$environment_modifier *
      ceiling_density_multiplier(
        state$globals$density_n_alive,
        params$capacity
      )
  },
  requires = c(
    "globals.environment_modifier",
    "globals.density_n_alive"
  ),
  params = list(base_survival = 0.8, capacity = 100)
)
```

The same pure term can be used explicitly in `breeding_probability` or
`fecundity_mean` callbacks. Bounds remain the callback author's responsibility:
probability callbacks must return `[0, 1]`, and fecundity callbacks a finite
non-negative mean. OpenPVA does not infer affected rates, composition order or
capacity from scenario state.

## Scientific interpretation

This ceiling form is phenomenological vital-rate feedback. Its `capacity`
parameter is not automatically an empirical carrying capacity, a hard cap,
population truncation, or a guarantee that abundance will equilibrate at that
value. Interpretation depends on the rate affected, lifecycle position,
population measure, temporal scale and parameter evidence supplied by the
model.

`grizzly_density_extension_scenario()` is a source-labelled synthetic example
that applies one positioned snapshot to survival, breeding and fecundity. The
breeding and fecundity callbacks each apply the multiplier, so expected births
contain both terms. It is not one of the five canonical Goal 003 scenarios and
supplies no empirical grizzly density default.

## Deferred

- patch-specific abundance and capacity;
- age-, sex- or resource-structured density state;
- lags, stochastic capacity and environmental inference;
- calibration, sensitivity and YAML configuration;
- a modifier registry or controller-managed density specification.
