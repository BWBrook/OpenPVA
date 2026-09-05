woodhen_rate_rows <- function(parameters, sex = "F") {
  rows <- parameters$vital_rates[parameters$vital_rates$sex == sex, , drop = FALSE]
  rows[order(rows$age_min), , drop = FALSE]
}

woodhen_rate_index <- function(age, n_rates = 7L) {
  pmin(as.integer(age), n_rates - 1L) + 1L
}

woodhen_beta_shapes <- function(probabilities, standard_deviation) {
  if (standard_deviation == 0) {
    return(NULL)
  }
  variance <- standard_deviation^2
  denominator <- probabilities * (1 - probabilities) / variance - 1
  alpha <- probabilities * denominator
  beta <- (1 - probabilities) * denominator
  if (any(alpha <= 0 | beta <= 0)) {
    stop("survival_sd is incompatible with at least one survival probability", call. = FALSE)
  }
  list(alpha = alpha, beta = beta)
}

woodhen_allocate_territories <- function(
    population,
    capacity,
    minimum_breeding_age = 1L) {
  for (index in seq_along(population)) {
    population[[index]]$territory_holder <- FALSE
  }
  eligible <- vapply(population, function(individual) {
    isTRUE(individual$alive) && individual$age >= minimum_breeding_age
  }, logical(1))
  sexes <- vapply(population, `[[`, character(1), "sex")
  ids <- vapply(population, `[[`, integer(1), "id")
  females <- which(eligible & sexes == "F")
  males <- which(eligible & sexes == "M")
  females <- females[order(ids[females])]
  males <- males[order(ids[males])]
  assigned_pairs <- min(as.integer(capacity), length(females), length(males))
  assigned <- if (assigned_pairs > 0L) {
    c(females[seq_len(assigned_pairs)], males[seq_len(assigned_pairs)])
  } else {
    integer()
  }
  for (index in assigned) {
    population[[index]]$territory_holder <- TRUE
  }
  list(
    population = population,
    available_pairs = as.integer(min(length(females), length(males))),
    assigned_pairs = as.integer(assigned_pairs),
    adult_floaters = as.integer(length(females) + length(males) - 2L * assigned_pairs)
  )
}

woodhen_annual_conditions_process <- function(parameters, scenario) {
  female_rates <- woodhen_rate_rows(parameters, "F")
  environment <- parameters$annual_environment
  shapes <- woodhen_beta_shapes(female_rates$p_surv, environment$survival_sd)

  OpenPVA::pva_process(
    name = "annual_conditions",
    run = function(state, context, params) {
      survival <- if (is.null(params$shapes)) {
        params$base_survival
      } else {
        stats::rbeta(
          length(params$base_survival),
          params$shapes$alpha,
          params$shapes$beta
        )
      }
      fecundity <- params$base_fecundity * exp(stats::rnorm(
        length(params$base_fecundity),
        mean = 0,
        sd = params$fecundity_log_sd
      ))
      cyclone <- stats::runif(1L) < params$cyclone_probability
      if (cyclone) {
        survival <- survival * params$cyclone_survival_multiplier
        fecundity <- fecundity * params$cyclone_fecundity_multiplier
      }
      capacity <- if (params$capacity_sd > 0) {
        round(stats::rnorm(1L, params$capacity, params$capacity_sd))
      } else {
        params$capacity
      }
      capacity <- as.integer(max(1, capacity))

      state$globals$woodhen_survival <- survival
      state$globals$woodhen_fecundity <- fecundity
      state$globals$territory_capacity_pairs <- capacity
      state$globals$cyclone <- cyclone
      OpenPVA::pva_result(
        state,
        list(list(
          event_type = "annual_conditions",
          territory_capacity_pairs = capacity,
          cyclone = cyclone,
          mean_survival = mean(survival),
          mean_fecundity = mean(fecundity)
        ))
      )
    },
    params = list(
      base_survival = female_rates$p_surv,
      base_fecundity = female_rates$lambda,
      shapes = shapes,
      fecundity_log_sd = environment$fecundity_log_sd,
      cyclone_probability = environment$cyclone_probability,
      cyclone_survival_multiplier = environment$cyclone_survival_multiplier,
      cyclone_fecundity_multiplier = environment$cyclone_fecundity_multiplier,
      capacity = scenario$territory_capacity_pairs[[1L]],
      capacity_sd = scenario$territory_capacity_sd[[1L]]
    ),
    writes = c(
      "globals.woodhen_survival",
      "globals.woodhen_fecundity",
      "globals.territory_capacity_pairs",
      "globals.cyclone"
    ),
    description = "Draw shared annual Woodhen conditions before demography."
  )
}

woodhen_initial_population <- function(parameters) {
  records <- list()
  next_id <- 1L
  for (row in seq_len(nrow(parameters$initial_population))) {
    age <- parameters$initial_population$age[[row]]
    for (sex in c("F", "M")) {
      count_field <- if (sex == "F") "females" else "males"
      count <- parameters$initial_population[[count_field]][[row]]
      if (!count) {
        next
      }
      for (index in seq_len(count)) {
        individual <- OpenPVA::create_individual(next_id, sex, age)
        individual$territory_holder <- FALSE
        records[[length(records) + 1L]] <- individual
        next_id <- next_id + 1L
      }
    }
  }
  records
}

