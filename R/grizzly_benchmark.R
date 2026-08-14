#' Construct the illustrative canonical benchmark parameters
#'
#' The values returned here are a synthetic, source-labelled fixture for
#' exercising the process engine. They are deliberately not empirical grizzly
#' values, a calibrated Greater Yellowstone model, a recovery criterion or a
#' sustainable-mortality recommendation.
#'
#' @param horizon Number of annual intervals.
#' @param quasi_extinction_threshold Explicit threshold used by summaries.
#'
#' @return A named list of parameters with units and provenance.
#' @export
grizzly_benchmark_parameters <- function(
    horizon = 12L,
    quasi_extinction_threshold = 4L) {
  horizon <- .normalize_positive_count(horizon, "horizon")
  quasi_extinction_threshold <- .normalize_non_negative_count(
    quasi_extinction_threshold,
    "quasi_extinction_threshold"
  )
  parameters <- list(
    source_label = "OpenPVA synthetic illustrative fixture; not empirical",
    calibrated = FALSE,
    horizon = horizon,
    quasi_extinction_threshold = quasi_extinction_threshold,
    units = list(
      time = "years",
      survival = "annual probability",
      breeding_probability = "probability per eligible female per year",
      fecundity_lambda = "expected offspring per breeding female per year",
      human_mortality = "conditional annual hazard among target individuals alive at process position",
      immigration = "individuals per year"
    ),
    maturity_age = 4L,
    dependency_age = 3L,
    breeding_probability = 0.7,
    fecundity_lambda = 0.8,
    dependent_survival = 0.78,
    male_survival = 0.91,
    female_survival = c(
      baseline = 0.93,
      low = 0.78,
      high = 0.94
    ),
    human_mortality_probability = 0.25,
    human_target_sex = "F",
    human_target_min_age = 5L,
    observation_detection = 0.8,
    immigration_count = 1L,
    immigration_sex = c("M", "F"),
    immigration_age = 4L,
    environmental_modifiers = rep(1, horizon),
    varying_environmental_modifiers = rep(
      c(0.90, 1.05, 0.96, 1.02),
      length.out = horizon
    )
  )
  .validate_grizzly_benchmark_parameters(parameters)
  parameters
}

#' Construct an initial population for the illustrative benchmark
#'
#' @param n_females Number of female individuals.
#' @param n_males Number of male individuals.
#' @param dependent_females Number of dependent females among the females.
#' @param dependent_males Number of dependent males among the males.
#' @param parameters Parameter fixture from [grizzly_benchmark_parameters()].
#'
#' @return A validated [pva_state()].
grizzly_benchmark_initial_state <- function(
    n_females = 6L,
    n_males = 4L,
    dependent_females = 2L,
    dependent_males = 1L,
    parameters = grizzly_benchmark_parameters()) {
  counts <- c(
    n_females = n_females,
    n_males = n_males,
    dependent_females = dependent_females,
    dependent_males = dependent_males
  )
  counts <- vapply(seq_along(counts), function(index) {
    .normalize_non_negative_count(counts[[index]], names(counts)[[index]])
  }, integer(1))
  if (counts[[3L]] > counts[[1L]] || counts[[4L]] > counts[[2L]]) {
    stop("dependent counts cannot exceed the corresponding sex counts", call. = FALSE)
  }
  .validate_grizzly_benchmark_parameters(parameters)

  sexes <- c(rep("F", counts[[1L]]), rep("M", counts[[2L]]))
  dependent <- c(
    seq_len(counts[[1L]]) <= counts[[3L]],
    seq_len(counts[[2L]]) <= counts[[4L]]
  )
  independent_female_ids <- which(sexes == "F" & !dependent)
  care_mother_id <- if (length(independent_female_ids)) {
    as.integer(independent_female_ids[[1L]])
  } else {
    NA_integer_
  }
  population <- lapply(seq_along(sexes), function(index) {
    individual <- create_individual(
      id = index,
      sex = sexes[[index]],
      age = if (dependent[[index]]) 1L else parameters$maturity_age,
      alive = TRUE,
      mother_id = if (dependent[[index]]) care_mother_id else NA_integer_
    )
    individual$dependency <- if (!dependent[[index]]) {
      "independent"
    } else if (individual$age <= 1L) {
      "cub"
    } else {
      "yearling"
    }
    individual$reproductive_status <- "ineligible"
    individual
  })
  pva_state(
    population,
    globals = list(environment_modifier = 1),
    next_id = length(population) + 1L
  )
}

