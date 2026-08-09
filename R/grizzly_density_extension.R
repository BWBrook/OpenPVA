#' Construct the illustrative grizzly global-density extension
#'
#' This non-canonical fixture adds an explicitly positioned global abundance
#' snapshot to the Goal 003 baseline and composes its multiplier inside the
#' existing survival, breeding-probability and fecundity callbacks. `capacity`
#' is an illustrative user input, not an empirical grizzly estimate.
#'
#' @param capacity Positive finite illustrative capacity.
#' @param parameters Parameter fixture from [grizzly_benchmark_parameters()].
#' @param n_runs Number of replicate runs.
#' @param n_steps Number of annual intervals; defaults to the fixture horizon.
#' @param seed Root RNG seed.
#' @param include_observation Include the custom benchmark observer.
#'
#' @return An `openpva_scenario` carrying explicit benchmark and density
#'   provenance.
#' @export
grizzly_density_extension_scenario <- function(
    capacity,
    parameters = grizzly_benchmark_parameters(),
    n_runs = 20L,
    n_steps = parameters$horizon,
    seed = 20260809L,
    include_observation = TRUE) {
  ceiling_density_multiplier(0, capacity)
  capacity <- as.numeric(capacity)
  .validate_grizzly_benchmark_parameters(parameters)
  n_runs <- .normalize_positive_count(n_runs, "n_runs")
  n_steps <- .normalize_positive_count(n_steps, "n_steps")
  if (n_steps > parameters$horizon) {
    stop("n_steps cannot exceed the benchmark parameter horizon", call. = FALSE)
  }
  if (!is.logical(include_observation) || length(include_observation) != 1L ||
      is.na(include_observation)) {
    stop("include_observation must be one non-missing logical value", call. = FALSE)
  }

  processes <- grizzly_benchmark_processes(
    parameters = parameters,
    scenario = "baseline",
    include_observation = include_observation
  )
  process_names <- vapply(processes, `[[`, character(1), "name")

  reproduction_index <- match("reproduction", process_names)
  reproduction <- processes[[reproduction_index]]
  reproduction$params$model$base_breeding_probability <-
    reproduction$params$breeding_probability
  reproduction$params$model$base_fecundity_mean <-
    reproduction$params$fecundity_mean
  reproduction$params$model$density_capacity <- capacity
  reproduction$params$breeding_probability <- function(
      mother, state, context, params) {
    params$base_breeding_probability(mother, state, context, params) *
      ceiling_density_multiplier(
        state$globals$density_n_alive,
        params$density_capacity
      )
  }
  reproduction$params$fecundity_mean <- function(
      mother, state, context, params) {
    params$base_fecundity_mean(mother, state, context, params) *
      ceiling_density_multiplier(
        state$globals$density_n_alive,
        params$density_capacity
      )
  }
  reproduction$requires <- unique(c(
    reproduction$requires,
    "globals.density_n_alive"
  ))
  reproduction$description <- paste(
    reproduction$description,
    "The illustrative density snapshot explicitly modifies breeding and fecundity."
  )
  processes[[reproduction_index]] <- .validate_process(reproduction)

  for (process_name in c("dependent_survival", "independent_survival")) {
    index <- match(process_name, process_names)
    survival <- processes[[index]]
    survival$params$model$base_probability <- survival$params$probability
    survival$params$model$density_capacity <- capacity
    survival$params$probability <- function(individual, state, context, params) {
      params$base_probability(individual, state, context, params) *
        ceiling_density_multiplier(
          state$globals$density_n_alive,
          params$density_capacity
        )
    }
    survival$requires <- unique(c(
      survival$requires,
      "globals.density_n_alive"
    ))
    survival$description <- paste(
      survival$description,
      "The illustrative density snapshot explicitly modifies survival."
    )
    processes[[index]] <- .validate_process(survival)
  }

  processes <- append(
    processes,
    list(density_snapshot_process()),
    after = reproduction_index - 1L
  )
  validate_processes(processes)

  initial_state_spec <- list(
    n_females = 6L,
    n_males = 4L,
    dependent_females = 2L,
    dependent_males = 1L
  )
  result <- scenario_spec(
    name = "grizzly-illustrative-global-density-feedback",
    n_runs = n_runs,
    n_steps = n_steps,
    init_fun = function() grizzly_benchmark_initial_state(parameters = parameters),
    processes = processes,
    seed = seed,
    initial_census = census_process(
      summarise = .grizzly_census_metrics,
      requires = c(
        "population.id", "population.sex", "population.alive",
        "population.dependency", "population.reproductive_status"
      )
    ),
    record_population_history = FALSE
  )
  process_order <- vapply(processes, `[[`, character(1), "name")
  source_label <- paste(
    parameters$source_label,
    "Global density capacity is synthetic and illustrative, not empirical."
  )
  result$benchmark <- list(
    scenario = "global_density_feedback_extension",
    parameters = parameters,
    initial_state_spec = initial_state_spec,
    process_order = process_order,
    parameter_hash = .grizzly_parameter_hash(list(
      parameters = parameters,
      capacity = capacity,
      n_steps = n_steps,
      initial_state_spec = initial_state_spec,
      process_order = process_order
    )),
    source_label = source_label,
    density_extension = list(
      calibrated = FALSE,
      capacity = capacity,
      capacity_units = "living individuals",
      snapshot_field = "globals.density_n_alive",
      affected_rates = c(
        "survival_probability",
        "breeding_probability",
        "fecundity_mean"
      ),
      interpretation = paste(
        "Phenomenological vital-rate feedback; not a hard cap, empirical K,",
        "equilibrium guarantee, or population truncation."
      )
    ),
    software = list(
      package = as.character(utils::packageVersion("OpenPVA")),
      R = as.character(getRversion())
    )
  )
  result
}
