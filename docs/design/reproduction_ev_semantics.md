# Design: reproduction rate semantics

## Active contract

`reproduction_process()` separates two effective-rate callbacks from stochastic
realisation:

- `breeding_probability(mother, state, context, params)` returns one value in
  `[0, 1]`;
- `fecundity_mean(mother, state, context, params)` returns one finite
  non-negative Poisson mean.

For each living female, the process draws breeding as Bernoulli, resolves the
optional mate, draws litter size as Poisson conditional on breeding, allocates
stable IDs, initializes declared newborn fields and emits accounting events.

## Modeller-owned effective rates

The callbacks return effective values. They may explicitly compose baseline
demography, environment, density or other scientifically justified terms:

```r
breeding_probability = function(mother, state, context, params) {
  params$base_breeding *
    state$globals$environment_modifier *
    ceiling_density_multiplier(
      state$globals$density_n_alive,
      params$capacity
    )
}
```

The process validates the final callback result but does not infer channels,
composition order or bounds-clamping policy. Every state input must appear in
the process `requires` declaration. The modeller therefore owns both the
scientific formula and where its upstream measurement processes occur.

Applying one density multiplier to breeding probability and again to
fecundity means expected births receive both terms. In the Goal 004 synthetic
extension the same multiplier is used deliberately in both callbacks, so its
reproductive expectation contains the multiplier squared. This is an explicit
fixture choice, not an OpenPVA default.

## Deferred configuration

YAML and environmental-variation compilation are Stage 4 analysis/configuration
work. They may construct these ordinary callbacks but must not become a second
controller, a fixed modifier channel system or a lifecycle DSL.

## Validation

Tests should distinguish breeding-only, fecundity-only and combined effects.
For `n` eligible females, breeding probability `p` and conditional Poisson mean
`lambda`, the independent expectation is

```text
E[births] = n * p * lambda
Var(births) = n * (p * lambda + p * (1 - p) * lambda^2)
```

Stochastic validation should compare replicate means against this compound
expectation using stated Monte Carlo error rather than a single seeded result.
