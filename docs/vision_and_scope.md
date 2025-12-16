# OpenPVA Roadmap and Scope

This document describes the planned development phases for OpenPVA and clarifies what is **in scope now** versus **deferred to later stages**.

The purpose is to keep both human contributors and automated agents focused on the right problems at the right time.

---

## Phase 0 – Foundations (completed / ongoing)

**Objectives:**

- Establish the core repository structure.
- Define development conventions and architectural principles.
- Capture GAPPS heritage and design intent in documentation.

**Key artefacts:**

- `docs/overview_openpva.md`
- `docs/architecture_core.md`
- `docs/dev_conventions_r.md`
- `docs/gapps_heritage.md`
- `docs/agent_guidelines_codex.md`

**Status:**  
These documents and the basic `R/` skeleton exist and will be refined as the project evolves.

---

## Phase 1 – Core Demographic Engine (current focus)

**Goal:**  
Implement a clean, testable **individual-based demographic engine** with a minimal but complete life cycle.

### 1.1 Core components

In scope:

- Individual representation (lists with id, sex, age, alive, etc.).
- Population representation as a collection of individuals.
- Lifecycle processes:
  - Ageing (`age_individuals()`).
  - Survival (`apply_survival()` with pluggable survival functions).
  - Breeding-eligibility (`determine_breeding()`).
  - Birth/offspring creation (initial minimal implementation).
- Simple density feedback:
  - E.g. ceiling-based regulation, basic harvest/removal modules.

Out of scope (for Phase 1):

- Detailed genetics (alleles, loci, inbreeding coefficients).
- Complex spatial structures (patch networks, landscapes).
- Sophisticated management rules (e.g. complex optimisation routines).

### 1.2 Simulation controller

In scope:

- A basic simulation function that:
  - Accepts an initial population and parameters.
  - Applies a fixed sequence of lifecycle processes over time.
  - Returns population trajectories and simple summary metrics.

- Integration with `targets`:
  - Targets to initialise a population, run simulations, and summarise results.

### 1.3 Testing and examples

In scope:

- Unit tests for all core functions.
- At least one worked example:
  - A small, stylised population (e.g. simple age-structured mammal) with deterministic/stochastic runs.

---

## Phase 2 – Genetics and Inbreeding

**Goal:**  
Extend the engine to optionally model **genetic attributes** and their interaction with demography.

In scope:

- Adding genetic fields to individuals (e.g. allele representations, F).
- Functions for:
  - Initialising diversity (`initialise_alleles()`).
  - Tracking inbreeding (`update_inbreeding()`).
  - Calculating diversity/heterozygosity metrics.
- Mechanisms to apply inbreeding depression to survival or breeding:
  - E.g. functions that adjust vital rates based on F or other genetic metrics.

Out of scope (Phase 2):

- Full-blown population genetics platform.
- Complex multi-locus selection models.
- Tight coupling to external genetics simulators.

The aim is to recapture the spirit of GAPPS’s `ALLELES`, `INBREED`, `GENETICS`, `DEPRESS` functionality in a transparent R implementation.

---

## Phase 3 – Spatial and Environmental Structure

**Goal:**  
Introduce spatial structure and environmental dynamics in a modular way.

In scope:

- Spatial representation:
  - Patches or regions with their own carrying capacities and vital rate modifiers.
  - Assignment of individuals to patches.
- Dispersal modules:
  - Simple distance- or probability-based movement between patches.
- Environmental forcing:
  - Time series of patch-level conditions affecting vital rates or K.
- Basic spatial outputs:
  - Distribution of individuals across patches through time.
  - Patch-level extinction risks.

Out of scope (Phase 3):

- Continuous landscapes with complex movement kernels.
- Direct coupling to external SDM/climate models (except via pre-processed inputs).
- Eco-evolutionary range shift modelling (this is in the territory of RangeShiftR).

---

## Phase 4 – Decision Support and Management Scenarios

**Goal:**  
Layer decision- and management-oriented capabilities on top of the core engine.

In scope:

- Modules for:
  - Harvest and culling strategies.
  - Translocation/supplementation rules.
  - Simple habitat restoration scenarios.
- Scenario comparison tools:
  - Running multiple management scenarios and comparing:
    - Extinction risk.
    - Time to quasi-extinction.
    - Other relevant metrics.
- Hooks for optimisation and decision analysis:
  - E.g. simple search over discrete management options.

Out of scope (Phase 4):

- Full optimisation frameworks or POMDPs.
- Sophisticated cost–benefit analyses (these can be built externally using OpenPVA outputs).

---

## Phase 5 – Advanced Features and Interfaces

**Goal:**  
Once the core is stable and trusted, extend OpenPVA for broader use and deeper analysis.

Potential directions (not all mandatory):

- Integration with pattern-oriented validation or ensemble modelling (e.g. ideas akin to `poems`).
- More sophisticated genetic models and eco-evolutionary dynamics.
- Model calibration/parameter estimation interfaces (Bayesian, ABC, etc.).
- Shiny-based or other GUIs for non-coding users.
- Teaching-focused vignettes and classroom-friendly interfaces.

These are aspirational and will be scoped in detail once Phases 1–3 are mature.

---

## Current Scope Summary (for contributors and agents)

At present, OpenPVA is in **Phase 1**. That means:

- **In scope right now:**
  - Individual and population representations.
  - Ageing, survival, and basic breeding modules.
  - A minimal birth/offspring module.
  - A simple density feedback implementation.
  - Basic simulation controller(s).
  - Tests, documentation, and `_targets.R` wiring for the above.

- **Out of scope for now:**
  - Genetics modules (design can be discussed, but not implemented wholesale).
  - Spatial structure and dispersal.
  - Decision-support tooling.
  - GUIs and other interfaces.

The priority is to get a **clean, working, well-tested core demographic engine** in place before layering on additional complexity.

If you are about to implement something that clearly belongs to a later phase, pause and either:

- Defer it, or
- Flag it explicitly in an issue or design note for future work.

OpenPVA is intended to grow incrementally and coherently, not as a tangle of half-finished subsystems.