#' Construct the annual environmental process used by the benchmark
#'
#' @param parameters Benchmark parameter fixture.
#' @param varying Whether to use the annual varying modifier vector.
#' @param name Process name.
#'
#' @return A conforming process object.
grizzly_environment_process <- function(
    parameters = grizzly_benchmark_parameters(),
    varying = FALSE,
    name = "environment") {
  .validate_grizzly_benchmark_parameters(parameters)
  if (!is.logical(varying) || length(varying) != 1L || is.na(varying)) {
    stop("varying must be one non-missing logical value", call. = FALSE)
  }
  pva_process(
    name = name,
    params = list(
      values = if (varying) parameters$varying_environmental_modifiers else
        parameters$environmental_modifiers,
      varying = varying
    ),
    run = function(state, context, process_params) {
      values <- process_params$values
      index <- min(context$time + 1L, length(values))
      modifier <- as.numeric(values[[index]])
      state$globals$environment_modifier <- modifier
      pva_result(
        state,
        list(list(event_type = "environment", modifier = modifier))
      )
    },
    requires = "globals.environment_modifier",
    writes = "globals.environment_modifier",
    description = "Set the neutral or annually varying environmental modifier."
  )
}

#' Construct the dependency-transition process
#'
#' @param parameters Benchmark parameter fixture.
#' @param name Process name.
#'
#' @return A conforming process object.
grizzly_dependency_process <- function(
    parameters = grizzly_benchmark_parameters(),
    name = "dependency") {
  .validate_grizzly_benchmark_parameters(parameters)
  pva_process(
    name = name,
    params = list(dependency_age = parameters$dependency_age),
    run = function(state, context, process_params) {
      transitions <- list()
      for (index in seq_along(state$population)) {
        individual <- state$population[[index]]
        if (!isTRUE(individual$alive)) next
        target <- if (individual$age <= 1L) {
          "cub"
        } else if (individual$age == 2L) {
          "yearling"
        } else {
          "independent"
        }
        if (!identical(individual$dependency, target)) {
          state$population[[index]]$dependency <- target
          key <- paste(individual$dependency, target, sep = "->")
          transitions[[key]] <- (transitions[[key]] %||% 0L) + 1L
        }
      }
      events <- lapply(names(transitions), function(key) {
        endpoints <- strsplit(key, "->", fixed = TRUE)[[1L]]
        list(
          event_type = "dependency_transition",
          value = as.integer(transitions[[key]]),
          from = endpoints[[1L]],
          to = endpoints[[2L]]
        )
      })
      pva_result(state, events)
    },
    requires = c("population.id", "population.age", "population.alive", "population.dependency"),
    writes = "population.dependency",
    description = "Update dependent/independent status from age."
  )
}

#' Construct the breeding-eligibility and mate-availability process
#'
#' @param parameters Benchmark parameter fixture.
#' @param name Process name.
#'
#' @return A conforming process object.
grizzly_breeding_eligibility_process <- function(
    parameters = grizzly_benchmark_parameters(),
    name = "breeding_eligibility") {
  .validate_grizzly_benchmark_parameters(parameters)
  pva_process(
    name = name,
    params = list(maturity_age = parameters$maturity_age),
    run = function(state, context, process_params) {
      alive_males <- any(vapply(
        state$population,
        function(ind) isTRUE(ind$alive) && identical(ind$sex, "M") &&
          identical(ind$dependency, "independent") &&
          ind$age >= process_params$maturity_age,
        logical(1)
      ))
      eligible <- 0L
      for (index in seq_along(state$population)) {
        individual <- state$population[[index]]
        caring <- any(vapply(
          state$population,
          function(child) isTRUE(child$alive) && identical(child$mother_id, individual$id) &&
            child$dependency %in% c("cub", "yearling"),
          logical(1)
        ))
        is_eligible <- isTRUE(individual$alive) && identical(individual$sex, "F") &&
          identical(individual$dependency, "independent") &&
          individual$age >= process_params$maturity_age && alive_males && !caring
        state$population[[index]]$reproductive_status <- if (caring) {
          "caring"
        } else if (is_eligible) {
          eligible <- eligible + 1L
          "eligible"
        } else {
          "ineligible"
        }
      }
      pva_result(
        state,
        list(list(event_type = "breeding_eligibility", value = as.integer(eligible)))
      )
    },
    requires = c(
      "population.id", "population.sex", "population.age", "population.alive",
      "population.dependency", "population.reproductive_status"
    ),
    writes = "population.reproductive_status",
    description = "Mark mature independent females eligible only when a mate exists."
  )
}

