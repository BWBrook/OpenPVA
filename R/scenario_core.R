#' Create a simulation scenario specification
#'
#' Defines a reusable scenario that can be executed with [run_scenario()].
#'
#' @param name Scenario name (character scalar).
#' @param n_runs Number of replicate runs.
#' @param n_years Number of years per run.
#' @param init_fun Function that initialises a population when called.
#' @param survival_fun Function returning survival probabilities.
#' @param breeding_prob_fun Baseline breeding-probability function returning
#'   values in `[0, 1]`.
#' @param fecundity_lambda_fun Baseline fecundity-mean function returning
#'   `lambda >= 0`.
#' @param density_spec Optional density specification created by
#'   [density_spec()].
#' @param harvest_quota Optional harvest quota (scalar or length `n_years`).
#' @param lifecycle_steps Character vector describing the lifecycle order.
#' @param mating_fun Function used for mate selection.
#' @param require_mate Logical; if `TRUE`, females without a selected mate do
#'   not produce offspring in reproduction steps.
#' @param inherit_fun Optional function for generating offspring genotypes.
#' @param dispersal_fun Function controlling movement between patches.
#' @param supplement_quota Optional numeric scalar or vector (length `n_years`)
#'   giving supplementation quotas for the `"supplementation"` lifecycle step.
#' @param supplement_patch Optional patch identifier assigned to all added
#'   individuals (defaults to `NA`).
#' @param env_surv_sd Standard deviation of a lognormal year-level multiplier on
#'   survival.
#' @param cat_surv_prob Per-year probability of a catastrophic survival event.
#' @param cat_surv_mult Multiplicative factor applied to survival probabilities
#'   in catastrophe years.
#' @param env_repro_p_sd Standard deviation of a lognormal year-level multiplier
#'   on breeding probability.
#' @param env_repro_lambda_sd Standard deviation of a lognormal year-level
#'   multiplier on fecundity lambda.
#' @param cat_repro_prob Per-year probability of a reproduction catastrophe.
#' @param cat_repro_mult Multiplicative factor applied to breeding probability
#'   and fecundity lambda in reproduction catastrophe years.
#' @param record_population_history Logical; if `TRUE`, each run stores per-year
#'   population snapshots in `population_history`.
#' @param seed Optional integer random seed forwarded to
#'   [run_basic_simulation_replicates()].
#' @param uncertainty_spec Optional uncertainty specification list compatible
#'   with [sample_uncertainty_parameters()].
#'
#' @return An object of class `openpva_scenario`.
#' @export
scenario_spec <- function(
    name,
    n_runs,
    n_years,
    init_fun,
    survival_fun = default_survival_fun,
    breeding_prob_fun = default_breeding_prob_fun,
    fecundity_lambda_fun = default_fecundity_lambda_fun,
    density_spec = NULL,
    harvest_quota = NULL,
    lifecycle_steps = default_lifecycle_steps(),
    mating_fun = default_mating_fun,
    require_mate = FALSE,
    inherit_fun = NULL,
    dispersal_fun = default_dispersal_fun,
    supplement_quota = NULL,
    supplement_patch = NULL,
    env_surv_sd = 0,
    cat_surv_prob = 0,
    cat_surv_mult = 1,
    env_repro_p_sd = 0,
    env_repro_lambda_sd = 0,
    cat_repro_prob = 0,
    cat_repro_mult = 1,
    record_population_history = FALSE,
    seed = NULL,
    uncertainty_spec = NULL) {
  scenario <- list(
    name = name,
    n_runs = n_runs,
    n_years = n_years,
    init_fun = init_fun,
    survival_fun = survival_fun,
    breeding_prob_fun = breeding_prob_fun,
    fecundity_lambda_fun = fecundity_lambda_fun,
    density_spec = density_spec,
    harvest_quota = harvest_quota,
    lifecycle_steps = lifecycle_steps,
    mating_fun = mating_fun,
    require_mate = require_mate,
    inherit_fun = inherit_fun,
    dispersal_fun = dispersal_fun,
    supplement_quota = supplement_quota,
    supplement_patch = supplement_patch,
    env_surv_sd = env_surv_sd,
    cat_surv_prob = cat_surv_prob,
    cat_surv_mult = cat_surv_mult,
    env_repro_p_sd = env_repro_p_sd,
    env_repro_lambda_sd = env_repro_lambda_sd,
    cat_repro_prob = cat_repro_prob,
    cat_repro_mult = cat_repro_mult,
    record_population_history = record_population_history,
    seed = seed,
    uncertainty_spec = uncertainty_spec
  )
  scenario <- .validate_scenario(scenario)
  class(scenario) <- c("openpva_scenario", "list")
  scenario
}

