# Design: reproduction semantics + reproduction EV

Status: DECISION LOCKED + CONTROLLER PATH IMPLEMENTED (WP-0.5.4)

## 1) Problem statement

Legacy reproduction flow currently mixes structural rules and stochastic outcomes:

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

## 4) Compatibility/deprecation contract

Compatibility is adapter-first:

- Legacy `breeding_fun` and `fecundity_fun` remain accepted during transition.
- Legacy channels are adapted into the new controller semantics.
- Legacy YAML must continue to run through versioned migration/adaptation.

Deprecation policy:

- No hard removal until replacement API/docs/tests are complete.
- When deprecations begin, emit explicit warnings with migration guidance.

Breaking changes (must be explicitly declared):

- removing legacy interface channels without wrappers,
- changing output schema semantics without contract documentation/tests,
- changing lifecycle ordering semantics without opt-in and migration notes.

## 5) YAML v2 implications (planned)

YAML v2 should expose explicit baseline reproduction fields and reproduction EV:

- baseline breeding probability channels,
- baseline fecundity lambda channels,
- year-level reproduction EV/cat configuration,
- compatibility migration from v1/legacy.

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
- adapter tests ensuring legacy interfaces preserve behavior envelopes,
- integration tests:
  - legacy YAML compatibility path,
  - new YAML path,
  - deterministic seeded behavior,
  - output schema regression safety.