#' Construct a targeted human-caused mortality process
#'
#' @param parameters Benchmark parameter fixture.
#' @param name Process name.
#'
#' @return A conforming mortality process.
grizzly_human_mortality_process <- function(
    parameters = grizzly_benchmark_parameters(),
    name = "human_mortality") {
  .validate_grizzly_benchmark_parameters(parameters)
  pva_process(
    name = name,
    params = list(
      mortality_probability = parameters$human_mortality_probability,
      target_sex = parameters$human_target_sex,
      target_min_age = parameters$human_target_min_age,
      age_class_boundary = parameters$maturity_age
    ),
    run = function(state, context, process_params) {
      deaths <- list()
      for (index in seq_along(state$population)) {
        individual <- state$population[[index]]
        eligible <- isTRUE(individual$alive) &&
          identical(individual$sex, process_params$target_sex) &&
          individual$age >= process_params$target_min_age &&
          identical(individual$dependency, "independent")
        if (eligible && stats::runif(1L) < process_params$mortality_probability) {
          state$population[[index]]$alive <- FALSE
          deaths[[length(deaths) + 1L]] <- list(
            event_type = "death",
            value = 1L,
            cause = "human",
            sex = individual$sex,
            age = as.integer(individual$age),
            age_class = if (individual$age >= process_params$age_class_boundary) "adult" else "subadult",
            dependency = individual$dependency
          )
        }
      }
      pva_result(state, deaths)
    },
    requires = c(
      "population.id", "population.sex", "population.age", "population.alive",
      "population.dependency"
    ),
    writes = "population.alive",
    description = "Apply targeted human mortality with stratum provenance."
  )
}

#' Construct the optional immigration/introduction process
#'
#' @param parameters Benchmark parameter fixture.
#' @param name Process name.
#'
#' @return A conforming creation process.
grizzly_immigration_process <- function(
    parameters = grizzly_benchmark_parameters(),
    name = "immigration") {
  .validate_grizzly_benchmark_parameters(parameters)
  immigration_count <- .normalize_non_negative_count(
    parameters$immigration_count, "immigration_count"
  )
  immigration_age <- .normalize_integer_scalar(
    parameters$immigration_age, "immigration_age", minimum = 0L
  )
  introduction_process(
    count = immigration_count,
    initializer = function(index, id, state, context, params) {
      list(
        sex = params$sexes[[((index - 1L) %% length(params$sexes)) + 1L]],
        age = params$age,
        mother_id = NA_integer_,
        father_id = NA_integer_,
        dependency = "independent",
        reproductive_status = "ineligible"
      )
    },
    initializer_fields = c(
      "sex", "age", "mother_id", "father_id", "dependency",
      "reproductive_status"
    ),
    source = "illustrative translocation",
    name = name,
    params = list(
      sexes = parameters$immigration_sex,
      age = immigration_age
    ),
    requires = character()
  )
}

#' Construct a non-mutating benchmark observation process
#'
#' @param name Process name.
#'
#' @return A conforming observer process.
grizzly_observation_process <- function(
    parameters = grizzly_benchmark_parameters(),
    name = "observation") {
  .validate_grizzly_benchmark_parameters(parameters)
  pva_process(
    name = name,
    params = list(detection_probability = parameters$observation_detection),
    run = function(state, context, params) {
      alive <- vapply(state$population, function(ind) isTRUE(ind$alive), logical(1))
      observed <- if (sum(alive)) {
        sum(stats::rbinom(sum(alive), size = 1L, prob = params$detection_probability))
      } else {
        0L
      }
      pva_result(
        state,
        list(list(
          event_type = "observation",
          latent_total = as.integer(sum(alive)),
          observed_total = as.integer(observed),
          detection_probability = params$detection_probability,
          observation_model = "independent binomial detection"
        ))
      )
    },
    requires = c("population.id", "population.alive"),
    description = "Observe total abundance without changing population state."
  )
}

