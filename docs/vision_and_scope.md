# OpenPVA North Star

## Mission

> The modeller defines the biological program; OpenPVA supplies the execution
> engine, reusable processes, scientific contracts, and reproducible analysis
> machinery.

OpenPVA is a modern, open-R system for constructing, running, checking, and
communicating population viability analyses. Its central product is not one
fixed life cycle or one species model. It is an inspectable execution framework
in which biological and management processes are ordinary R components whose
order, inputs, state effects, stochasticity, and outputs are explicit.

## Scientific purpose

OpenPVA supports descriptive, predictive, and decision-scenario population
models. It does not make a causal or predictive model credible merely by running
it. Credibility depends on the estimand, sampling and observation processes,
parameter evidence, structural assumptions, validation, and scope of inference.

For a typical PVA, the modeller remains responsible for defining:

- the population, spatial and temporal scales of inference;
- the individual, stage, patch, or population units;
- lifecycle order and biological processes;
- vital-rate, density, environmental, genetic, movement, and management models;
- observation error, detection, missingness, and sampling bias where relevant;
- validation data, sensitivity questions, and decision thresholds.

OpenPVA is responsible for executing that program consistently, protecting
state and random-number contracts, recording provenance, validating process
requirements, and returning trajectories, events, diagnostics, and summaries
without hiding assumptions.

## Product promise

A modeller should be able to:

1. compose an ordered lifecycle from reusable or project-defined R processes;
2. replace, repeat, omit, or add a process without editing the engine controller;
3. inspect what each process requires and writes;
4. test stochastic simulations against independent expected-value calculations
   where matched life-table or matrix assumptions permit it;
5. reproduce runs from explicit parameters, seeds, versions, and provenance;
6. validate transformations, accounting identities, special cases, hindcasts,
   and decision-relevant outputs;
7. retain replicate-level evidence rather than only polished summaries.

Community extension is a core acceptance condition: a third-party process must
compose through the public contract without a new engine branch or central
registry entry.

## Architectural commitments

- **R-native composition.** Ordinary functions and simple named lists are the
  default. A minimal S3 tag may aid validation and printing, but inheritance is
  not the process protocol.
- **Explicit order.** The lifecycle is a direct ordered process list. Repetition
  and omission are meaningful and validated.
- **Separated ownership.** Processes own biological transformations. The engine
  owns interval time, process occurrence, replicate RNG streams, run identity,
  event collection,
  provenance, and failure context.
- **Visible state effects.** Population state, global dynamic state, and stable
  identifier allocation are explicit. Hidden global mutation is prohibited.
- **No premature platform.** No YAML lifecycle DSL, plugin manager, dependency-
  injection system, global registry, or S4/R6 hierarchy until demonstrated use
  proves that simpler R composition is inadequate.
- **Clean realignment.** Obsolete controller paths will be removed rather than
  preserved behind compatibility adapters when implementation is authorised.
- **Locked lean defaults.** Goal 001 fixes replicate-level L'Ecuyer-CMRG
  streams, declared field dependencies, required event provenance, and explicit
  interval/census semantics. Native deterministic execution is deferred.

## Canonical benchmark

The first acceptance benchmark is a minimal grizzly-bear model derived from the
scientific questions that motivated and later exercised GAPPS: structured
survival and reproduction, maternal dependency, stochastic demography,
human-caused mortality, alternative survival scenarios, and inspectable
population summaries and, when enabled, genetic summaries. It is defined in
`docs/design/canonical_grizzly_reference_model.md`.

The benchmark is not a universal default, a calibrated Greater Yellowstone
model, or a management recommendation. Its purpose is to prove that the engine
can express and test a consequential long-lived-mammal PVA without hard-coding
grizzly logic.

## Scope boundaries

OpenPVA is:

- an execution engine and reusable scientific-process library;
- primarily individual-based; an additional aggregate/fractional population
  representation is not required for the first realignment;
- a reproducible analysis substrate for uncertainty, sensitivity, hindcasting,
  scenario comparison, and reporting;
- designed for code-capable ecologists and extensible by community R packages.

OpenPVA is not:

- a black-box extinction-risk calculator;
- a guarantee that a model is identifiable, calibrated, or decision-safe;
- a replacement for integrated population models, habitat models, SDMs,
  optimisation systems, or specialised genetic simulators;
- a requirement that every model include genetics, space, density dependence,
  or every available feature;
- currently a GUI product or a new modelling language.

## Current decision boundary

The repository has substantial implemented breadth, but its lifecycle vocabulary
is still fixed to six controller-recognised labels. The next implementation
tranche is therefore architectural realignment, not another feature family.
`docs/design/lifecycle_process_contract.md` supplies the approved lean defaults
for RNG, fields, events and time/census semantics. Barry's remaining decision is
strategic acceptance of this package before implementation begins.

Current capabilities and historical roadmaps are evidence about the starting
point, not the authority for product direction. This document is the authority.
