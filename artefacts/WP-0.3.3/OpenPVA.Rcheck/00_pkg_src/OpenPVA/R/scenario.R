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
#' @param K_patches Optional numeric vector of patch-specific carrying capacities.
#' @param harvest_quota Optional harvest quota (scalar or length `n_years`).
#' @param lifecycle_steps Character vector describing the lifecycle order.
#' @param mating_fun Function used for mate selection (defaults to `default_mating_fun`).
#' @param inherit_fun Optional function for generating offspring genotypes. `NULL`
#'   disables inheritance.
#' @param dispersal_fun Function controlling movement between patches (defaults to
#'   `default_dispersal_fun`).
#' @param supplement_quota Optional numeric scalar or vector (length `n_years`)
#'   giving supplementation quotas for the "supplementation" lifecycle step.
#' @param supplement_patch Optional patch identifier assigned to all added
#'   individuals (defaults to `NA`).
#' @param env_surv_sd Standard deviation of a lognormal year-level multiplier on
#'   survival (environmental variation). Set to 0 to disable.
#' @param cat_surv_prob Per-year probability of a catastrophic survival event
#'   (Bernoulli). Set to 0 to disable.
#' @param cat_surv_mult Multiplicative factor applied to survival probabilities
#'   in catastrophe years. Typical values lie within (0, 1]; set to 1 to make
#'   catastrophes neutral even if they occur.
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
    K_patches = NULL,
    harvest_quota = NULL,
    lifecycle_steps = default_lifecycle_steps(),
    mating_fun = default_mating_fun,
    inherit_fun = NULL,
    dispersal_fun = default_dispersal_fun,
    supplement_quota = NULL,
    supplement_patch = NULL,
    env_surv_sd = 0,
    cat_surv_prob = 0,
    cat_surv_mult = 1) {
  env_surv_sd <- as.numeric(env_surv_sd)
  cat_surv_prob <- as.numeric(cat_surv_prob)
  cat_surv_mult <- as.numeric(cat_surv_mult)
  scenario <- list(
    name = name,
    n_runs = n_runs,
    n_years = n_years,
    init_fun = init_fun,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun,
    K = K,
    K_patches = K_patches,
    harvest_quota = harvest_quota,
    lifecycle_steps = lifecycle_steps,
    mating_fun = mating_fun,
    inherit_fun = inherit_fun,
    dispersal_fun = dispersal_fun,
    supplement_quota = supplement_quota,
    supplement_patch = supplement_patch,
    env_surv_sd = env_surv_sd,
    cat_surv_prob = cat_surv_prob,
    cat_surv_mult = cat_surv_mult
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
    K_patches = scenario$K_patches,
    harvest_quota = scenario$harvest_quota,
    lifecycle_steps = scenario$lifecycle_steps,
    mating_fun = scenario$mating_fun,
    inherit_fun = scenario$inherit_fun,
    dispersal_fun = scenario$dispersal_fun,
    supplement_quota = scenario$supplement_quota,
    supplement_patch = scenario$supplement_patch,
    env_surv_sd = scenario$env_surv_sd,
    cat_surv_prob = scenario$cat_surv_prob,
    cat_surv_mult = scenario$cat_surv_mult
  )
  list(scenario = scenario, sim_output = sim_output)
}