#' Construct the canonical benchmark process list
#'
#' @param parameters Benchmark parameter fixture.
#' @param scenario One of the named benchmark scenarios.
#' @param include_observation Include the custom non-mutating observer.
#'
#' @return An ordered list of ordinary process objects.
#' @export
grizzly_benchmark_processes <- function(
    parameters = grizzly_benchmark_parameters(),
    scenario = c(
      "baseline", "female_low_survival", "female_high_survival",
      "human_mortality", "immigration", "environmental_variation",
      "human_mortality_before_reproduction"
    ),
    include_observation = TRUE) {
  .validate_grizzly_benchmark_parameters(parameters)
  scenario <- match.arg(scenario)
  if (!is.logical(include_observation) || length(include_observation) != 1L ||
      is.na(include_observation)) {
    stop("include_observation must be one non-missing logical value", call. = FALSE)
  }
  female_key <- switch(
    scenario,
    female_low_survival = "low",
    female_high_survival = "high",
    "baseline"
  )
  processes <- list(
    grizzly_environment_process(
      parameters,
      varying = identical(scenario, "environmental_variation")
    ),
    age_process(),
    grizzly_dependency_process(parameters),
    grizzly_breeding_eligibility_process(parameters)
  )
  human <- grizzly_human_mortality_process(parameters)
  reproduction_base <- reproduction_process(
    breeding_probability = function(mother, state, context, params) {
      if (identical(mother$reproductive_status, "eligible")) {
        params$breeding_probability
      } else {
        0
      }
    },
    fecundity_mean = function(mother, state, context, params) {
      params$fecundity_lambda
    },
    mating = function(population, mother, context, params) {
      males <- Filter(function(ind) {
        isTRUE(ind$alive) && identical(ind$sex, "M") &&
          identical(ind$dependency, "independent") &&
          ind$age >= params$maturity_age
      }, population)
      if (length(males)) males[[1L]] else NULL
    },
    require_mate = TRUE,
    newborn_initializer = function(mother, father, state, context, params) {
      list(dependency = "cub", reproductive_status = "ineligible")
    },
    initializer_fields = c("dependency", "reproductive_status"),
    requires = c("population.dependency", "population.reproductive_status", "globals.environment_modifier"),
    params = list(
      breeding_probability = parameters$breeding_probability,
      fecundity_lambda = parameters$fecundity_lambda,
      maturity_age = parameters$maturity_age
    )
  )
  reproduction <- .grizzly_reproduction_process(reproduction_base)
  independent <- survival_process(
    probability = function(individual, state, context, params) {
      base <- if (identical(individual$sex, "F")) params$female_survival else params$male_survival
      base * state$globals$environment_modifier
    },
    eligible = function(individual, state, context, params) {
      identical(individual$dependency, "independent")
    },
    name = "independent_survival",
    params = list(
      female_survival = parameters$female_survival[[female_key]],
      male_survival = parameters$male_survival
    ),
    requires = c("population.dependency", "globals.environment_modifier"),
    cause = "natural_independent"
  )
  dependent <- survival_process(
    probability = function(individual, state, context, params) {
      params$dependent_survival * state$globals$environment_modifier
    },
    eligible = function(individual, state, context, params) {
      individual$dependency %in% c("cub", "yearling")
    },
    name = "dependent_survival",
    params = list(dependent_survival = parameters$dependent_survival),
    requires = c("population.dependency", "globals.environment_modifier"),
    cause = "natural_dependent"
  )
  dependent <- .grizzly_dependent_survival_process(dependent)
  if (identical(scenario, "human_mortality_before_reproduction")) {
    processes <- c(processes, list(human, reproduction, dependent, independent))
  } else {
    processes <- c(processes, list(reproduction, dependent, independent))
    if (identical(scenario, "human_mortality")) processes <- c(processes, list(human))
  }
  if (identical(scenario, "immigration")) {
    processes <- c(processes, list(grizzly_immigration_process(parameters)))
  }
  if (include_observation) processes <- c(processes, list(grizzly_observation_process(parameters)))
  processes <- c(processes, list(
    census_process(
      summarise = .grizzly_census_metrics,
      requires = c(
        "population.id", "population.sex", "population.alive",
        "population.dependency", "population.reproductive_status"
      )
    )
  ))
  validate_processes(processes)
}

