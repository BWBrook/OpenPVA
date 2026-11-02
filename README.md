# OpenPVA

> **Status:** developed in the open as a working record. This is work in progress: contents may change, and nothing here is peer-reviewed unless stated.

OpenPVA is a programmable, inspectable population-viability engine for R.

> The modeller defines the biological program; OpenPVA supplies the execution
> engine, reusable processes, scientific contracts, and reproducible analysis
> machinery.

The project is being realigned as a modern open-R descendant of GAPPS. A model
is a direct ordered list of ordinary R process objects. Processes can be added,
removed, repeated or reordered without editing the controller.

## Current Core

The current runtime provides:

- validated `pva_state`, `pva_process` and `pva_result` objects;
- one generic ordered execution loop;
- explicit field dependencies and newborn/introduction field declarations;
- engine-stamped events and exact population accounting;
- stable IDs and engine-owned `next_id` allocation;
- explicit interval and initial-census timing;
- independently assigned L'Ecuyer-CMRG replicate streams with caller RNG
  restoration and serial/fork identity;
- minimal age, survival, reproduction, generic introduction,
  global/patch-density snapshot, simultaneous dispersal and census process
  constructors;
- pure global and strict keyed patch-density multipliers for explicit
  composition in modeller-owned vital-rate callbacks;
- an explicitly uncalibrated canonical grizzly-like benchmark with baseline,
  female-survival, targeted human-mortality and immigration scenarios;
- replicate-preserving abundance, event, threshold, growth and provenance
  summaries from `run_grizzly_benchmark()`;
- a standalone Lord Howe Island woodhen model project that consumes only the
  installed public package surface.

The source-labelled `grizzly_density_extension_scenario()` demonstrates global
density feedback without adding an empirical carrying-capacity default or
changing the five canonical scenarios. Discrete patch transitions now use
explicit domains and event-first evidence. Exogenous immigration,
supplementation, stocking and translocation use one source-labelled creator
with modeller-owned counts and newcomer state. Optional pedigree ancestry uses
exact conditional-IBD coefficients, explicit founder/parentage declarations
and the same creator seam; marker genetics and harvest/removal remain future
process-migration sources. YAML, uncertainty/calibration execution, `targets`
and Quarto are deliberately absent from the active dependencies and scaffold;
Stage 4 may reintroduce each only with an executable consumer.

## External Modeller Example

[`inst/examples/woodhen/`](inst/examples/woodhen/README.md) is the first Stage 4
vertical slice. It is an ordinary-R, source-backed individual model with three
management scenarios, explicit territory occupancy and floaters, parentage,
exact population accounting and reloadable evidence. It is historically
grounded and illustrative, not a calibrated contemporary assessment.

## Development Setup

```r
source("bootstrap_env.R")
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
    fecundity_mean = function(mother, state, context, params) 1.2,
    offspring_sex = function(mother, father, state, context, params) {
      sample(c("F", "M"), 1L)
    }
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
Within one survival or reproduction process, every individual-level callback
sees the same pre-process state and realised changes are staged. Offspring sex
is always an explicit modeller-owned callback; OpenPVA supplies no sex-ratio
default.

## Exogenous Introductions

One explicit creator covers immigration, supplementation, stocking and
exogenous translocation. Every initializer call in one execution sees the same
pre-process state; the engine supplies IDs and `alive = TRUE`.

```r
stocking <- introduction_process(
  count = function(state, context, params) {
    if (context$time == 0L) params$release_count else 0L
  },
  initializer = function(index, id, state, context, params) {
    list(
      sex = params$sexes[[index]],
      age = params$ages[[index]],
      patch_id = params$patch_ids[[index]]
    )
  },
  initializer_fields = c("sex", "age", "patch_id"),
  source = "project release plan v1",
  name = "stocking",
  group_by = "patch_id",
  params = list(
    release_count = 2L,
    sexes = c("F", "M"),
    ages = c(2L, 3L),
    patch_ids = c(1L, 2L)
  )
)
```

These release values are illustrative API inputs, not biological defaults or
management advice. An introduction does not subtract from a donor population.

## Optional Pedigree Ancestry

Pedigree founders are declared explicitly. Assignment by field name replaces
the generic missing parent fields rather than appending duplicates.

```r
female <- create_individual(1L, "F", age = 4L)
male <- create_individual(2L, "M", age = 5L)
founder_fields <- pedigree_founder_fields()
female[names(founder_fields)] <- founder_fields
male[names(founder_fields)] <- founder_fields
population <- initialize_pedigree(list(female, male))

pedigree_birth <- reproduction_process(
  breeding_probability = function(mother, state, context, params) 0.5,
  fecundity_mean = function(mother, state, context, params) 1.2,
  offspring_sex = function(mother, father, state, context, params) "F",
  mating = function(population, mother, context, params) population[[2L]],
  require_mate = TRUE,
  newborn_initializer = function(mother, father, state, context, params) {
    pedigree_newborn_fields(mother, father, state)
  },
  initializer_fields = c("pedigree_status", "pedigree_F"),
  requires = c(
    "population.mother_id", "population.father_id",
    "population.pedigree_status", "population.pedigree_F"
  )
)
```

`pedigree_F` is conditional pedigree IBD, not marker heterozygosity. These
birth values remain illustrative API inputs rather than species defaults.

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
- [Spatial process contract](docs/design/spatial_process_contract.md)
- [Introduction process contract](docs/design/introduction_process_contract.md)
- [Pedigree ancestry contract](docs/design/pedigree_ancestry_contract.md)
- [Goal 003 benchmark packet](docs/goals/003-canonical-grizzly-benchmark/Goal.md)
- [Goal 004 density packet](docs/goals/004-global-density-feedback/Goal.md)
- [Goal 005 spatial packet](docs/goals/005-patch-transitions-density/Goal.md)
- [Goal 006 introductions packet](docs/goals/006-generic-introductions/Goal.md)
- [Goal 007 pedigree packet](docs/goals/007-pedigree-ancestry/Goal.md)
- [Living plan](docs/plan.md)

## Validation

```sh
Rscript scripts/run_tests.R
```

Package release builds have separate acceptance and publication gates. YAML,
`targets` and Quarto workflow reconnection is deferred to Stage 4 and currently
has no dormant package dependency or project scaffold.
