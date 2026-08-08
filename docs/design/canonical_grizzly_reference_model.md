# Canonical grizzly reference model

## Role

This model is the first architecture acceptance benchmark for OpenPVA. It asks:

> Can a modeller express, execute, inspect, vary, and validate a consequential
> long-lived-mammal PVA without adding grizzly-specific branches to the engine?

It is not a calibrated Greater Yellowstone model, a recovery criterion, a
sustainable-mortality recommendation, or a package demonstration chosen only
because it is easy.

## Scientific question and estimands

Reference question: under stated vital rates and human-caused mortality
scenarios, what are the distributions of short-term population growth,
abundance, female abundance, and quasi-extinction outcomes for a small
grizzly-like population?

Primary estimands by scenario:

- finite population growth over a stated horizon;
- annual and final total abundance;
- annual independent-female abundance;
- probability and timing of crossing an explicit quasi-extinction threshold;
- human-caused mortality by sex/age/status;
- births, dependency transitions, and deaths by cause.

Genetic retention is an optional extension estimand, not part of the minimal
demographic baseline.

## Data-generating and observation processes

The simulator represents a latent population process. Vital-rate inputs are
assumed to have been estimated externally from telemetry, reproductive histories,
counts or integrated analyses. The baseline does not pretend those estimates are
error-free.

The acceptance benchmark must distinguish:

- process variation: Bernoulli survival, breeding and dependency events and
  optional annual environmental variation;
- parameter uncertainty: supplied as explicit alternative draws/scenarios;
- observation variation: outside the baseline, demonstrated by at least one
  optional census or harvest-observation process.

The sampling unit and replication unit are different: an individual is the unit
of lifecycle events; a simulation replicate is the unit for Monte Carlo
uncertainty. Years within a replicate are not independent replicates.

## Minimal state

### Individual fields

- `id`: stable unique integer;
- `sex`: explicit two-sex value;
- `age`: non-negative integer time steps;
- `alive`: logical, or absence from a live-population table under one agreed
  representation;
- `mother_id`: stable identifier or missing;
- `dependency`: `cub`, `yearling`, or `independent`;
- `reproductive_status`: sufficient to prevent breeding while dependent or
  caring for offspring under the selected rule;
- `cause_of_death`: event output rather than hidden state where practical.

### Global state

- current population;
- model globals used by processes, initially empty except explicitly required
  environmental or management state;
- `next_id`, owned by the engine.

No spatial patch, genotype, pedigree coefficient, body condition, habitat score,
or persistent individual frailty is required in the baseline.

## Reference lifecycle

The default annual order is a declared modelling choice:

1. draw annual environmental modifiers;
2. age individuals and update dependency;
3. determine breeding eligibility and mate availability;
4. breed and create litters/newborns;
5. apply survival to dependent offspring;
6. apply survival to independent bears;
7. apply human-caused mortality;
8. apply optional immigration or management introductions;
9. execute an explicitly positioned census observer when requested.

The modeller must be able to change, omit, or repeat processes. At least one
extension demonstration must move human-caused mortality before reproduction and
show that the program changes without controller edits. OpenPVA must not assert
that the reference order is universally correct.

The engine inserts no implicit census. An optional initial census records the
starting state at `t = 0`; subsequent census position defines its pre/post-event
meaning. Step `t` covers interval `t -> t+1`, and births and other events are
labelled `t`.

## Rates and stochastic validation

Parameter values are supplied by fixtures, never silently defaulted as grizzly
truth. Required functions/tables define:

- sex/status/age-specific natural survival;
- probability of breeding among eligible females;
- litter-size distribution;
- offspring sex distribution;
- dependency transition rules;
- human-caused mortality by selected class.

### Expected-value oracle

Stage 1 does not implement a second aggregate/fractional population
representation or native deterministic process mode. Instead, an independent
life-table or matrix calculation provides expected values under deliberately
matched assumptions. Stochastic replicate means must converge to that oracle
within stated Monte Carlo error. The oracle is test evidence, not another engine
execution path.

### Stochastic execution

Individual outcomes use one engine-assigned L'Ecuyer-CMRG stream per replicate,
with sequential draws through ordered processes. Replicate streams are
preassigned so serial and parallel execution match, and caller RNG state is
restored. Number of replicates is justified by Monte Carlo error for the
reported decision metric.

## Management scenarios

The minimal benchmark includes:

- baseline natural demography with no human-caused mortality;
- at least two explicit independent-female survival or mortality scenarios;
- a sex/age-targeted human-caused mortality scenario;
- one introduction/immigration extension.

Scenarios compare distributions and thresholds; they do not label a mortality
rate “sustainable” without a stated horizon, population state, uncertainty, and
decision criterion.

## Required outputs

- run/year abundance by sex and dependency/status;
- births, dependency transitions, natural deaths, human-caused deaths and
  introductions;
- annual environmental modifiers;
- growth and threshold-crossing summaries with Monte Carlo uncertainty;
- process order, parameter hashes/values, seed provenance and software version;
- event/accounting diagnostics sufficient to reconcile population change.

## Extension demonstrations

The benchmark passes only if all can be added without controller edits:

1. reorder human-caused mortality and reproduction;
2. replace survival with an annually varying survival process;
3. add a custom observation process that leaves population state unchanged;
4. add immigration or translocation;
5. optionally add pedigree/genetic state and an inbreeding-dependent vital-rate
   process;
6. optionally add patch membership with correctly initialized newborn patches.

## Validation ladder

1. **Object validation:** field types, unique IDs, parent references, probability
   bounds, parameter units and required fields.
2. **Process tests:** one process at a time on hand-calculable populations,
   including zero, one-sex and all-dependent edge cases.
3. **Accounting tests:** start + births + introductions - deaths = end, by run
   and year; no duplicate IDs or impossible dependency transitions.
4. **Expected-value oracle:** compare stochastic means with an independent life
   table or matrix under exactly matched assumptions and stated Monte Carlo
   error.
5. **Stochastic calibration:** Bernoulli/offspring frequencies converge within
   stated Monte Carlo error; fixed seeds reproduce exactly.
6. **Order falsification:** demonstrate expected differences when survival or
   mortality moves relative to reproduction.
7. **Hindcast:** only when a dated dataset and holdout rule are supplied; do not
   use calibration observations for validation.
8. **Cross-engine fixture:** where assumptions can be exactly matched, compare
   against an independent calculation or implementation.

## Non-goals

- exact replication of historical GAPPS, VORTEX, or GYE outputs;
- native deterministic execution or a second fractional population
  representation in Stage 1;
- default density dependence, metapopulation dynamics, habitat suitability,
  disease, climate forcing, infanticide, or genomic selection;
- inference of vital rates from raw monitoring data;
- management optimisation or causal attribution;
- a claim that the minimal state captures all grizzly biology.

## Acceptance boundary

Scientific parameterisation requires a separate goal with named data sources,
observation model, units, population and time period. Barry must approve any
values presented as canonical empirical defaults.