# Keep the generic reproduction contract intact while making the benchmark's
# maternal state explicit: a mother that produced at least one cub is caring
# immediately, so a repeated reproduction process in the same interval cannot
# create a second litter.
.grizzly_reproduction_process <- function(base) {
  process <- base
  process$run <- function(state, context, process_params) {
    before_ids <- if (length(state$population)) {
      vapply(state$population, `[[`, integer(1), "id")
    } else {
      integer()
    }
    result <- base$run(state, context, process_params)
    after <- result$state
    after_ids <- if (length(after$population)) {
      vapply(after$population, `[[`, integer(1), "id")
    } else {
      integer()
    }
    newborn_ids <- setdiff(after_ids, before_ids)
    if (length(newborn_ids)) {
      newborns <- after$population[vapply(
        after$population,
        function(ind) ind$id %in% newborn_ids,
        logical(1)
      )]
      mother_ids <- unique(vapply(
        newborns,
        function(ind) ind$mother_id,
        integer(1)
      ))
      mother_ids <- mother_ids[!is.na(mother_ids)]
      for (mother_id in mother_ids) {
        index <- which(vapply(
          after$population,
          function(ind) identical(ind$id, mother_id),
          logical(1)
        ))
        if (length(index) == 1L && isTRUE(after$population[[index]]$alive)) {
          after$population[[index]]$reproductive_status <- "caring"
        }
      }
    }
    pva_result(after, result$events)
  }
  process$writes <- unique(c(process$writes, "population.reproductive_status"))
  .validate_process(process)
}

# Refresh maternal status after dependent survival, before any later observer
# or census. A mother whose dependants all died remains ineligible for the
# current interval; the next interval's eligibility process may recompute it.
.grizzly_dependent_survival_process <- function(base) {
  process <- base
  process$run <- function(state, context, process_params) {
    result <- base$run(state, context, process_params)
    after <- result$state
    for (index in seq_along(after$population)) {
      individual <- after$population[[index]]
      if (!identical(individual$sex, "F") || !isTRUE(individual$alive)) next
      caring <- any(vapply(
        after$population,
        function(child) isTRUE(child$alive) && identical(child$mother_id, individual$id) &&
          child$dependency %in% c("cub", "yearling"),
        logical(1)
      ))
      if (caring) {
        after$population[[index]]$reproductive_status <- "caring"
      } else if (identical(individual$reproductive_status, "caring")) {
        after$population[[index]]$reproductive_status <- "ineligible"
      }
    }
    pva_result(after, result$events)
  }
  process$writes <- unique(c(process$writes, "population.reproductive_status"))
  .validate_process(process)
}

#' Construct one canonical benchmark scenario
#'
#' @param scenario Named scenario accepted by [grizzly_benchmark_processes()].
#' @param parameters Benchmark parameter fixture.
#' @param n_runs Number of replicate runs.
#' @param n_steps Number of annual intervals; defaults to parameter horizon.
#' @param seed Root RNG seed.
#' @param include_observation Include the custom observer.
#'
#' @return An `openpva_scenario` carrying benchmark provenance.
#' @export
grizzly_benchmark_scenario <- function(
    scenario = c(
      "baseline", "female_low_survival", "female_high_survival",
      "human_mortality", "immigration", "environmental_variation",
      "human_mortality_before_reproduction"
    ),
    parameters = grizzly_benchmark_parameters(),
    n_runs = 20L,
    n_steps = parameters$horizon,
    seed = 20260809L,
    include_observation = TRUE) {
  scenario <- match.arg(scenario)
  parameters$immigration_count <- .normalize_non_negative_count(
    parameters$immigration_count, "immigration_count"
  )
  parameters$immigration_age <- .normalize_integer_scalar(
    parameters$immigration_age, "immigration_age", minimum = 0L
  )
  .validate_grizzly_benchmark_parameters(parameters)
  n_runs <- .normalize_positive_count(n_runs, "n_runs")
  n_steps <- .normalize_positive_count(n_steps, "n_steps")
  if (n_steps > parameters$horizon) {
    stop("n_steps cannot exceed the benchmark parameter horizon", call. = FALSE)
  }
  processes <- grizzly_benchmark_processes(parameters, scenario, include_observation)
  initial_census <- census_process(
    summarise = .grizzly_census_metrics,
    requires = c(
      "population.id", "population.sex", "population.alive",
      "population.dependency", "population.reproductive_status"
    )
  )
  result <- scenario_spec(
    name = paste0("grizzly-illustrative-", scenario),
    n_runs = n_runs,
    n_steps = n_steps,
    init_fun = function() grizzly_benchmark_initial_state(parameters = parameters),
    processes = processes,
    seed = seed,
    initial_census = initial_census,
    record_population_history = FALSE
  )
  result$benchmark <- list(
    scenario = scenario,
    parameters = parameters,
    initial_state_spec = list(
      n_females = 6L, n_males = 4L,
      dependent_females = 2L, dependent_males = 1L
    ),
    process_order = vapply(processes, `[[`, character(1), "name"),
    parameter_hash = .grizzly_parameter_hash(list(
      parameters = parameters,
      scenario = scenario,
      n_steps = n_steps,
      initial_state_spec = list(
        n_females = 6L, n_males = 4L,
        dependent_females = 2L, dependent_males = 1L
      ),
      process_order = vapply(processes, `[[`, character(1), "name")
    )),
    source_label = parameters$source_label,
    software = list(
      package = as.character(utils::packageVersion("OpenPVA")),
      R = as.character(getRversion())
    )
  )
  result
}