#' Construct a simple genetics-enabled scenario
#'
#' Provides a convenience wrapper that initialises genotypes, applies inbreeding-
#' aware survival, and enables genotype inheritance for each run.
#'
#' @param name Scenario name.
#' @param n_runs Number of replicate runs.
#' @param n_years Number of years per run.
#' @param initial_n Initial population size for each run.
#' @param n_loci Number of loci per individual.
#' @param n_alleles Number of possible allele states per locus.
#' @param mutation_rate Mutation probability per allele during inheritance.
#' @param beta_F Strength of inbreeding depression (passed to
#'   `make_inbreeding_survival_fun()`).
#' @inheritParams run_basic_simulation
#'
#' @return An `openpva_scenario` ready to run with `run_scenario()`.
#' @export
make_simple_genetic_scenario <- function(
    name,
    n_runs,
    n_years,
    initial_n,
    n_loci = 10L,
    n_alleles = 2L,
    mutation_rate = 0,
    beta_F = 0.5,
    K = NULL,
    harvest_quota = NULL,
    lifecycle_steps = default_lifecycle_steps()) {
  .assert_positive_int <- function(value, label) {
    if (!is.numeric(value) || length(value) != 1L || value <= 0) {
      stop(label, " must be a positive numeric value", call. = FALSE)
    }
  }
  .assert_positive_int(n_runs, "n_runs")
  .assert_positive_int(n_years, "n_years")
  .assert_positive_int(initial_n, "initial_n")
  .assert_positive_int(n_loci, "n_loci")
  .assert_positive_int(n_alleles, "n_alleles")
  mutation_rate <- as.numeric(mutation_rate)
  if (length(mutation_rate) != 1L || is.na(mutation_rate) ||
      mutation_rate < 0 || mutation_rate > 1) {
    stop("mutation_rate must be within [0, 1]", call. = FALSE)
  }
  beta_F <- as.numeric(beta_F)
  if (length(beta_F) != 1L || is.na(beta_F) || beta_F < 0) {
    stop("beta_F must be a non-negative numeric value", call. = FALSE)
  }

  init_fun <- function() {
    pop <- initialize_population(initial_n)
    initialize_genotypes(pop, n_loci = n_loci, n_alleles = n_alleles)
  }
  survival_fun <- make_inbreeding_survival_fun(default_survival_fun, beta = beta_F)
  inherit_fun <- function(mother, father) {
    inherit_genotype_simple(
      mother = mother,
      father = father,
      mutation_rate = mutation_rate,
      n_alleles = n_alleles
    )
  }

  scenario_spec(
    name = name,
    n_runs = n_runs,
    n_years = n_years,
    init_fun = init_fun,
    survival_fun = survival_fun,
    breeding_fun = default_breeding_fun,
    fecundity_fun = default_fecundity_fun,
    K = K,
    harvest_quota = harvest_quota,
    lifecycle_steps = lifecycle_steps,
    mating_fun = default_mating_fun,
    inherit_fun = inherit_fun,
    dispersal_fun = default_dispersal_fun
  )
}

