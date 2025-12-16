# Design: reproduction semantics + reproduction EV (planned refactor)

Status: DRAFT (must be finalised before implementation lands)

## 1) Problem statement

Current reproduction API is oriented around:
- `breeding_fun(ind)` returning a boolean “eligibility” predicate,
- `fecundity_fun(ind)` returning a realised integer litter size.

This pattern makes year-level EV/cats on reproduction awkward and obscures what is baseline demography vs stochastic draw.

Goal: cleanly separate
- baseline probabilities/means (demography),
- stochastic draws (controller),
- year-level EV/cats modifiers,
- demographic stochasticity and mating constraints.

## 2) Proposed new interfaces

### 2.1 Breeding probability
- `breeding_prob_fun(ind)` → p in [0,1]
  - interpreted as probability a (eligible) female breeds in a normal year.

Open question:
- should the breeding table itself return probabilities,
  or should “eligibility” remain structural and probability be layered?

### 2.2 Fecundity mean
- `fecundity_lambda_fun(ind)` → λ ≥ 0
  - interpreted as mean offspring number conditional on breeding.

## 3) Controller responsibilities (post-refactor)

In each year (and optionally per patch):
- compute EV/cat multipliers for breeding and lambda,
- compute effective p and λ per individual,
- draw:
  - breeders via Bernoulli,
  - offspring counts via Poisson,
- apply mating constraints.

## 4) EV/cats choices (to decide)

- p_breed EV: logit-normal vs multiplicative vs other
- λ EV: lognormal vs other
- catastrophe impacts: multiplicative scalers? year-level overrides?

Decision(s) must be recorded in `docs/decisions.md`.

## 5) Backwards compatibility plan

Preferred:
- keep current `breeding_fun` / `fecundity_fun` working via adaptors/wrappers.
- introduce new names and route new scenarios through the new controller path.
- add deprecation warnings later only if necessary.

## 6) YAML implications

Once semantics are stable:
- extend YAML to express:
  - breeding probabilities,
  - fecundity means,
  - reproduction EV parameters (p_sd, lambda_sd, catastrophe effects),
  - and any density modifiers if needed.

## 7) Test plan (mandatory)

- unit tests for table builders and validators
- integration tests:
  - legacy YAML still runs,
  - new YAML runs,
  - deterministic seed runs show expected behaviours,
  - regression tests on summary columns.