#' Construct the required benchmark scenario set
#'
#' @param parameters Benchmark parameter fixture.
#' @param n_runs Number of replicates in each scenario.
#' @param seed Root seed used for each scenario.
#'
#' @return Named list of benchmark scenarios.
#' @export
grizzly_benchmark_scenarios <- function(
    parameters = grizzly_benchmark_parameters(),
    n_runs = 20L,
    seed = 20260809L) {
  names <- c(
    "baseline", "female_low_survival", "female_high_survival",
    "human_mortality", "immigration"
  )
  stats::setNames(lapply(names, function(name) {
    grizzly_benchmark_scenario(name, parameters, n_runs = n_runs, seed = seed)
  }), names)
}

#' Run and summarise one canonical benchmark scenario
#'
#' @param scenario One of the five canonical benchmark scenario names.
#' @param parameters Benchmark parameter fixture.
#' @param n_runs Number of replicates.
#' @param n_steps Number of annual intervals.
#' @param seed Root RNG seed.
#' @param parallel Whether to use supported fork execution.
#' @param workers Number of fork workers.
#'
#' @return The `run_scenario()` result with a benchmark summary.
#' @export
run_grizzly_benchmark <- function(
    scenario = "baseline",
    parameters = grizzly_benchmark_parameters(),
    n_runs = 20L,
    n_steps = parameters$horizon,
    seed = 20260809L,
    parallel = FALSE,
    workers = 2L) {
  scenario <- match.arg(scenario, c(
    "baseline", "female_low_survival", "female_high_survival",
    "human_mortality", "immigration"
  ))
  scenario_object <- grizzly_benchmark_scenario(
    scenario = scenario,
    parameters = parameters,
    n_runs = n_runs,
    n_steps = n_steps,
    seed = seed
  )
  output <- run_scenario(scenario_object, parallel = parallel, workers = workers)
  benchmark <- scenario_object$benchmark
  output$sim_output$provenance$benchmark <- benchmark
  output$benchmark_summary <- summarise_grizzly_benchmark(output, benchmark)
  output
}