#' Construct a simple two-patch spatial scenario
#'
#' Builds a scenario with two patches, patch-specific carrying capacities,
#' and Markov dispersal.
#'
#' @param name Scenario name.
#' @param n_runs Number of replicate runs.
#' @param n_years Number of years per run.
#' @param initial_n Integer vector of length 2 giving starting individuals per patch.
#' @param K_patches Numeric vector of length 2 giving patch-specific carrying capacities.
#' @param dispersal_matrix 2x2 matrix of movement probabilities (rows origin, columns destination).
#' @inheritParams scenario_spec
#'
#' @return An `openpva_scenario`.
#' @export
make_two_patch_spatial_scenario <- function(
    name,
    n_runs,
    n_years,
    initial_n = c(50L, 50L),
    K_patches = c(80, 80),
    dispersal_matrix = matrix(c(0.9, 0.1,
                                0.1, 0.9),
                              nrow = 2, byrow = TRUE),
    survival_fun = default_survival_fun,
    breeding_fun = default_breeding_fun,
    fecundity_fun = default_fecundity_fun,
    lifecycle_steps = c("age", "survival", "dispersal", "breeding_births", "harvest")) {
  .assert_positive_int <- function(value, label) {
    if (!is.numeric(value) || length(value) != 1L || value <= 0) {
      stop(label, " must be a positive numeric value", call. = FALSE)
    }
  }
  .assert_positive_int(n_runs, "n_runs")
  .assert_positive_int(n_years, "n_years")
  if (length(initial_n) != 2L || any(initial_n < 0)) {
    stop("initial_n must be a length-2 vector with non-negative entries", call. = FALSE)
  }
  if (length(K_patches) != 2L || any(K_patches <= 0)) {
    stop("K_patches must be a length-2 vector with values > 0", call. = FALSE)
  }

  init_fun <- function() {
    total_n <- sum(as.integer(initial_n))
    pop <- initialize_population(n = total_n)
    patch_ids <- c(
      rep.int(1L, initial_n[1]),
      rep.int(2L, initial_n[2])
    )
    initialize_patches(pop, patch_ids = patch_ids)
  }

  dispersal_fun <- make_markov_dispersal_fun(dispersal_matrix)

  scenario_spec(
    name = name,
    n_runs = n_runs,
    n_years = n_years,
    init_fun = init_fun,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun,
    K = NULL,
    K_patches = K_patches,
    harvest_quota = NULL,
    lifecycle_steps = lifecycle_steps,
    mating_fun = default_mating_fun,
    inherit_fun = NULL,
    dispersal_fun = dispersal_fun
  )
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
#' The YAML may optionally include a `demography` block with nested
#' `survival$table`, `breeding$table`, and `fecundity$table`, each listing rows
#' matching the corresponding validation helpers (e.g. columns `age_min`,
#' `age_max`, `sex`, and `p_surv`/`can_breed`/`lambda`). When present, these
#' tables are compiled into functions via
#' `build_survival_fun_from_table()`, `build_breeding_fun_from_table()`, and
#' `build_fecundity_fun_from_table()`, overriding any function-name fields at
#' the top level.
#'
#' Survival environmental variation and catastrophes can be set via top-level
#' keys `env_surv_sd`, `cat_surv_prob`, and `cat_surv_mult`.
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
    if (is.null(args)) {
      args <- list()
    } else {
      if (!is.list(args)) stop("initializer$args must be a named list")
      args <- as.list(args)
    }
    do.call(f, args)
  }

  survival_fun_name <- cfg$survival_fun %||% "default_survival_fun"
  breeding_fun_name <- cfg$breeding_fun %||% "default_breeding_fun"
  fecundity_fun_name <- cfg$fecundity_fun %||% "default_fecundity_fun"
  survival_fun <- .resolve_function(survival_fun_name)
  breeding_fun <- .resolve_function(breeding_fun_name)
  fecundity_fun <- .resolve_function(fecundity_fun_name)

  lifecycle_steps <- cfg$lifecycle_steps %||% default_lifecycle_steps()
  lifecycle_steps <- unlist(lifecycle_steps)

  management <- cfg$management %||% list()
  harvest_quota <- if (!is.null(management$harvest_quota)) management$harvest_quota else cfg$harvest_quota
  supplement_quota <- management$supplement_quota %||% NULL
  supplement_patch <- management$supplement_patch %||% NULL

  demography <- cfg$demography %||% NULL

  to_df <- function(tbl) {
    if (is.null(tbl)) return(NULL)
    if (is.data.frame(tbl)) return(tbl)
    if (is.list(tbl)) return(dplyr::bind_rows(tbl))
    stop("Demography tables must be data frames or lists", call. = FALSE)
  }

  if (!is.null(demography$survival$table)) {
    surv_tbl <- to_df(demography$survival$table)
    surv_tbl <- validate_survival_table(surv_tbl)
    survival_fun <- build_survival_fun_from_table(surv_tbl)
  }
  if (!is.null(demography$breeding$table)) {
    breed_tbl <- to_df(demography$breeding$table)
    breed_tbl <- validate_breeding_table(breed_tbl)
    breeding_fun <- build_breeding_fun_from_table(breed_tbl)
  }
  if (!is.null(demography$fecundity$table)) {
    fec_tbl <- to_df(demography$fecundity$table)
    fec_tbl <- validate_fecundity_table(fec_tbl)
    fecundity_fun <- build_fecundity_fun_from_table(fec_tbl)
  }

  env_surv_sd <- cfg$env_surv_sd %||% 0
  cat_surv_prob <- cfg$cat_surv_prob %||% 0
  cat_surv_mult <- cfg$cat_surv_mult %||% 1

  env_surv_sd <- as.numeric(env_surv_sd)
  if (length(env_surv_sd) != 1L || is.na(env_surv_sd) || env_surv_sd < 0) {
    stop("env_surv_sd must be a non-negative numeric value", call. = FALSE)
  }
  cat_surv_prob <- as.numeric(cat_surv_prob)
  if (length(cat_surv_prob) != 1L || is.na(cat_surv_prob) ||
      cat_surv_prob < 0 || cat_surv_prob > 1) {
    stop("cat_surv_prob must be within [0, 1]", call. = FALSE)
  }
  cat_surv_mult <- as.numeric(cat_surv_mult)
  if (length(cat_surv_mult) != 1L || is.na(cat_surv_mult) || cat_surv_mult < 0) {
    stop("cat_surv_mult must be a numeric value >= 0", call. = FALSE)
  }

  scenario_spec(
    name = cfg$name,
    n_runs = cfg$n_runs,
    n_years = cfg$n_years,
    init_fun = init_fun,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun,
    K = cfg$K,
    K_patches = cfg$K_patches %||% NULL,
    harvest_quota = harvest_quota,
    lifecycle_steps = lifecycle_steps,
    supplement_quota = supplement_quota,
    supplement_patch = supplement_patch,
    env_surv_sd = env_surv_sd,
    cat_surv_prob = cat_surv_prob,
    cat_surv_mult = cat_surv_mult
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
  if (!is.null(scenario$K) && !is.null(scenario$K_patches)) {
    stop("Specify either K or K_patches in scenario_spec(), not both", call. = FALSE)
  }
  if (!is.null(scenario$K_patches)) {
    if (!is.numeric(scenario$K_patches) || !length(scenario$K_patches) ||
        any(scenario$K_patches <= 0)) {
      stop("K_patches must be NULL or a numeric vector > 0", call. = FALSE)
    }
  }
  if (!is.function(scenario$init_fun)) stop("init_fun must be a function")
  if (!is.function(scenario$survival_fun)) stop("survival_fun must be a function")
  if (!is.function(scenario$breeding_fun)) stop("breeding_fun must be a function")
  if (!is.function(scenario$fecundity_fun)) stop("fecundity_fun must be a function")
  if (!is.function(scenario$mating_fun)) stop("mating_fun must be a function")
  if (!is.null(scenario$inherit_fun) && !is.function(scenario$inherit_fun)) {
    stop("inherit_fun must be NULL or a function")
  }
  if (!is.function(scenario$dispersal_fun)) {
    stop("dispersal_fun must be a function")
  }
  if (!is.null(scenario$supplement_quota)) {
    if (!is.numeric(scenario$supplement_quota) ||
        !length(scenario$supplement_quota) %in% c(1L, scenario$n_years)) {
      stop("supplement_quota must be NULL or numeric of length 1 or n_years", call. = FALSE)
    }
  }
  if (!is.null(scenario$supplement_patch)) {
    scenario$supplement_patch <- as.integer(scenario$supplement_patch)
  }
  env_surv_sd <- as.numeric(scenario$env_surv_sd %||% 0)
  if (length(env_surv_sd) != 1L || is.na(env_surv_sd) || env_surv_sd < 0) {
    stop("env_surv_sd must be a non-negative numeric value", call. = FALSE)
  }
  cat_surv_prob <- as.numeric(scenario$cat_surv_prob %||% 0)
  if (length(cat_surv_prob) != 1L || is.na(cat_surv_prob) ||
      cat_surv_prob < 0 || cat_surv_prob > 1) {
    stop("cat_surv_prob must be within [0, 1]", call. = FALSE)
  }
  cat_surv_mult <- as.numeric(scenario$cat_surv_mult %||% 1)
  if (length(cat_surv_mult) != 1L || is.na(cat_surv_mult) || cat_surv_mult < 0) {
    stop("cat_surv_mult must be a numeric value >= 0", call. = FALSE)
  }
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
    return(utils::getFromNamespace(name, "OpenPVA"))
  }
  match.fun(name)
}

`%||%` <- function(a, b) if (!is.null(a)) a else b
