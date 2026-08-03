# Design: reproduction semantics + reproduction EV

Status: DECISION LOCKED + CONTROLLER PATH IMPLEMENTED (WP-0.5.4)

## 1) Historical problem statement

The pre-rate reproduction flow mixed structural rules and stochastic outcomes:

- `breeding_fun(ind)` as boolean eligibility.
- `fecundity_fun(ind)` as realized integer count.

That coupling makes year-level EV/cat application awkward and weakens auditability.

## 2) Locked semantic model

Reproduction is split into baseline rates plus controller stochastic realization:

- `breeding_prob_fun(ind)` returns baseline `p_breed_base` in `[0, 1]`.
- `fecundity_lambda_fun(ind)` returns baseline `lambda_base >= 0`.

Controller then applies year-level modifiers and performs stochastic draws:

- breeding realization via Bernoulli,
- offspring realization via Poisson (conditional on breeding).

This split is mandatory for all new reproduction pathways.

## 3) Controller responsibilities

For each run-year:

1. Compute reproduction EV/cat year modifiers.
2. Compute effective per-individual rates:
   - `p_breed_eff = clamp01(p_breed_base * m_p_year * m_p_density * ...)`
   - `lambda_eff = max(0, lambda_base * m_lambda_year * m_lambda_density * ...)`
3. Draw breeding realizations (Bernoulli).
4. Resolve mates using configured mating policy.
5. Draw offspring counts for realized breeders (Poisson).
6. Generate offspring records and metadata.

## 4) Clean-break contract

The current development line is clean-break by design:

- controller/scenario APIs use baseline-rate channels only,
- YAML uses a single canonical schema (`schema_version: 3`),
- legacy `breeding_fun` / `fecundity_fun` controller shims are intentionally
  removed.

Breaking changes are allowed when the repo docs, tests, and packaged examples
move together.

## 5) YAML implications

Canonical YAML exposes explicit baseline reproduction fields and reproduction EV:

- baseline breeding probability channels,
- baseline fecundity lambda channels,
- year-level reproduction EV/cat configuration.

The current parser accepts only this canonical schema-v3 form. Older YAML and
the historical controller shims are not compatibility promises; any future
migration requires named tests and documentation.

## 6) Worked example

Assume a female with:

- `p_breed_base = 0.60`
- `lambda_base = 1.80`

And a given year has:

- breeding EV multiplier `m_p_year = 0.90`
- fecundity EV multiplier `m_lambda_year = 1.10`
- no catastrophe

Then:

- `p_breed_eff = 0.60 * 0.90 = 0.54`
- `lambda_eff = 1.80 * 1.10 = 1.98`

Controller draws:

- breed? `Bernoulli(0.54)`
- if breeding realized, offspring count `Poisson(1.98)`

This shows baseline demography and yearly stochastic forcing remain separable and auditable.

## 7) Test requirements for implementation WPs

- unit tests for new reproduction API helpers/builders,
- integration tests:
  - canonical YAML path,
  - deterministic seeded behavior,
  - output schema regression safety.