#' Run a simulation scenario
#'
#' Executes a scenario created by [scenario_spec()] via
#' [run_basic_simulation_replicates()].
#'
#' @param scenario An object created by [scenario_spec()].
#'
#' @return A list with elements `scenario` and `sim_output`.
#' @export
run_scenario <- function(scenario) {
  if (!inherits(scenario, "openpva_scenario")) {
    stop("`scenario` must be created by scenario_spec().", call. = FALSE)
  }
  scenario <- .validate_scenario(scenario)
  sim_output <- run_basic_simulation_replicates(
    n_runs = scenario$n_runs,
    n_years = scenario$n_years,
    init_fun = scenario$init_fun,
    survival_fun = scenario$survival_fun,
    breeding_prob_fun = scenario$breeding_prob_fun,
    fecundity_lambda_fun = scenario$fecundity_lambda_fun,
    density_spec = scenario$density_spec,
    harvest_quota = scenario$harvest_quota,
    lifecycle_steps = scenario$lifecycle_steps,
    mating_fun = scenario$mating_fun,
    require_mate = scenario$require_mate,
    inherit_fun = scenario$inherit_fun,
    dispersal_fun = scenario$dispersal_fun,
    supplement_quota = scenario$supplement_quota,
    supplement_patch = scenario$supplement_patch,
    env_surv_sd = scenario$env_surv_sd,
    cat_surv_prob = scenario$cat_surv_prob,
    cat_surv_mult = scenario$cat_surv_mult,
    env_repro_p_sd = scenario$env_repro_p_sd,
    env_repro_lambda_sd = scenario$env_repro_lambda_sd,
    cat_repro_prob = scenario$cat_repro_prob,
    cat_repro_mult = scenario$cat_repro_mult,
    record_population_history = scenario$record_population_history,
    seed = scenario$seed
  )
  list(scenario = scenario, sim_output = sim_output)
}

#' Construct a simple genetics-enabled scenario
#'
#' Provides a convenience wrapper that initialises genotypes, applies
#' inbreeding-aware survival, and enables genotype inheritance for each run.
#'
#' @param name Scenario name.
#' @param n_runs Number of replicate runs.
#' @param n_years Number of years per run.
#' @param initial_n Initial population size for each run.
#' @param n_loci Number of loci per individual.
#' @param n_alleles Number of possible allele states per locus.
#' @param mutation_rate Mutation probability per allele during inheritance.
#' @param beta_F Strength of inbreeding depression passed to
#'   [make_inbreeding_survival_fun()].
#' @param harvest_quota Optional harvest quota (scalar or length `n_years`).
#' @param lifecycle_steps Character vector describing the lifecycle order.
#' @param seed Optional integer random seed forwarded to
#'   [scenario_spec()].
#'
#' @return An `openpva_scenario` ready to run with [run_scenario()].
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
    harvest_quota = NULL,
    lifecycle_steps = default_lifecycle_steps(),
    seed = NULL) {
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
    breeding_prob_fun = default_breeding_prob_fun,
    fecundity_lambda_fun = default_fecundity_lambda_fun,
    harvest_quota = harvest_quota,
    lifecycle_steps = lifecycle_steps,
    mating_fun = default_mating_fun,
    inherit_fun = inherit_fun,
    dispersal_fun = default_dispersal_fun,
    seed = seed
  )
}

#' Construct a simple two-patch spatial scenario
#'
#' Builds a scenario with two patches, patch-specific carrying capacities, and
#' Markov dispersal.
#'
#' @param name Scenario name.
#' @param n_runs Number of replicate runs.
#' @param n_years Number of years per run.
#' @param initial_n Integer vector of length 2 giving starting individuals per
#'   patch.
#' @param K_patches Numeric vector of length 2 giving patch-specific carrying
#'   capacities.
#' @param dispersal_matrix 2x2 matrix of movement probabilities (rows origin,
#'   columns destination).
#' @param survival_fun Function returning survival probabilities.
#' @param breeding_prob_fun Baseline breeding probability function.
#' @param fecundity_lambda_fun Baseline fecundity mean function.
#' @param harvest_quota Optional harvest quota.
#' @param lifecycle_steps Character vector describing the lifecycle order.
#' @param seed Optional integer random seed forwarded to [scenario_spec()].
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
    breeding_prob_fun = default_breeding_prob_fun,
    fecundity_lambda_fun = default_fecundity_lambda_fun,
    harvest_quota = NULL,
    lifecycle_steps = c("age", "survival", "dispersal", "breeding_births", "harvest"),
    seed = NULL) {
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

  scenario_spec(
    name = name,
    n_runs = n_runs,
    n_years = n_years,
    init_fun = init_fun,
    survival_fun = survival_fun,
    breeding_prob_fun = breeding_prob_fun,
    fecundity_lambda_fun = fecundity_lambda_fun,
    density_spec = density_spec(
      survival_fun = make_ceiling_density_fun(K_patches = K_patches)
    ),
    harvest_quota = harvest_quota,
    lifecycle_steps = lifecycle_steps,
    mating_fun = default_mating_fun,
    dispersal_fun = make_markov_dispersal_fun(dispersal_matrix),
    seed = seed
  )
}

