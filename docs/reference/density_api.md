# Density API (1.1.x)

This page documents the R-level density module interface introduced after the
1.0 release line.

## Purpose

The density module provides channel-specific multiplicative modifiers that are
applied by controllers to baseline vital rates.

Supported channels:

- `survival`
- `breeding`
- `fecundity`

## Public constructors and validators

- `density_spec(survival_fun = NULL, breeding_fun = NULL, fecundity_fun = NULL)`
- `validate_density_spec(spec)`
- `make_ceiling_density_fun(K = NULL, K_patches = NULL)`

## Function contract

Each channel function must have signature:

- `function(population, ind) -> multiplier`

Requirements:

- Return value must be a single finite numeric scalar.
- Return value must be `>= 0`.
- At least one channel function must be supplied in `density_spec()`.

## Controller composition order

For each vital-rate calculation, OpenPVA applies:

1. baseline demography rate
2. density channel multiplier
3. year-level EV/cat multiplier
4. bounds clamp (`[0, 1]` for probabilities, `>= 0` for lambdas)
5. stochastic draw (Bernoulli/Poisson where relevant)

## Legacy compatibility mapping

Legacy carrying-capacity inputs remain supported:

- `K` maps to a global ceiling multiplier on the survival channel.
- `K_patches` maps to patch-level ceiling multipliers on the survival channel.

Compatibility rules:

- `K` and `K_patches` remain mutually exclusive.
- `density_spec` cannot be combined with `K` or `K_patches` in the same call.

## YAML integration

YAML scenarios can configure density through a top-level `density` block. See
`docs/reference/yaml_schema_v1.md` for field-level schema details.

## Notes on `survival_scale` summary field

`survival_scale` remains for legacy compatibility:

- Legacy global `K`: stores the global ceiling scale used that year.
- Legacy `K_patches`: set to `NA` because no single global scalar applies.
- Explicit `density_spec`: set to `1` (channel effects are represented directly
  through outcomes rather than a legacy scalar).
