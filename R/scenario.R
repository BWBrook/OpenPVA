#' Create a simulation scenario specification
#'
#' Defines a reusable scenario that can be executed with `run_scenario()`.
#'
#' @param name Scenario name (character scalar).
#' @param n_runs Number of replicate runs.
#' @param n_years Number of years per run.
#' @param init_fun Function that initialises a population when called.
#' @param survival_fun Function returning survival probabilities.
#' @param breeding_fun Function identifying breeding-eligible individuals.
#' @param fecundity_fun Function returning offspring counts for breeders.
#' @param K Optional numeric carrying capacity for density scaling.
#' @param harvest_quota Optional harvest quota (scalar or length `n_years`).
#' @param lifecycle_steps Character vector describing the lifecycle order.
#'
#' @return An object of class `openpva_scenario`.
#' @export
scenario_spec <- function(
    name,
    n_runs,
    n_years,
    init_fun,
    survival_fun = default_survival_fun,
    breeding_fun = default_breeding_fun,
    fecundity_fun = default_fecundity_fun,
    K = NULL,
    harvest_quota = NULL,
    lifecycle_steps = default_lifecycle_steps()) {
  scenario <- list(
    name = name,
    n_runs = n_runs,
    n_years = n_years,
    init_fun = init_fun,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun,
    K = K,
    harvest_quota = harvest_quota,
    lifecycle_steps = lifecycle_steps
  )
  .validate_scenario(scenario)
  class(scenario) <- c("openpva_scenario", "list")
  scenario
}

#' Run a simulation scenario
#'
#' Executes a scenario created by `scenario_spec()` via
#' `run_basic_simulation_replicates()`.
#'
#' @param scenario An object created by `scenario_spec()`.
#'
#' @return A list with elements `scenario` and `sim_output`.
#' @export
run_scenario <- function(scenario) {
  if (!inherits(scenario, "openpva_scenario")) {
    stop("`scenario` must be created by scenario_spec().")
  }
  .validate_scenario(scenario)
  sim_output <- run_basic_simulation_replicates(
    n_runs = scenario$n_runs,
    n_years = scenario$n_years,
    init_fun = scenario$init_fun,
    survival_fun = scenario$survival_fun,
    breeding_fun = scenario$breeding_fun,
    fecundity_fun = scenario$fecundity_fun,
    K = scenario$K,
    harvest_quota = scenario$harvest_quota,
    lifecycle_steps = scenario$lifecycle_steps
  )
  list(scenario = scenario, sim_output = sim_output)
}

#' @export
print.openpva_scenario <- function(x, ...) {
  cat(
    sprintf(
      "<Scenario %s | runs: %d | years: %d | K: %s | harvest: %s | steps: %s>\n",
      x$name,
      as.integer(x$n_runs),
      as.integer(x$n_years),
      ifelse(is.null(x$K), "NULL", x$K),
      ifelse(is.null(x$harvest_quota), "NULL", "set"),
      paste(x$lifecycle_steps, collapse = " -> ")
    )
  )
  invisible(x)
}

#' Read a scenario specification from YAML
#'
#' Parses a YAML file describing a scenario and returns an
#' `openpva_scenario` object.
#'
#' @param path Path to a YAML file.
#'
#' @return An `openpva_scenario` object.
#' @export
read_scenario_yaml <- function(path) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required to read scenario YAML files. Please install it.", call. = FALSE)
  }
  cfg <- yaml::read_yaml(path)
  if (is.null(cfg$name) || is.null(cfg$n_runs) || is.null(cfg$n_years)) {
    stop("YAML must include name, n_runs, and n_years.")
  }

  init_spec <- cfg$initializer
  if (is.null(init_spec$fun)) {
    stop("initializer$fun must be provided in YAML.")
  }
  init_fun <- function() {
    f <- .resolve_function(init_spec$fun)
    args <- init_spec$args
    if (is.null(args)) args <- list()
    if (!is.list(args)) stop("initializer$args must be a named list")
    do.call(f, args)
  }

  survival_fun_name <- cfg$survival_fun %||% "default_survival_fun"
  breeding_fun_name <- cfg$breeding_fun %||% "default_breeding_fun"
  fecundity_fun_name <- cfg$fecundity_fun %||% "default_fecundity_fun"

  lifecycle_steps <- cfg$lifecycle_steps %||% default_lifecycle_steps()
  lifecycle_steps <- unlist(lifecycle_steps)

  scenario_spec(
    name = cfg$name,
    n_runs = cfg$n_runs,
    n_years = cfg$n_years,
    init_fun = init_fun,
    survival_fun = .resolve_function(survival_fun_name),
    breeding_fun = .resolve_function(breeding_fun_name),
    fecundity_fun = .resolve_function(fecundity_fun_name),
    K = cfg$K,
    harvest_quota = cfg$harvest_quota,
    lifecycle_steps = lifecycle_steps
  )
}

.validate_scenario <- function(scenario) {
  if (!is.list(scenario)) {
    stop("scenario must be a list")
  }
  if (!is.character(scenario$name) || length(scenario$name) != 1L || !nzchar(scenario$name)) {
    stop("Scenario `name` must be a non-empty character scalar")
  }
  for (field in c("n_runs", "n_years")) {
    value <- scenario[[field]]
    if (!is.numeric(value) || length(value) != 1L || value <= 0) {
      stop(field, " must be a positive numeric value")
    }
    scenario[[field]] <- as.integer(value)
  }
  if (!is.function(scenario$init_fun)) stop("init_fun must be a function")
  if (!is.function(scenario$survival_fun)) stop("survival_fun must be a function")
  if (!is.function(scenario$breeding_fun)) stop("breeding_fun must be a function")
  if (!is.function(scenario$fecundity_fun)) stop("fecundity_fun must be a function")
  .validate_lifecycle_steps(scenario$lifecycle_steps)
  invisible(scenario)
}

.resolve_function <- function(name) {
  if (is.function(name)) {
    return(name)
  }
  if (!is.character(name) || length(name) != 1L) {
    stop("Function reference must be a character scalar or function")
  }
  if (exists(name, where = asNamespace("OpenPVA"), inherits = FALSE)) {
    return(getFromNamespace(name, "OpenPVA"))
  }
  match.fun(name)
}

`%||%` <- function(a, b) if (!is.null(a)) a else b
