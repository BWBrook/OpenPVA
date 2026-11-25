# Lord Howe Island woodhen 1980 reconstruction as an ordinary-R OpenPVA model.
# Every process is built through exported OpenPVA constructors.

woodhen_rate_index <- function(parameters) {
  rates <- parameters$vital_rates
  rates$row <- seq_len(nrow(rates))
  OpenPVA::age_sex_rate(rates, "row")
}

woodhen_initial_state <- function(parameters, scenario, pedigree = FALSE) {
  initial <- parameters$initial_population
  rates <- parameters$vital_rates
  population <- OpenPVA::pva_population(
    sex = c(rep("F", sum(initial$females)), rep("M", sum(initial$males))),
    age = c(rep(initial$age, initial$females), rep(initial$age, initial$males)),
    mate_id = NA_integer_
  )
  OpenPVA::pva_state(
    population,
    globals = list(
      cyclone = FALSE,
      woodhen_survival = rates$p_surv,
      woodhen_fecundity = rates$lambda,
      territory_capacity_pairs = as.integer(scenario$territory_capacity_pairs)
    ),
    pedigree = pedigree
  )
}

woodhen_conditions_process <- function(parameters, scenario) {
  rates <- parameters$vital_rates
  environment <- parameters$annual_environment
  shapes <- if (environment$survival_sd > 0) {
    OpenPVA::beta_shapes(rates$p_surv, environment$survival_sd)
  }
  OpenPVA::environment_process(
    name = "annual_conditions",
    variables = list(
      cyclone = function(state, context, params) {
        stats::runif(1L) < params$cyclone_probability
      },
      woodhen_survival = function(state, context, params) {
        survival <- if (is.null(params$shapes)) {
          params$base_survival
        } else {
          # Each age class experiences the same annual percentile in both sexes.
          percentile <- stats::runif(max(params$age_group))
          stats::qbeta(
            percentile[params$age_group],
            params$shapes$shape1,
            params$shapes$shape2
          )
        }
        if (state$globals$cyclone) survival * params$cyclone_survival_multiplier else survival
      },
      woodhen_fecundity = function(state, context, params) {
        fecundity <- params$base_fecundity * exp(stats::rnorm(
          length(params$base_fecundity), -params$fecundity_log_sd^2 / 2, params$fecundity_log_sd
        ))
        if (state$globals$cyclone) fecundity * params$cyclone_fecundity_multiplier else fecundity
      },
      territory_capacity_pairs = function(state, context, params) {
        capacity <- if (params$capacity_sd > 0) {
          round(stats::rnorm(1L, params$capacity, params$capacity_sd))
        } else {
          params$capacity
        }
        as.integer(max(1, capacity))
      }
    ),
    params = list(
      base_survival = rates$p_surv,
      base_fecundity = rates$lambda,
      age_group = match(rates$age_min, sort(unique(rates$age_min))),
      shapes = shapes,
      fecundity_log_sd = environment$fecundity_log_sd,
      cyclone_probability = environment$cyclone_probability,
      cyclone_survival_multiplier = environment$cyclone_survival_multiplier,
      cyclone_fecundity_multiplier = environment$cyclone_fecundity_multiplier,
      capacity = scenario$territory_capacity_pairs,
      capacity_sd = scenario$territory_capacity_sd
    )
  )
}

woodhen_survival_process <- function(parameters) {
  OpenPVA::survival_process(
    probability = function(pop, state, context, params) {
      state$globals$woodhen_survival[params$rate_index(pop, state, context, params)]
    },
    cause = "natural_or_environmental",
    requires = c("population.age", "population.sex", "globals.woodhen_survival"),
    params = list(rate_index = woodhen_rate_index(parameters))
  )
}

woodhen_territory_process <- function(parameters, priority = "id") {
  OpenPVA::pairing_process(
    name = "territory_allocation",
    eligible = function(pop, state, context, params) {
      pop$age >= params$minimum_breeding_age
    },
    capacity = function(state, context, params) {
      state$globals$territory_capacity_pairs
    },
    priority = priority,
    field = "mate_id",
    requires = c("population.age", "globals.territory_capacity_pairs"),
    params = list(minimum_breeding_age = parameters$minimum_breeding_age)
  )
}

