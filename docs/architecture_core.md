# OpenPVA Core Architecture

This document describes the **core architectural concepts** of OpenPVA. It is intended for developers, contributors, and automated coding agents working inside the repository.

The goal is to ensure that any new code aligns with the intended mental model of how OpenPVA works.

---

## High-Level Design

OpenPVA is structured as a **modular simulation engine** implemented in R. At the highest level, it consists of:

- **State objects**: individuals and populations
- **Lifecycle process modules**: functions that transform population state
- **Simulation controller**: orchestrates processes through time
- **Pipelines and environment management**: `targets` for workflows, `renv` for reproducibility

Everything else (genetics, spatial structure, management, validation) is layered on top of this core.

---

## Core Concepts

### 1. Individual

An **individual** is the basic unit of simulation in OpenPVA. In the initial implementation, individuals are represented as **named lists** with standard fields:

- `id` — unique integer identifier
- `sex` — character, typically `"M"` or `"F"`
- `age` — integer, age in years or time steps
- `alive` — logical, living status
- `alleles` — `NULL` or a 2 × L integer matrix representing two haplotypes across L loci
- `F` — numeric inbreeding coefficient, computed as \(1 -\) heterozygosity when `alleles` exist (may be `NA` otherwise; missing values are treated as zero by default)
- `patch_id` — integer or `NA`, indicating the spatial patch membership used by spatial/density modules

Example (conceptual):

```r
ind <- list(
  id = 1L,
  sex = "F",
  age = 4L,
  alive = TRUE,
  alleles = rbind(
    c(1L, 2L, 1L),
    c(2L, 1L, 2L)
  ),
  F = 0
)
```

Lists are chosen for **flexibility and simplicity**. Later implementations may layer S3/R6 classes or alternative backends on top of this representation, but all code should treat individuals as **opaque objects with a documented interface**, not as rigid class instances.

Individuals lacking genotype data may have `F` set to `NA` (or 0). Inbreeding-aware survival helpers interpret missing values as zero, ensuring legacy demographic runs remain unaffected until genetics are explicitly enabled.

---

### 2. Population

A **population** is a collection of individuals, typically a list of individual objects:

```r
population <- list(ind1, ind2, ind3, ...)
```

Later, we may support alternative representations (e.g. tibbles, data.tables) as long as they satisfy the same conceptual interface. Lifecycle modules should treat “population” as:

- A mutable object representing all individuals at a given time
- The **input and output** of lifecycle process functions

In more complex models, populations may also carry **metadata** (e.g. spatial patch membership, global counters, tracking variables), implemented as attributes or as a higher-level wrapper (e.g. a list with `individuals` and `meta` slots).

---

### 3. Lifecycle Process Modules

Lifecycle processes are the **heart** of OpenPVA. Each process is implemented as a function (or small family of functions) that:

- Takes a **population state** (and possibly other parameters) as input
- Returns a **modified population state** as output
- Is conceptually responsible for *one* part of the life cycle

Examples of lifecycle processes include:

- `age_individuals()` — increments age for all living individuals
- `apply_survival()` — updates `alive` status based on a survival probability function
- `determine_breeding()` — identifies breeding-eligible individuals
- Future: `apply_reproduction()`, `apply_dispersal()`, `apply_harvest()`, `apply_genetic_update()`, etc.

Design principles for lifecycle modules:

- **Single responsibility**: each function should modify one aspect of the population state.
- **Composability**: modules should be easy to sequence in different orders.
- **Purity where feasible**: minimise side effects. A lifecycle module should not write files, plot figures, or alter global state.

All IO, plotting, and reporting should be handled in higher-level scripts or `targets` pipelines, *not* inside lifecycle modules.

---

### 4. Simulation Controller (Scheduler)

The simulation controller is responsible for stepping the model forward in time. Conceptually:

1. Initialise the population at time `t = 0`
2. For each time step:
   - Apply lifecycle processes in a defined order
   - Record summary statistics if required
   - Update time and continue until stopping conditions are met

At a code level, this can be implemented as a function that takes:

- An initial population
- A list or sequence of lifecycle modules
- Simulation parameters (number of runs, time horizon, random seeds, etc.)

For example (conceptual pseudocode):