woodhen_initial_state <- function(parameters, scenario) {
  female_rates <- woodhen_rate_rows(parameters, "F")
  capacity <- as.integer(scenario$territory_capacity_pairs[[1L]])
  initial <- woodhen_allocate_territories(
    woodhen_initial_population(parameters),
    capacity
  )
  OpenPVA::pva_state(
    initial$population,
    globals = list(
      woodhen_survival = female_rates$p_surv,
      woodhen_fecundity = female_rates$lambda,
      territory_capacity_pairs = capacity,
      cyclone = FALSE
    )
  )
}

woodhen_territory_process <- function() {
  OpenPVA::pva_process(
    name = "territory_allocation",
    run = function(state, context, params) {
      allocation <- woodhen_allocate_territories(
        state$population,
        state$globals$territory_capacity_pairs,
        params$minimum_breeding_age
      )
      state$population <- allocation$population
      OpenPVA::pva_result(state, list(list(
        event_type = "territory_allocation",
        available_pairs = allocation$available_pairs,
        assigned_pairs = allocation$assigned_pairs,
        adult_floaters = allocation$adult_floaters
      )))
    },
    params = list(minimum_breeding_age = 1L),
    requires = c(
      "population.id", "population.sex", "population.age", "population.alive",
      "population.territory_holder", "globals.territory_capacity_pairs"
    ),
    writes = "population.territory_holder",
    description = "Assign annual breeding territories without deleting floaters."
  )
}

woodhen_mating <- function(population, mother, context, params) {
  eligible <- function(individual, sex) {
    isTRUE(individual$alive) && identical(individual$sex, sex) &&
      individual$age >= params$minimum_breeding_age &&
      isTRUE(individual$territory_holder)
  }
  females <- Filter(function(individual) eligible(individual, "F"), population)
  males <- Filter(function(individual) eligible(individual, "M"), population)
  females <- females[order(vapply(females, `[[`, integer(1), "id"))]
  males <- males[order(vapply(males, `[[`, integer(1), "id"))]
  female_ids <- vapply(females, `[[`, integer(1), "id")
  rank <- match(mother$id, female_ids)
  if (is.na(rank) || rank > length(males)) NULL else males[[rank]]
}

woodhen_reproduction_process <- function(parameters) {
  rates <- parameters$vital_rates
  breeding_lookup <- OpenPVA::build_breeding_prob_fun_from_table(
    rates[c("age_min", "age_max", "sex", "p_breed")]
  )

  OpenPVA::reproduction_process(
    name = "reproduction",
    breeding_probability = function(mother, state, context, params) {
      if (!isTRUE(mother$territory_holder)) {
        return(0)
      }
      params$breeding_lookup(mother)
    },
    fecundity_mean = function(mother, state, context, params) {
      index <- woodhen_rate_index(mother$age)
      state$globals$woodhen_fecundity[[index]]
    },
    mating = woodhen_mating,
    require_mate = TRUE,
    offspring_sex = function(mother, father, state, context, params) {
      if (stats::runif(1L) < params$female_probability) "F" else "M"
    },
    newborn_initializer = function(mother, father, state, context, params) {
      list(territory_holder = FALSE)
    },
    initializer_fields = "territory_holder",
    requires = c(
      "population.age", "globals.woodhen_fecundity",
      "population.territory_holder"
    ),
    params = list(
      breeding_lookup = breeding_lookup,
      minimum_breeding_age = 1L,
      female_probability = parameters$offspring_female_probability
    )
  )
}

woodhen_survival_process <- function() {
  OpenPVA::survival_process(
    name = "survival",
    probability = function(individual, state, context, params) {
      state$globals$woodhen_survival[[woodhen_rate_index(individual$age)]]
    },
    requires = c("population.age", "globals.woodhen_survival"),
    cause = "natural_or_environmental"
  )
}

woodhen_capture_process <- function(parameters) {
  OpenPVA::pva_process(
    name = "scheduled_capture",
    run = function(state, context, params) {
      if (!context$time %in% params$times) {
        return(OpenPVA::pva_result(state))
      }
      eligible <- function(individual, sex) {
        isTRUE(individual$alive) && identical(individual$sex, sex) &&
          individual$age >= params$minimum_age
      }
      females <- Filter(function(individual) eligible(individual, "F"), state$population)
      males <- Filter(function(individual) eligible(individual, "M"), state$population)
      females <- females[order(vapply(females, `[[`, integer(1), "id"))]
      males <- males[order(vapply(males, `[[`, integer(1), "id"))]
      realised_pairs <- min(params$pairs_per_time, length(females), length(males))
      selected <- if (realised_pairs > 0L) {
        c(
          vapply(females[seq_len(realised_pairs)], `[[`, integer(1), "id"),
          vapply(males[seq_len(realised_pairs)], `[[`, integer(1), "id")
        )
      } else {
        integer()
      }
      if (length(selected)) {
        for (index in seq_along(state$population)) {
          if (state$population[[index]]$id %in% selected) {
            state$population[[index]]$alive <- FALSE
          }
        }
      }
      events <- list(list(
        event_type = "capture_attempt",
        requested_pairs = as.integer(params$pairs_per_time),
        realised_pairs = as.integer(realised_pairs),
        shortfall_pairs = as.integer(params$pairs_per_time - realised_pairs)
      ))
      if (length(selected)) {
        events[[2L]] <- list(
          event_type = "removal",
          value = as.integer(length(selected)),
          cause = "captive_breeding_capture"
        )
      }
      OpenPVA::pva_result(state, events)
    },
    params = parameters$capture,
    requires = c(
      "population.id", "population.sex", "population.age", "population.alive"
    ),
    writes = "population.alive",
    description = "Capture scheduled living female-male pairs for captive breeding."
  )
}