#' @export
print.openpva_scenario <- function(x, ...) {
  cat(
    sprintf(
      "<Scenario %s | runs: %d | years: %d | density: %s | harvest: %s | steps: %s>\n",
      x$name,
      as.integer(x$n_runs),
      as.integer(x$n_years),
      if (is.null(x$density_spec)) "none" else "set",
      if (is.null(x$harvest_quota)) "NULL" else "set",
      paste(x$lifecycle_steps, collapse = " -> ")
    )
  )
  invisible(x)
}

.validate_scenario <- function(scenario) {
  if (!is.list(scenario)) {
    stop("scenario must be a list", call. = FALSE)
  }
  if (!is.character(scenario$name) || length(scenario$name) != 1L || !nzchar(scenario$name)) {
    stop("Scenario `name` must be a non-empty character scalar", call. = FALSE)
  }
  for (field in c("n_runs", "n_years")) {
    value <- scenario[[field]]
    if (!is.numeric(value) || length(value) != 1L || value <= 0) {
      stop(field, " must be a positive numeric value", call. = FALSE)
    }
    scenario[[field]] <- as.integer(value)
  }
  if (!is.function(scenario$init_fun)) {
    stop("init_fun must be a function", call. = FALSE)
  }
  if (!is.function(scenario$survival_fun)) {
    stop("survival_fun must be a function", call. = FALSE)
  }
  if (!is.function(scenario$breeding_prob_fun)) {
    stop("breeding_prob_fun must be a function", call. = FALSE)
  }
  if (!is.function(scenario$fecundity_lambda_fun)) {
    stop("fecundity_lambda_fun must be a function", call. = FALSE)
  }
  if (!is.null(scenario$density_spec)) {
    scenario$density_spec <- validate_density_spec(scenario$density_spec)
  }
  if (!is.function(scenario$mating_fun)) {
    stop("mating_fun must be a function", call. = FALSE)
  }
  if (!is.null(scenario$inherit_fun) && !is.function(scenario$inherit_fun)) {
    stop("inherit_fun must be NULL or a function", call. = FALSE)
  }
  if (!is.function(scenario$dispersal_fun)) {
    stop("dispersal_fun must be a function", call. = FALSE)
  }
  require_mate <- scenario$require_mate %||% FALSE
  if (!is.logical(require_mate) || length(require_mate) != 1L || is.na(require_mate)) {
    stop("require_mate must be a single logical value", call. = FALSE)
  }
  record_population_history <- scenario$record_population_history %||% FALSE
  if (!is.logical(record_population_history) ||
      length(record_population_history) != 1L ||
      is.na(record_population_history)) {
    stop("record_population_history must be a single logical value", call. = FALSE)
  }
  if (!is.null(scenario$supplement_quota) &&
      !length(scenario$supplement_quota) %in% c(1L, scenario$n_years)) {
    stop("supplement_quota must be NULL or numeric of length 1 or n_years", call. = FALSE)
  }
  if (!is.null(scenario$supplement_patch)) {
    scenario$supplement_patch <- as.integer(scenario$supplement_patch)
  }
  scenario$env_surv_sd <- .normalize_non_negative_numeric(scenario$env_surv_sd %||% 0, "env_surv_sd")
  scenario$cat_surv_prob <- .normalize_probability(scenario$cat_surv_prob %||% 0, "cat_surv_prob")
  scenario$cat_surv_mult <- .normalize_non_negative_numeric(scenario$cat_surv_mult %||% 1, "cat_surv_mult")
  scenario$env_repro_p_sd <- .normalize_non_negative_numeric(
    scenario$env_repro_p_sd %||% 0,
    "env_repro_p_sd"
  )
  scenario$env_repro_lambda_sd <- .normalize_non_negative_numeric(
    scenario$env_repro_lambda_sd %||% 0,
    "env_repro_lambda_sd"
  )
  scenario$cat_repro_prob <- .normalize_probability(
    scenario$cat_repro_prob %||% 0,
    "cat_repro_prob"
  )
  scenario$cat_repro_mult <- .normalize_non_negative_numeric(
    scenario$cat_repro_mult %||% 1,
    "cat_repro_mult"
  )
  scenario$seed <- .normalize_optional_seed(scenario$seed %||% NULL)
  if (!is.null(scenario$uncertainty_spec)) {
    scenario$uncertainty_spec <- .validate_uncertainty_spec(scenario$uncertainty_spec)
  }
  .validate_lifecycle_steps(scenario$lifecycle_steps)
  invisible(scenario)
}