#' Summarise replicate-level canonical benchmark output
#'
#' @param output Result from [run_grizzly_benchmark()] or [run_scenario()].
#' @param benchmark Optional benchmark provenance list.
#'
#' @return A list containing trajectory, event and run-level summaries.
#' @export
summarise_grizzly_benchmark <- function(output, benchmark = NULL) {
  if (!is.list(output) || is.null(output$sim_output$census) ||
      is.null(output$sim_output$events)) {
    stop("output must contain sim_output$census and sim_output$events", call. = FALSE)
  }
  if (is.null(benchmark)) {
    benchmark <- output$sim_output$provenance$benchmark
  }
  if (!is.list(benchmark) || is.null(benchmark$parameters)) {
    stop(
      "explicit benchmark metadata is required for benchmark summaries",
      call. = FALSE
    )
  }
  census <- output$sim_output$census
  events <- output$sim_output$events
  threshold <- benchmark$parameters$quasi_extinction_threshold
  if (!is.numeric(threshold) || length(threshold) != 1L || is.na(threshold)) {
    stop("benchmark metadata must include a quasi-extinction threshold", call. = FALSE)
  }
  trajectory <- census |>
    dplyr::mutate(
      scenario = benchmark$scenario %||% NA_character_,
      phase_order = dplyr::if_else(.data$phase == "initial", 0L, 1L)
    ) |>
    dplyr::group_by(.data$run) |>
    dplyr::arrange(.data$time, .data$phase_order, .by_group = TRUE) |>
    dplyr::mutate(
      finite_growth = dplyr::if_else(
        .data$phase == "interval",
        .data$n_alive / dplyr::lag(.data$n_alive),
        NA_real_
      )
    ) |>
    dplyr::ungroup()
  initial_summary <- trajectory |>
    dplyr::filter(.data$phase == "initial") |>
    dplyr::group_by(.data$run) |>
    dplyr::summarise(initial_abundance = dplyr::first(.data$n_alive), .groups = "drop")
  crossing_summary <- trajectory |>
    dplyr::mutate(crossed = .data$n_alive <= threshold) |>
    dplyr::group_by(.data$run) |>
    dplyr::arrange(.data$time, .data$phase_order, .by_group = TRUE) |>
    dplyr::summarise(
      quasi_extinct = any(.data$crossed),
      quasi_extinction_time = if (any(.data$crossed)) {
        .data$time[which(.data$crossed)[[1L]]]
      } else {
        NA_integer_
      },
      quasi_extinction_phase = if (any(.data$crossed)) {
        .data$phase[which(.data$crossed)[[1L]]]
      } else {
        NA_character_
      },
      .groups = "drop"
    )
  run_summary <- trajectory |>
    dplyr::filter(.data$phase == "interval") |>
    dplyr::group_by(.data$run) |>
    dplyr::summarise(
      final_abundance = .data$n_alive[which.max(.data$time)],
      final_independent_females = .data$n_female_independent_alive[which.max(.data$time)],
      horizon = max(.data$time) + 1L,
      .groups = "drop"
    ) |>
    dplyr::left_join(initial_summary, by = "run") |>
    dplyr::left_join(crossing_summary, by = "run") |>
    dplyr::mutate(
      finite_growth = dplyr::if_else(
        .data$initial_abundance == 0L,
        NA_real_,
        (.data$final_abundance / .data$initial_abundance)^(1 / .data$horizon)
      )
    )
  event_summary <- events |>
    dplyr::mutate(event_value = dplyr::coalesce(as.numeric(.data$value), 0)) |>
    dplyr::group_by(
      .data$run, .data$time, .data$event_type,
      dplyr::across(dplyr::any_of(c(
        "cause", "sex", "age", "age_class", "dependency", "from", "to",
        "source"
      )))
    ) |>
    dplyr::summarise(event_value = sum(.data$event_value), .groups = "drop")
  list(
    trajectory = trajectory,
    events = event_summary,
    run_summary = run_summary,
    threshold = threshold,
    quasi_extinction_probability = mean(run_summary$quasi_extinct),
    quasi_extinction_mcse = sqrt(
      mean(run_summary$quasi_extinct) * (1 - mean(run_summary$quasi_extinct)) /
        nrow(run_summary)
    ),
    quasi_extinction_mean_time = if (any(run_summary$quasi_extinct)) {
      mean(run_summary$quasi_extinction_time[run_summary$quasi_extinct])
    } else {
      NA_real_
    },
    provenance = benchmark
  )
}

.grizzly_census_metrics <- function(state, context, params) {
  alive <- vapply(state$population, function(ind) isTRUE(ind$alive), logical(1))
  sex <- vapply(state$population, `[[`, character(1), "sex")
  dependency <- vapply(state$population, `[[`, character(1), "dependency")
  status <- vapply(state$population, `[[`, character(1), "reproductive_status")
  list(
    n_alive = as.integer(sum(alive)),
    n_female_alive = as.integer(sum(alive & sex == "F")),
    n_male_alive = as.integer(sum(alive & sex == "M")),
    n_dependent_alive = as.integer(sum(alive & dependency %in% c("cub", "yearling"))),
    n_cub_alive = as.integer(sum(alive & dependency == "cub")),
    n_yearling_alive = as.integer(sum(alive & dependency == "yearling")),
    n_independent_alive = as.integer(sum(alive & dependency == "independent")),
    n_female_independent_alive = as.integer(sum(alive & sex == "F" & dependency == "independent")),
    n_eligible_female_alive = as.integer(sum(alive & sex == "F" & status == "eligible"))
  )
}

