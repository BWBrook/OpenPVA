# Density API

This page documents the explicit R-level density module interface used by the
current controller/scenario APIs.

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

## YAML integration

YAML scenarios configure density through a top-level `density` block. See
`docs/reference/yaml_schema_v1.md` for field-level schema details.

## Notes on `survival_scale` summary field

`survival_scale` is retained in the summary schema and remains `1` for the
explicit density path. Channel effects are represented through outcomes rather
than through a separate legacy scalar.