woodhen_reproduction_process <- function(parameters) {
  OpenPVA::reproduction_process(
    breeding_probability = function(pop, state, context, params) {
      as.numeric(!is.na(pop$mate_id))
    },
    litter_size = OpenPVA::litter_poisson(function(pop, state, context, params) {
      state$globals$woodhen_fecundity[params$rate_index(pop, state, context, params)]
    }),
    offspring_sex = OpenPVA::offspring_sex_bernoulli(
      parameters$offspring_female_probability
    ),
    mate = OpenPVA::mate_from_field("mate_id"),
    require_mate = TRUE,
    newborn_fields = function(mothers, fathers, pop, state, context, params) {
      list(mate_id = NA_integer_)
    },
    newborn_field_names = "mate_id",
    requires = c(
      "population.age", "population.mate_id", "globals.woodhen_fecundity"
    ),
    params = list(rate_index = woodhen_rate_index(parameters))
  )
}

woodhen_capture_process <- function(parameters) {
  OpenPVA::removal_process(
    name = "scheduled_capture",
    select = function(pop, state, context, params) {
      if (!(context$time %in% params$times)) {
        return(integer())
      }
      adult <- pop$age >= params$minimum_age
      females <- which(adult & pop$sex == "F")
      males <- which(adult & pop$sex == "M")
      pairs <- min(params$pairs_per_time, length(females), length(males))
      c(females[seq_len(pairs)], males[seq_len(pairs)])
    },
    cause = "captive_breeding_capture",
    requires = c("population.age", "population.sex"),
    params = parameters$capture
  )
}

woodhen_release_process <- function(parameters) {
  release <- parameters$release
  OpenPVA::introduction_process(
    name = "captive_release",
    count = function(state, context, params) {
      if (context$time %in% params$times) 2L * params$pairs_per_time else 0L
    },
    fields = function(n, state, context, params) {
      list(
        sex = rep(c("F", "M"), length.out = n),
        age = as.integer(params$age),
        mate_id = NA_integer_
      )
    },
    creates = c("sex", "age", "mate_id"),
    source = release$source,
    params = release
  )
}

woodhen_census_process <- function(parameters) {
  OpenPVA::census_process(
    metrics = function(pop, state, context, params) {
      adult <- pop$age >= params$minimum_breeding_age
      paired <- !is.na(pop$mate_id)
      c(
        n_alive = length(pop$id),
        n_female = sum(pop$sex == "F"),
        n_male = sum(pop$sex == "M"),
        n_juvenile = sum(pop$age == 0L),
        n_breeding_age_pairs = min(sum(adult & pop$sex == "F"), sum(adult & pop$sex == "M")),
        n_potential_pairs = sum(paired & pop$sex == "F"),
        n_adult_floaters = sum(adult & !paired),
        territory_capacity_pairs = state$globals$territory_capacity_pairs,
        cyclone = as.numeric(state$globals$cyclone)
      )
    },
    requires = c(
      "population.age", "population.mate_id",
      "globals.territory_capacity_pairs", "globals.cyclone"
    ),
    params = list(minimum_breeding_age = parameters$minimum_breeding_age)
  )
}

woodhen_processes <- function(parameters, scenario) {
  processes <- list(
    woodhen_conditions_process(parameters, scenario),
    woodhen_survival_process(parameters),
    OpenPVA::age_process(),
    woodhen_territory_process(parameters),
    woodhen_reproduction_process(parameters)
  )
  if (isTRUE(scenario$capture)) {
    processes <- c(processes, list(woodhen_capture_process(parameters)))
  }
  if (isTRUE(scenario$release)) {
    processes <- c(processes, list(woodhen_release_process(parameters)))
  }
  c(processes, list(woodhen_census_process(parameters)))
}

woodhen_build_scenario <- function(
    scenario_id,
    n_runs = NULL,
    seed = NULL,
    parameters = woodhen_parameters(),
    pedigree = FALSE) {
  woodhen_validate_parameters(parameters)
  scenario <- as.list(
    parameters$scenarios[parameters$scenarios$scenario_id == scenario_id, , drop = FALSE]
  )
  if (!length(scenario$scenario_id)) {
    stop("unknown Woodhen scenario: ", scenario_id, call. = FALSE)
  }
  OpenPVA::scenario_spec(
    name = paste0("woodhen_", scenario_id),
    n_runs = if (is.null(n_runs)) parameters$default_n_runs else n_runs,
    n_steps = parameters$n_steps,
    init_fun = function() woodhen_initial_state(parameters, scenario, pedigree),
    processes = woodhen_processes(parameters, scenario),
    seed = if (is.null(seed)) scenario$seed else seed,
    initial_census = woodhen_census_process(parameters)
  )
}