woodhen_release_process <- function(parameters) {
  release <- parameters$release
  OpenPVA::introduction_process(
    name = "captive_release",
    count = function(state, context, params) {
      if (context$time %in% params$times) 2L * params$pairs_per_time else 0L
    },
    initializer = function(index, id, state, context, params) {
      list(
        sex = if (index %% 2L == 1L) "F" else "M",
        age = as.integer(params$age),
        mother_id = NA_integer_,
        father_id = NA_integer_,
        territory_holder = FALSE
      )
    },
    initializer_fields = c(
      "sex", "age", "mother_id", "father_id", "territory_holder"
    ),
    source = release$source,
    group_by = "sex",
    params = release
  )
}

woodhen_census_process <- function(parameters) {
  OpenPVA::census_process(
    name = "census",
    summarise = function(state, context, params) {
      alive <- vapply(state$population, function(individual) {
        isTRUE(individual$alive)
      }, logical(1))
      sexes <- vapply(state$population, `[[`, character(1), "sex")
      ages <- vapply(state$population, `[[`, integer(1), "age")
      territory_holders <- vapply(state$population, function(individual) {
        isTRUE(individual$territory_holder)
      }, logical(1))
      adult <- alive & ages >= params$minimum_breeding_age
      females <- sum(adult & sexes == "F")
      males <- sum(adult & sexes == "M")
      holder_females <- sum(adult & territory_holders & sexes == "F")
      holder_males <- sum(adult & territory_holders & sexes == "M")
      list(
        n_alive = as.integer(sum(alive)),
        n_female_alive = as.integer(sum(alive & sexes == "F")),
        n_male_alive = as.integer(sum(alive & sexes == "M")),
        n_juvenile = as.integer(sum(alive & ages == 0L)),
        n_breeding_age_pairs = as.integer(min(females, males)),
        n_potential_pairs = as.integer(min(holder_females, holder_males)),
        n_adult_floaters = as.integer(
          females + males - holder_females - holder_males
        ),
        territory_capacity_pairs = as.integer(
          state$globals$territory_capacity_pairs
        ),
        cyclone = isTRUE(state$globals$cyclone),
        calendar_year = as.integer(
          if (context$phase == "initial") params$start_year else
            params$start_year + context$time + 1L
        )
      )
    },
    requires = c(
      "population.id", "population.sex", "population.age", "population.alive",
      "population.territory_holder",
      "globals.territory_capacity_pairs", "globals.cyclone"
    ),
    params = list(
      minimum_breeding_age = 1L,
      start_year = parameters$start_year
    )
  )
}

woodhen_scenario_ids <- function(parameters = woodhen_parameters()) {
  as.character(parameters$scenarios$scenario_id)
}

woodhen_build_scenario <- function(
    scenario_id,
    n_runs = NULL,
    seed = NULL,
    parameters = woodhen_parameters()) {
  woodhen_validate_parameters(parameters)
  scenario <- parameters$scenarios[
    parameters$scenarios$scenario_id == scenario_id,
    ,
    drop = FALSE
  ]
  if (nrow(scenario) != 1L) {
    stop("unknown Woodhen scenario: ", scenario_id, call. = FALSE)
  }
  if (is.null(n_runs)) {
    n_runs <- parameters$default_n_runs
  }
  if (is.null(seed)) {
    seed <- scenario$seed[[1L]]
  }

  census <- woodhen_census_process(parameters)
  processes <- list(
    woodhen_annual_conditions_process(parameters, scenario),
    woodhen_survival_process(),
    OpenPVA::age_process(),
    woodhen_territory_process(),
    woodhen_reproduction_process(parameters)
  )
  if (isTRUE(scenario$capture[[1L]])) {
    processes[[length(processes) + 1L]] <- woodhen_capture_process(parameters)
  }
  if (isTRUE(scenario$release[[1L]])) {
    processes[[length(processes) + 1L]] <- woodhen_release_process(parameters)
  }
  processes[[length(processes) + 1L]] <- census

  OpenPVA::scenario_spec(
    name = paste0("woodhen_", scenario_id),
    n_runs = n_runs,
    n_steps = parameters$n_steps,
    init_fun = function() woodhen_initial_state(parameters, scenario),
    processes = processes,
    seed = seed,
    initial_census = census,
    record_population_history = FALSE
  )
}