.validate_grizzly_benchmark_parameters <- function(parameters) {
  if (!is.list(parameters) || !identical(parameters$calibrated, FALSE) ||
      !is.character(parameters$source_label) || length(parameters$source_label) != 1L ||
      is.na(parameters$source_label) || !nzchar(trimws(parameters$source_label))) {
    stop("parameters must be the uncalibrated, source-labelled benchmark fixture", call. = FALSE)
  }
  .normalize_positive_count(parameters$horizon, "horizon")
  .normalize_non_negative_count(parameters$quasi_extinction_threshold, "quasi_extinction_threshold")
  .normalize_non_negative_count(parameters$immigration_count, "immigration_count")
  .normalize_integer_scalar(parameters$immigration_age, "immigration_age", minimum = 0L)
  probabilities <- c(
    parameters$breeding_probability, parameters$dependent_survival,
    parameters$male_survival, parameters$female_survival,
    parameters$human_mortality_probability, parameters$observation_detection
  )
  if (any(!is.finite(probabilities) | probabilities < 0 | probabilities > 1)) {
    stop("benchmark probabilities must lie in [0, 1]", call. = FALSE)
  }
  if (!is.finite(parameters$fecundity_lambda) || parameters$fecundity_lambda < 0) {
    stop("fecundity_lambda must be finite and non-negative", call. = FALSE)
  }
  age_fields <- c("maturity_age", "dependency_age", "human_target_min_age")
  if (any(!vapply(parameters[age_fields], function(value) {
    is.numeric(value) && length(value) == 1L && is.finite(value) &&
      value == as.integer(value) && value >= 0
  }, logical(1)))) {
    stop("benchmark ages must be non-negative integer-like values", call. = FALSE)
  }
  if (parameters$dependency_age != 3L || parameters$maturity_age <= parameters$dependency_age) {
    stop("the benchmark requires dependency_age = 3 and maturity after dependency", call. = FALSE)
  }
  if (!identical(names(parameters$female_survival), c("baseline", "low", "high"))) {
    stop("female_survival must be named baseline, low and high", call. = FALSE)
  }
  if (!parameters$human_target_sex %in% c("F", "M")) {
    stop("human_target_sex must be 'F' or 'M'", call. = FALSE)
  }
  if (!is.character(parameters$immigration_sex) || !length(parameters$immigration_sex) ||
      any(!parameters$immigration_sex %in% c("F", "M"))) {
    stop("immigration sex parameters are invalid", call. = FALSE)
  }
  required_units <- c(
    "time", "survival", "breeding_probability", "fecundity_lambda",
    "human_mortality", "immigration"
  )
  if (!is.list(parameters$units) || !all(required_units %in% names(parameters$units))) {
    stop("benchmark units metadata is incomplete", call. = FALSE)
  }
  if (!all(vapply(parameters$units[required_units], function(value) {
    is.character(value) && length(value) == 1L && !is.na(value) &&
      nzchar(trimws(value))
  }, logical(1)))) {
    stop("benchmark units must be non-empty character scalars", call. = FALSE)
  }
  if (length(parameters$environmental_modifiers) != parameters$horizon ||
      length(parameters$varying_environmental_modifiers) != parameters$horizon ||
      any(!is.finite(parameters$environmental_modifiers)) ||
      any(!is.finite(parameters$varying_environmental_modifiers)) ||
      any(parameters$environmental_modifiers <= 0) ||
      any(parameters$varying_environmental_modifiers <= 0)) {
    stop("environmental modifier vectors must be positive and match horizon", call. = FALSE)
  }
  maximum_modifier <- max(c(
    parameters$environmental_modifiers,
    parameters$varying_environmental_modifiers
  ))
  if (any(c(
    parameters$dependent_survival,
    parameters$male_survival,
    parameters$female_survival
  ) * maximum_modifier > 1)) {
    stop("survival multiplied by environmental modifiers must remain in [0, 1]", call. = FALSE)
  }
  invisible(parameters)
}

.grizzly_parameter_hash <- function(parameters) {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(parameters, path)
  unname(as.character(tools::md5sum(path)))
}
