# Design: density dependence module

Status: DECISION LOCKED + CHANNEL PATH IMPLEMENTED (WP-1.1.1 / WP-1.1.2)

## 1) Goal

The current density implementation generalizes the earlier survival-only
`K`/`K_patches` idea into a modular channel system that can scale:

- survival probability,
- breeding probability,
- fecundity lambda.

The current line is a clean break: density composition must be explicit and
auditable through `density_spec()`. Any compatibility claim requires named
tests and documentation rather than an implicit promise for older scenarios.

## 2) Core semantic model

Density is represented as channel-specific multiplicative modifiers. For each
relevant individual-year calculation:

- `survival`: `p_surv_eff = clamp01(p_surv_base * m_surv_density * m_surv_evcat)`
- `breeding`: `p_breed_eff = clamp01(p_breed_base * m_breed_density * m_breed_evcat)`
- `fecundity`: `lambda_eff = max(0, lambda_base * m_fec_density * m_fec_evcat)`

Where:

- baseline rates come from demography functions/tables,
- density modifiers come from the density module,
- EV/cat modifiers come from controller year-level processes,
- stochastic draws remain controller-owned.

## 3) Ordering contract (non-negotiable)

The controller must apply in this order:

1. baseline demography rate,
2. density modifier,
3. year-level EV/cat modifier,
4. bounds clamp (`[0,1]` for probabilities, `>=0` for lambdas),
5. stochastic draw (Bernoulli/Poisson where relevant).

This keeps density, EV, and demographic stochasticity separable.

## 4) State inputs and scope

Minimum required state for density functions:

- total alive `N` (global),
- optional per-patch alive counts `N_patch`,
- optional carrying capacities (global and/or patch),
- current individual (for patch-specific scaling).

Design scope for current implementation line:

- global and patch-level scaling,
- no age-structured density state in initial version,
- additive extensibility for richer state summaries later.

## 5) Interface shape

An R-level density spec should support channel-specific functions:

- `survival_fun(population, ind) -> multiplier`
- `breeding_fun(population, ind) -> multiplier`
- `fecundity_fun(population, ind) -> multiplier`

Each function returns a single finite numeric multiplier `>= 0`.

The explicit constructor `make_ceiling_density_fun()` accepts `K` or
`K_patches` and returns a channel function. These values are not
`scenario_spec()` arguments; callers attach the constructor through
`density_spec()`.

## 6) Compatibility and migration

The current controller and YAML line is clean-break:

- `scenario_spec()` has no `K` or `K_patches` parameters.
- YAML accepts only explicit `density.survival`, `density.breeding`, and
  `density.fecundity` channel blocks; shorthand density fields are rejected.
- Existing compatibility claims require named tests and documentation. The
  historical `K`/`K_patches` behavior is represented by the explicit ceiling
  constructor rather than an implicit scenario adapter.

## 7) YAML implications

Canonical schema v3 exposes density through explicit channel blocks. Each
channel may use a constant multiplier, a function reference, or a ceiling
model with `K` or `K_patches`; top-level and shorthand density fields are not
accepted. See `docs/reference/yaml_schema_v1.md` (the filename is historical;
the documented contract is schema v3).

## 8) Test requirements

- Unit tests:
  - density spec validation,
  - global and patch ceiling density function behavior.
- Integration tests:
  - channel effects on survival/reproduction outputs,
  - explicit ceiling constructor behavior for global and patch capacities,
  - seeded deterministic behavior with density active.

## 9) Out-of-scope for this design lock

- Density effects on non-vital-rate processes (e.g., movement) in this line.
- Age-structured density states.
- YAML implementation details (covered separately in WP-1.1.3).