```r
run_simulation <- function(population, processes, n_years, ...) {
  for (year in seq_len(n_years)) {
    for (process in processes) {
      population <- process(population, ...)
    }
    # optional: record metrics here
  }
  population
}
```

In practice, simulations may be orchestrated by **targets pipelines**, with each simulation run built as a target.

---

### 5. Demography, Genetics, Spatial Modules

These are not different “kinds” of engines, but **modules acting on the same population state**.

- **Demographic modules**: ageing, survival, reproduction, density dependence, catastrophes, harvest, supplementation.
- **Genetic modules**: assign alleles, calculate inbreeding coefficients, model genetic drift and diversity, apply inbreeding depression.
- **Spatial modules**: assign individuals to patches or coordinates, model dispersal, apply spatial variation in vital rates.

Density feedback can now be specified either as a single global carrying capacity (`K`) or as per-patch capacities (`K_patches`). Patch-level regulation uses each individual's `patch_id` to apply independent survival scaling within each patch, while the global `survival_scale` summary is set to `NA` because no single value applies.

Spatial processes now include a dispersal module (`apply_dispersal()`) that updates `patch_id` based on a `dispersal_fun`. The lifecycle pipeline accepts an optional `"dispersal"` step, allowing users to place movement anywhere in the yearly sequence.

Management-facing helpers expose extinction probabilities (including quasi-extinction thresholds), harvest yields, and a simple `compare_scenarios()` wrapper so different strategies can be evaluated side by side using common decision metrics.

Supplementation/translocation is modelled as an optional "supplementation" lifecycle step that adds individuals via `apply_supplementation()`, with per-year quotas threaded through controllers and scenarios for basic rescue experiments.

Each of these modules should follow the same core interface: operate on a population, return a modified population, and avoid side effects.

We will progressively build these modules in phases. Early development focuses on **demography**, with genetics and spatial structure layered in afterwards.

---

## Pipelines, Reproducibility, and Environment Management

OpenPVA is designed to be used within **reproducible pipelines** rather than as ad hoc script fragments.

### 1. `renv`: Environment Management

The R package **renv** is used to pin package versions and ensure that simulations can be reproduced on other machines.

- `bootstrap_env.R` is the *only* place that should call `renv::init()` or install packages.
- Package dependencies should be declared there and tracked via `renv.lock`.
- Package code should never call `install.packages()` or perform environment management.

### 2. `targets`: Pipeline Orchestration

The **targets** package is used to define declarative workflows:

- `_targets.R` declares targets for:
  - Reading input data
  - Initialising populations
  - Running simulations
  - Summarising and plotting outputs
- Lifecycle modules and simulation controllers are called from within targets, not the other way around.
- `targets::tar_make()` runs the pipeline and caches results.

This approach ensures:

- Clear dependency graphs
- Automatic caching and incremental recomputation
- Reproducibility via `renv` + `targets`

---

## Extensibility and Plugin Design

OpenPVA is intended as a **framework**, not a closed codebase. Contributors should be able to:

- Add new lifecycle modules (e.g. a new survival function with environmental covariates)
- Add new simulation controllers (e.g. alternative scheduling strategies)
- Add new analysis modules (e.g. extinction risk summaries, sensitivity analyses)

To support this:

- Core modules live in `R/` with clear, minimal APIs.
- New modules should:
  - Take and return standard population objects
  - Accept parameters as arguments, not via global state
  - Be documented and tested
- Where sensible, we may define **interfaces** (e.g. function signatures, expected fields) for particular kinds of modules, so that multiple implementations can be used interchangeably.

An example pattern is to treat each process as a function of the form:

```r
process(population, params, state)
```

Where:

- `population` is the current population object
- `params` is a list of static parameters
- `state` is a list of dynamic variables shared across processes (e.g. year index, global counters)

We will refine this interface as the engine matures.

---

## Summary: How to Think About the Architecture

When working in OpenPVA:

- Think in terms of **population state** and **processes** that transform it.
- Keep lifecycle logic **modular** and **explicit**.
- Let `targets` handle workflow orchestration, and `renv` handle environments.
- Avoid IO and side effects inside core modules.
- Design new code so that others can read it, swap it out, and build on it.

This architecture aims to capture the spirit of GAPPS—flexible, declarative, individual-based PVA—while grounding it in modern, open, and reproducible R practice.
