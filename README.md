# OpenPVA

OpenPVA is a programmable, inspectable population-viability engine for R.

> The modeller defines the biological program; OpenPVA supplies the execution
> engine, reusable processes, scientific contracts, and reproducible analysis
> machinery.

The project is being realigned as a modern open-R descendant of GAPPS. A model
is a direct ordered list of ordinary R process objects. Processes can be added,
removed, repeated or reordered without editing the controller.

## Current Core

The Stage 1 runtime provides:

- validated `pva_state`, `pva_process` and `pva_result` objects;
- one generic ordered execution loop;
- explicit field dependencies and newborn/introduction field declarations;
- engine-stamped events and exact population accounting;
- stable IDs and engine-owned `next_id` allocation;
- explicit interval and initial-census timing;
- independently assigned L'Ecuyer-CMRG replicate streams with caller RNG
  restoration and serial/fork identity;
- minimal age, survival, reproduction, global-density snapshot and census
  process constructors;
- a pure ceiling-style global density multiplier for explicit composition in
  modeller-owned vital-rate callbacks;
- an explicitly uncalibrated canonical grizzly-like benchmark with baseline,
  female-survival, targeted human-mortality and immigration scenarios;
- replicate-preserving abundance, event, threshold, growth and provenance
  summaries from `run_grizzly_benchmark()`.

The source-labelled `grizzly_density_extension_scenario()` demonstrates global
density feedback without adding an empirical carrying-capacity default or
changing the five canonical scenarios. Spatial, genetic and management helpers
remain future process-migration sources. YAML,
uncertainty/calibration execution, `targets` and Quarto reconnection are
deliberately not active runtime interfaces during this clean break.

## Development Setup

```r
source("bootstrap_env.R")
renv::restore()
```

For ordinary development:

```r
pkgload::load_all()
testthat::test_dir("tests/testthat")
```

## Minimal Process Program

```r
pkgload::load_all(quiet = TRUE)

population <- list(
  create_individual(1L, "F", age = 4L),
  create_individual(2L, "M", age = 5L)
)

processes <- list(
  age_process(),
  survival_process(
    probability = function(individual, state, context, params) {
      params$annual_survival
    },
    requires = "population.age",
    params = list(annual_survival = 0.9)
  ),
  reproduction_process(
    breeding_probability = function(mother, state, context, params) 0.5,
    fecundity_mean = function(mother, state, context, params) 1.2
  ),
  census_process()
)

scenario <- scenario_spec(
  name = "minimal-example",
  n_runs = 10L,
  n_steps = 20L,
  init_fun = function() population,
  processes = processes,
  seed = 2026L
)

result <- run_scenario(scenario)
result$sim_output$census
result$sim_output$events
```

These values are an API example, not biological defaults for any species.

## Community Process

A project-defined observer composes through the same public contract:

```r
female_observer <- pva_process(
  name = "female_observer",
  run = function(state, context, params) {
    n_female <- sum(vapply(
      state$population,
      function(ind) isTRUE(ind$alive) && identical(ind$sex, "F"),
      logical(1)
    ))
    pva_result(
      state,
      list(list(event_type = "observation", value = n_female))
    )
  },
  requires = c("population.sex", "population.alive")
)
```

Insert `female_observer` anywhere in `processes`; no OpenPVA controller change
or registration is required.

## Architecture

- [Vision and scope](docs/vision_and_scope.md)
- [Core architecture](docs/architecture_core.md)
- [Lifecycle-process contract](docs/design/lifecycle_process_contract.md)
- [Canonical grizzly reference model](docs/design/canonical_grizzly_reference_model.md)
- [Global density feedback](docs/design/density_module.md)
- [Goal 003 benchmark packet](docs/goals/003-canonical-grizzly-benchmark/Goal.md)
- [Goal 004 density packet](docs/goals/004-global-density-feedback/Goal.md)
- [Living plan](docs/plan.md)

## Validation

```sh
Rscript scripts/run_tests.R
```

Release builds, Quarto and workflow automation have separate validation and
publication gates.
