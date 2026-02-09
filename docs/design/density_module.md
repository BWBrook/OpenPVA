# Design: density dependence module

Status: DECISION LOCKED (WP-1.1.1)

## 1) Goal

Generalize density dependence from survival-only `K`/`K_patches` scaling into a
modular channel system that can scale:

- survival probability,
- breeding probability,
- fecundity lambda.

The design must preserve backward compatibility for existing scenarios while
making density composition explicit and auditable.

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

Compatibility adapters map legacy fields:

- `K` -> global ceiling scale on survival channel,
- `K_patches` -> patch ceiling scale on survival channel.

## 6) Compatibility and migration

Compatibility strategy is adapter-first:

- Existing scenarios using `K`/`K_patches` remain valid.
- Legacy behavior is preserved by internally constructing equivalent survival
  density multipliers.
- New density channels are opt-in unless explicitly configured.

Potentially breaking behavior remains deferred to a future major release unless
explicitly versioned and documented under semver policy.

## 7) YAML implications (next WP)

YAML support is handled in WP-1.1.3. Planned principles:

- additive schema fields for density channels,
- explicit migration/adaptation path from legacy `K`/`K_patches`,
- regression tests for parsing and behavior preservation.

## 8) Test requirements

- Unit tests:
  - density spec validation,
  - global and patch ceiling density function behavior.
- Integration tests:
  - channel effects on survival/reproduction outputs,
  - legacy `K`/`K_patches` parity behavior,
  - seeded deterministic behavior with density active.

## 9) Out-of-scope for this design lock

- Density effects on non-vital-rate processes (e.g., movement) in this line.
- Age-structured density states.
- YAML implementation details (covered separately in WP-1.1.3).
