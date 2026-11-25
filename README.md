# OpenPVA

OpenPVA 2.0.0 is a modular, individual-based engine for population viability
analysis in R. A model specifies a population, the order of biological processes
within each interval, and the census that defines the risk endpoint. Processes
declare the fields they read, write and create. The engine assigns individual
IDs, tracks parentage, reconciles population changes and allocates a
reproducible random stream to each replicate.

Install from this checkout with `R CMD INSTALL .`. The package uses base and
recommended R packages and supports R 4.1.0 and later.

## What the engine provides

- A columnar population of living individuals (`pva_population()`,
  `pva_state()`), with the dead moved to an optional ledger.
- One generic execution loop with strict validation after every process:
  declared writes, field types, engine-owned fields, and accounting reconciled
  separately for existing and newly created individuals, by cohort.
- Exact pedigree inbreeding from recorded parentage, including a known sire
  lost after mating. Above the dense slot limit the engine traces ancestors of
  the breeders, retaining any specified starting kinships.
- One preassigned L'Ecuyer-CMRG stream per replicate: results are bit-identical
  on one core, on fork workers and on a PSOCK cluster.
- Reusable processes: `age_process()`, `survival_process()`,
  `staged_survival_process()`, `reproduction_process()` with Poisson, bounded
  and categorical litters, `pairing_process()` for mate and territory limits,
  `removal_process()`, `ceiling_process()`, `introduction_process()`,
  `environment_process()`, `catastrophe_process()`,
  `inbreeding_proxy_process()`, dispersal among patches, and `census_process()`.
- Helpers: age-by-sex rate tables, Beverton–Holt, Ricker and ceiling density
  multipliers, lethal-equivalent inbreeding depression.
- `run_scenario()`, `summarise_pva()` (first-crossing and horizon risk, time to
  threshold and final abundance with Monte Carlo standard errors),
  `summarise_trajectory()`, `summarise_accounting()` and `run_pva_ensemble()`,
  which separates a structural, parametric and management design from the inner
  Monte Carlo replicates.

## A minimal model

```r
library(OpenPVA)

survival <- survival_process(
  probability = function(pop, state, context, params) {
    ifelse(pop$age == 0, params$juvenile, params$adult)
  },
  requires = "population.age",
  params = list(juvenile = 0.5, adult = 0.9)
)

breeding <- reproduction_process(
  breeding_probability = function(pop, state, context, params) as.numeric(pop$age >= 2),
  litter_size = litter_poisson(1.2),
  offspring_sex = offspring_sex_bernoulli(0.5),
  mate = mate_random(function(pop, state, context, params) pop$age >= 2),
  requires = "population.age"
)

scenario <- scenario_spec(
  name = "minimal-example",
  n_runs = 200,
  n_steps = 20,
  init_fun = function() pva_population(sex = rep(c("F", "M"), 10), age = 3),
  processes = list(survival, age_process(), breeding, census_process()),
  seed = 2026
)

result <- run_scenario(scenario)
summarise_pva(result, threshold = 10)
all(summarise_accounting(result)$reconciled)
```

These illustrative rates specify a two-sex model. Each breeding female needs
an eligible male. With `mate = NULL` the model is female-dominant and a
breeding female can produce offspring with an unknown sire. For seasonal
mating, record pairs first and pass `mate_from_field()` at birth; refresh
pairing fields each interval because dead mates from an earlier interval are
rejected. When using `age_sex_rate()`, one-sex tables return `0` for the
omitted sex (intended for female-only fecundity tables; always supply both
sexes for survival tables).

The census follows breeding here, so each interval's abundance includes its
newborns. Supply `initial_census = census_process()` to count year zero as
well. Both risk summaries use the same observations and check the schedule
against the full replicate design. The default run keeps census, events and
accounting. Request `keep = c("census", "state", "ledger")` to inspect the
survivors and individual histories.

## A project-defined process

Anything that satisfies the contract composes with the built-in processes; no
registration is needed.

```r
harvest_oldest <- pva_process(
  name = "harvest_oldest",
  run = function(state, context, params) {
    oldest <- which.max(state$population$age)
    state$population$alive[oldest] <- FALSE
    pva_result(state, pva_events("removal", length(oldest), "harvest"))
  },
  requires = "population.age",
  writes = "population.alive"
)
```

If that process forgot its `removal` event, or changed a field it did not
declare, strict validation would stop the run and name the process.

## Species examples

- Follow a breeding female through summer mating, autumn harvest, winter birth
  and three years of maternal care. This example links adult-female mortality
  to cub survival and inter-birth intervals. [Grizzly model](inst/examples/grizzly/README.md)
- Compare recovery scenarios with sex-specific survival, shared environmental
  variation, territorial pairs and captive releases. The example provides
  parameters, their evidence and a script that runs on a socket cluster.
  [Lord Howe Island woodhen model](inst/examples/woodhen/README.md)

Both projects use the exported API and include runnable scripts. Their rates
illustrate model construction and management comparisons.

## Development

```sh
Rscript scripts/run_tests.R      # install to a temporary library and run all tests
Rscript scripts/build_rd.R       # regenerate man/*.Rd from scripts/rd_topics.R
R CMD build --no-build-vignettes . && R CMD check --as-cran --no-manual OpenPVA_*.tar.gz
```

Documentation is generated by `scripts/build_rd.R`, which builds every usage
section from the functions' formals, so `roxygen2` is not required.

## Design documents

- [Vision and scope](docs/vision_and_scope.md)
- [Lifecycle-process contract](docs/design/lifecycle_process_contract.md)
- [Public API](docs/reference/public_api.md)
- [GAPPS heritage](docs/gapps_heritage.md) and
  [evidence review](docs/literature/gapps_evidence_review.md)
