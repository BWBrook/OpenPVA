grizzly_parameters <- function(adult_female_mortality = 0, adult_male_mortality = 0) {
  list(
    weaning_age = 3L, maturity_age = 5L, breeding_probability = 0.7,
    litter_mean = 2, dependent_survival = 0.78, independent_survival = 0.93,
    adult_female_mortality = adult_female_mortality,
    adult_male_mortality = adult_male_mortality
  )
}

grizzly_initial_state <- function() {
  OpenPVA::pva_state(OpenPVA::pva_population(
    sex = c(rep("F", 6L), rep("M", 4L), "F", "M"),
    age = c(rep(6L, 10L), 0L, 0L),
    mother_id = c(rep(NA_integer_, 10L), 1L, 1L),
    father_id = c(rep(NA_integer_, 10L), 7L, 7L),
    mate_id = NA_integer_
  ), pedigree = TRUE)
}

grizzly_summer_mating <- function(parameters) {
  OpenPVA::pva_process(
    name = "summer_mating", params = parameters,
    requires = c("population.age", "population.sex", "population.mother_id"),
    writes = "population.mate_id",
    run = function(state, context, params) {
      pop <- state$population
      carers <- pop$mother_id[pop$age < params$weaning_age]
      mature <- pop$age >= params$maturity_age
      females <- which(mature & pop$sex == "F" & !(pop$id %in% carers))
      males <- which(mature & pop$sex == "M")
      sire <- rep(NA_integer_, length(pop$id))
      if (length(females) && length(males)) {
        sire[females] <- pop$id[males[sample.int(length(males), length(females), replace = TRUE)]]
      }
      state$population$mate_id <- sire
      OpenPVA::pva_result(state, OpenPVA::pva_events("mated_females", sum(!is.na(sire))))
    }
  )
}

grizzly_scenario <- function(parameters = grizzly_parameters(), n_runs = 40L,
                             n_steps = 12L, seed = 1987L, init_fun = grizzly_initial_state) {
  census <- OpenPVA::census_process(
    metrics = function(pop, state, context, params) {
      c(n_alive = length(pop$id), n_dependent = sum(pop$age < params$weaning_age),
        n_adult_female = sum(pop$sex == "F" & pop$age >= params$maturity_age))
    },
    requires = "population.age", params = parameters
  )
  processes <- list(
    OpenPVA::age_process(name = "spring_ageing"),
    OpenPVA::survival_process(
      function(pop, state, context, params) {
        ifelse(pop$age < params$weaning_age, params$dependent_survival, params$independent_survival)
      },
      name = "natural_survival", requires = "population.age", params = parameters
    ),
    grizzly_summer_mating(parameters),
    OpenPVA::survival_process(
      function(pop, state, context, params) {
        1 - ifelse(pop$sex == "F", params$adult_female_mortality, params$adult_male_mortality)
      },
      eligible = function(pop, state, context, params) pop$age >= params$maturity_age,
      name = "autumn_harvest", cause = "harvest",
      requires = c("population.age", "population.sex"), params = parameters
    ),
    OpenPVA::survival_process(
      0, eligible = function(pop, state, context, params) {
        pop$age < params$weaning_age & !(pop$mother_id %in% pop$id)
      },
      name = "orphan_loss", cause = "loss_of_mother",
      requires = c("population.age", "population.mother_id"), params = parameters
    ),
    OpenPVA::reproduction_process(
      name = "winter_birth", breeding_probability = parameters$breeding_probability,
      mate = OpenPVA::mate_from_field(), offspring_sex = OpenPVA::offspring_sex_bernoulli(0.5),
      litter_size = OpenPVA::litter_binomial(3L, parameters$litter_mean, min_size = 1L),
      newborn_fields = function(mothers, fathers, pop, state, context, params) list(mate_id = NA_integer_),
      newborn_field_names = "mate_id"
    ),
    census
  )
  OpenPVA::scenario_spec("grizzly", n_runs, n_steps, init_fun, processes,
                         seed = seed, initial_census = census)
}
