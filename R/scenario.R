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
#' @param breeding_prob_fun Optional baseline breeding-probability function
#'   returning values in `[0, 1]` for controller-level reproduction draws.
#' @param fecundity_lambda_fun Optional baseline fecundity-mean function
#'   returning `lambda >= 0` for controller-level reproduction draws.
#' @param density_spec Optional density module specification from
#'   [density_spec()]. Defines channel-specific density multipliers for survival,
#'   breeding probability, and fecundity lambda.
#' @param K Optional numeric carrying capacity for density scaling.
#' @param K_patches Optional numeric vector of patch-specific carrying capacities.
#' @param harvest_quota Optional harvest quota (scalar or length `n_years`).
#' @param lifecycle_steps Character vector describing the lifecycle order.
#' @param mating_fun Function used for mate selection (defaults to `default_mating_fun`).
#' @param require_mate Logical; if `TRUE`, females without a selected mate do
#'   not produce offspring in reproduction steps. Defaults to `FALSE` for
#'   backward compatibility.
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
#' @param env_repro_p_sd Standard deviation of a lognormal year-level multiplier
#'   on breeding probability in the controller reproduction pathway.
#' @param env_repro_lambda_sd Standard deviation of a lognormal year-level
#'   multiplier on fecundity lambda in the controller reproduction pathway.
#' @param cat_repro_prob Per-year probability of a reproduction catastrophe in
#'   the controller reproduction pathway.
#' @param cat_repro_mult Multiplicative factor applied to breeding probability
#'   and fecundity lambda in reproduction catastrophe years.
#' @param record_population_history Logical; if `TRUE`, each run stores
#'   per-year population snapshots in `population_history` for downstream
#'   spatial/genetic time-series summaries.
#' @param seed Optional integer random seed forwarded to
#'   `run_basic_simulation_replicates()`. When set, replicated scenario outputs
#'   are deterministic and caller RNG state is restored after execution.
#' @param uncertainty_spec Optional uncertainty specification list compatible
#'   with [sample_uncertainty_parameters()]. Used by
#'   [run_scenario_ensemble()] when uncertainty is not supplied explicitly.
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
    breeding_prob_fun = NULL,
    fecundity_lambda_fun = NULL,
    K = NULL,
    K_patches = NULL,
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
    uncertainty_spec = NULL,
    density_spec = NULL) {
  env_surv_sd <- as.numeric(env_surv_sd)
  cat_surv_prob <- as.numeric(cat_surv_prob)
  cat_surv_mult <- as.numeric(cat_surv_mult)
  env_repro_p_sd <- as.numeric(env_repro_p_sd)
  env_repro_lambda_sd <- as.numeric(env_repro_lambda_sd)
  cat_repro_prob <- as.numeric(cat_repro_prob)
  cat_repro_mult <- as.numeric(cat_repro_mult)
  seed <- .normalize_optional_seed(seed)
  scenario <- list(
    name = name,
    n_runs = n_runs,
    n_years = n_years,
    init_fun = init_fun,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun,
    breeding_prob_fun = breeding_prob_fun,
    fecundity_lambda_fun = fecundity_lambda_fun,
    density_spec = density_spec,
    K = K,
    K_patches = K_patches,
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
  scenario <- .validate_scenario(scenario)
  sim_output <- run_basic_simulation_replicates(
    n_runs = scenario$n_runs,
    n_years = scenario$n_years,
    init_fun = scenario$init_fun,
    survival_fun = scenario$survival_fun,
    breeding_fun = scenario$breeding_fun,
    fecundity_fun = scenario$fecundity_fun,
    breeding_prob_fun = scenario$breeding_prob_fun,
    fecundity_lambda_fun = scenario$fecundity_lambda_fun,
    density_spec = scenario$density_spec,
    K = scenario$K,
    K_patches = scenario$K_patches,
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
    lifecycle_steps = c("age", "survival", "dispersal", "breeding_births", "harvest"),
    density_spec = NULL) {
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
    density_spec = density_spec,
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

.normalize_yaml_schema_version <- function(cfg) {
  ver <- cfg$schema_version
  if (is.null(ver)) {
    return(0L)
  }
  if (is.character(ver) && length(ver) == 1L && grepl("^[0-9]+$", ver)) {
    ver <- as.integer(ver)
  }
  if (!is.numeric(ver) || length(ver) != 1L || is.na(ver) ||
      ver < 0 || ver != as.integer(ver)) {
    stop("schema_version must be a non-negative integer (legacy 0 or supported 1/2/3)", call. = FALSE)
  }
  as.integer(ver)
}

.migrate_yaml_legacy_to_v1 <- function(cfg) {
  cfg$schema_version <- 1L
  cfg
}

.validate_yaml_cfg_v1 <- function(cfg) {
  required <- c("name", "n_runs", "n_years")
  missing_required <- required[vapply(required, function(key) is.null(cfg[[key]]), logical(1))]
  if (length(missing_required)) {
    stop(
      "YAML schema_version 1 requires fields: ",
      paste(missing_required, collapse = ", "),
      call. = FALSE
    )
  }
  if (is.null(cfg$initializer) || !is.list(cfg$initializer) || is.null(cfg$initializer$fun)) {
    stop("YAML schema_version 1 requires initializer$fun", call. = FALSE)
  }
  cfg
}

.validate_yaml_cfg_v2 <- function(cfg, allow_uncertainty = FALSE, schema_label = 2L) {
  cfg <- .validate_yaml_cfg_v1(cfg)
  demography <- cfg$demography %||% list()
  demography_breeding_prob <- demography[["breeding_prob"]]
  demography_breeding <- demography[["breeding"]]
  demography_fecundity_lambda <- demography[["fecundity_lambda"]]
  demography_fecundity <- demography[["fecundity"]]

  has_breeding_prob <- !is.null(cfg$breeding_prob_fun) ||
    (!is.null(demography_breeding_prob) && !is.null(demography_breeding_prob[["table"]])) ||
    (!is.null(demography_breeding) && !is.null(demography_breeding[["table"]])) ||
    !is.null(cfg$breeding_fun)
  has_fecundity_lambda <- !is.null(cfg$fecundity_lambda_fun) ||
    (!is.null(demography_fecundity_lambda) && !is.null(demography_fecundity_lambda[["table"]])) ||
    (!is.null(demography_fecundity) && !is.null(demography_fecundity[["table"]])) ||
    !is.null(cfg$fecundity_fun)

  if (!has_breeding_prob || !has_fecundity_lambda) {
    stop(
      "YAML schema_version ", schema_label,
      " requires breeding_prob and fecundity_lambda channels ",
      "(functions and/or demography tables).",
      call. = FALSE
    )
  }
  if (!allow_uncertainty && !is.null(cfg$uncertainty)) {
    stop(
      "YAML schema_version 2 does not support an uncertainty block; use schema_version: 3.",
      call. = FALSE
    )
  }
  if (!is.null(cfg$reproduction_ev) && !is.list(cfg$reproduction_ev)) {
    stop(
      "YAML schema_version ", schema_label,
      " field reproduction_ev must be a mapping/list.",
      call. = FALSE
    )
  }

  cfg
}

.validate_yaml_cfg_v3 <- function(cfg) {
  cfg <- .validate_yaml_cfg_v2(cfg, allow_uncertainty = TRUE, schema_label = 3L)
  if (!is.null(cfg$uncertainty) && !is.list(cfg$uncertainty)) {
    stop("YAML schema_version 3 field uncertainty must be a mapping/list.", call. = FALSE)
  }
  cfg
}

.migrate_yaml_v1_to_v2 <- function(cfg) {
  to_df <- function(tbl) {
    if (is.null(tbl)) return(NULL)
    if (is.data.frame(tbl)) return(tbl)
    if (is.list(tbl)) return(dplyr::bind_rows(tbl))
    stop("Demography tables must be data frames or lists", call. = FALSE)
  }

  cfg_out <- cfg
  cfg_out$schema_version <- 2L

  demography <- cfg_out$demography %||% list()
  demography_breeding_prob <- demography[["breeding_prob"]]
  demography_breeding <- demography[["breeding"]]
  demography_fecundity_lambda <- demography[["fecundity_lambda"]]
  demography_fecundity <- demography[["fecundity"]]

  if ((is.null(demography_breeding_prob) || is.null(demography_breeding_prob[["table"]])) &&
      !is.null(demography_breeding) && !is.null(demography_breeding[["table"]])) {
    breed_tbl <- to_df(demography_breeding[["table"]])
    breed_tbl <- validate_breeding_table(breed_tbl)
    demography$breeding_prob <- list(
      table = dplyr::transmute(
        breed_tbl,
        age_min = .data$age_min,
        age_max = .data$age_max,
        sex = .data$sex,
        p_breed = as.numeric(.data$can_breed)
      )
    )
  }

  if ((is.null(demography_fecundity_lambda) || is.null(demography_fecundity_lambda[["table"]])) &&
      !is.null(demography_fecundity) && !is.null(demography_fecundity[["table"]])) {
    fec_tbl <- to_df(demography_fecundity[["table"]])
    fec_tbl <- validate_fecundity_table(fec_tbl)
    demography$fecundity_lambda <- list(
      table = dplyr::transmute(
        fec_tbl,
        age_min = .data$age_min,
        age_max = .data$age_max,
        sex = .data$sex,
        lambda = .data$lambda
      )
    )
  }
  cfg_out$demography <- demography

  if (is.null(cfg_out$reproduction_ev)) {
    cfg_out$reproduction_ev <- list()
  }
  if (!is.null(cfg_out$env_repro_p_sd) && is.null(cfg_out$reproduction_ev$env_repro_p_sd)) {
    cfg_out$reproduction_ev$env_repro_p_sd <- cfg_out$env_repro_p_sd
  }
  if (!is.null(cfg_out$env_repro_lambda_sd) && is.null(cfg_out$reproduction_ev$env_repro_lambda_sd)) {
    cfg_out$reproduction_ev$env_repro_lambda_sd <- cfg_out$env_repro_lambda_sd
  }
  if (!is.null(cfg_out$cat_repro_prob) && is.null(cfg_out$reproduction_ev$cat_repro_prob)) {
    cfg_out$reproduction_ev$cat_repro_prob <- cfg_out$cat_repro_prob
  }
  if (!is.null(cfg_out$cat_repro_mult) && is.null(cfg_out$reproduction_ev$cat_repro_mult)) {
    cfg_out$reproduction_ev$cat_repro_mult <- cfg_out$cat_repro_mult
  }

  cfg_out
}

.migrate_yaml_v2_to_v3 <- function(cfg) {
  cfg_out <- cfg
  cfg_out$schema_version <- 3L
  if (is.null(cfg_out$uncertainty)) {
    cfg_out$uncertainty <- NULL
  }
  cfg_out
}

.parse_uncertainty_yaml <- function(uncertainty_cfg) {
  if (is.null(uncertainty_cfg)) {
    return(NULL)
  }
  if (!is.list(uncertainty_cfg)) {
    stop("uncertainty must be a mapping/list", call. = FALSE)
  }

  uncertainty_params <- uncertainty_cfg[["params"]] %||% uncertainty_cfg
  if (is.null(uncertainty_params)) {
    return(NULL)
  }
  if (!is.list(uncertainty_params)) {
    stop("uncertainty$params must be a mapping/list", call. = FALSE)
  }
  if (!length(uncertainty_params)) {
    return(NULL)
  }
  .validate_uncertainty_spec(uncertainty_params)
}

.parse_density_channel_yaml <- function(channel_cfg, channel_label) {
  if (is.null(channel_cfg)) {
    return(NULL)
  }

  if (is.character(channel_cfg) && length(channel_cfg) == 1L) {
    return(.resolve_function(channel_cfg))
  }

  if (is.numeric(channel_cfg) && length(channel_cfg) == 1L) {
    mult <- as.numeric(channel_cfg)
    if (is.na(mult) || !is.finite(mult) || mult < 0) {
      stop("density.", channel_label, " numeric shortcut must be a finite value >= 0", call. = FALSE)
    }
    return(function(population, ind) mult)
  }

  if (!is.list(channel_cfg)) {
    stop(
      "density.", channel_label,
      " must be a mapping/list, numeric multiplier, or function reference",
      call. = FALSE
    )
  }

  model <- channel_cfg[["model"]] %||% NULL
  fun_ref <- channel_cfg[["fun"]] %||% NULL
  multiplier <- channel_cfg[["multiplier"]] %||% NULL
  K <- channel_cfg[["K"]] %||% NULL
  K_patches <- channel_cfg[["K_patches"]] %||% NULL

  if (!is.null(fun_ref)) {
    if (!is.null(model) || !is.null(multiplier) || !is.null(K) || !is.null(K_patches)) {
      stop(
        "density.", channel_label,
        " with `fun` cannot also define model/multiplier/K/K_patches",
        call. = FALSE
      )
    }
    return(.resolve_function(fun_ref))
  }

  if (is.null(model)) {
    if (!is.null(multiplier)) {
      model <- "constant"
    } else if (!is.null(K) || !is.null(K_patches)) {
      model <- "ceiling"
    } else {
      stop(
        "density.", channel_label,
        " must define either `fun` or `model`",
        call. = FALSE
      )
    }
  }

  if (!is.character(model) || length(model) != 1L) {
    stop("density.", channel_label, ".model must be a character scalar", call. = FALSE)
  }
  model <- tolower(trimws(model))

  if (model == "constant") {
    if (is.null(multiplier)) {
      stop("density.", channel_label, ".multiplier is required for model='constant'", call. = FALSE)
    }
    if (!is.numeric(multiplier) || length(multiplier) != 1L) {
      stop("density.", channel_label, ".multiplier must be a numeric scalar", call. = FALSE)
    }
    mult <- as.numeric(multiplier)
    if (is.na(mult) || !is.finite(mult) || mult < 0) {
      stop("density.", channel_label, ".multiplier must be a finite value >= 0", call. = FALSE)
    }
    return(function(population, ind) mult)
  }

  if (model == "ceiling") {
    if (!is.null(multiplier)) {
      stop("density.", channel_label, " model='ceiling' does not use multiplier", call. = FALSE)
    }
    return(make_ceiling_density_fun(K = K, K_patches = K_patches))
  }

  stop(
    "density.", channel_label,
    ".model must be one of 'constant' or 'ceiling'",
    call. = FALSE
  )
}

.build_density_spec_from_yaml <- function(density_cfg) {
  if (is.null(density_cfg)) {
    return(NULL)
  }
  if (!is.list(density_cfg)) {
    stop("density must be a mapping/list", call. = FALSE)
  }

  allowed <- c("survival", "breeding", "fecundity", "K", "K_patches")
  unknown <- setdiff(names(density_cfg), allowed)
  if (length(unknown)) {
    stop(
      "density has unknown fields: ",
      paste(unknown, collapse = ", "),
      call. = FALSE
    )
  }

  density_K <- density_cfg[["K"]] %||% NULL
  density_K_patches <- density_cfg[["K_patches"]] %||% NULL
  has_legacy_shorthand <- !is.null(density_K) || !is.null(density_K_patches)
  if (!is.null(density_cfg[["survival"]]) && has_legacy_shorthand) {
    stop("density cannot combine survival channel config with shorthand K/K_patches", call. = FALSE)
  }

  survival_cfg <- density_cfg[["survival"]] %||% NULL
  if (is.null(survival_cfg) && has_legacy_shorthand) {
    survival_cfg <- list(
      model = "ceiling",
      K = density_K,
      K_patches = density_K_patches
    )
  }

  survival_fun <- .parse_density_channel_yaml(survival_cfg, "survival")
  breeding_fun <- .parse_density_channel_yaml(density_cfg[["breeding"]] %||% NULL, "breeding")
  fecundity_fun <- .parse_density_channel_yaml(density_cfg[["fecundity"]] %||% NULL, "fecundity")

  if (is.null(survival_fun) && is.null(breeding_fun) && is.null(fecundity_fun)) {
    stop(
      "density must define at least one channel (survival, breeding, fecundity) ",
      "or shorthand K/K_patches",
      call. = FALSE
    )
  }

  density_spec(
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun
  )
}

#' Read a scenario specification from YAML
#'
#' Parses a YAML file describing a scenario and returns an
#' `openpva_scenario` object.
#'
#' @param path Path to a YAML file.
#'
#' YAML schema versioning:
#' - `schema_version: 3` is the current uncertainty-capable schema.
#' - `schema_version: 2` remains supported for backward compatibility.
#' - `schema_version: 1` remains supported for backward compatibility.
#' - missing `schema_version` is treated as legacy schema 0 and migrated to v1.
#' - unknown future versions are rejected with an explicit error.
#'
#' The YAML may optionally include a `demography` block with nested
#' `survival$table`, `breeding_prob$table`, and `fecundity_lambda$table` in
#' schema v2. Schema v1 table keys `breeding$table` and `fecundity$table`
#' remain supported and are adapted to the v2 reproduction channels during
#' parsing. Table rows must match the corresponding validation helpers (for
#' example `age_min`, `age_max`, `sex`, and `p_surv`/`p_breed`/`lambda`).
#'
#' Survival environmental variation and catastrophes can be set via top-level
#' keys `env_surv_sd`, `cat_surv_prob`, and `cat_surv_mult`.
#' Optional reproduction-controller function keys are `breeding_prob_fun` and
#' `fecundity_lambda_fun`.
#' Optional lifecycle-function keys are `mating_fun`, `dispersal_fun`, and
#' `inherit_fun`.
#'
#' In schema v2, reproduction environmental variation and catastrophes are
#' configured under `reproduction_ev`:
#' `reproduction_ev$env_repro_p_sd`, `reproduction_ev$env_repro_lambda_sd`,
#' `reproduction_ev$cat_repro_prob`, and `reproduction_ev$cat_repro_mult`.
#' Legacy top-level forms of these keys are still accepted and migrated.
#'
#' In schema v3, an optional `uncertainty` block can be provided with either:
#' - direct parameter mapping:
#'   - `uncertainty.<parameter_name>.<dist/fields>`
#' - nested mapping:
#'   - `uncertainty.params.<parameter_name>.<dist/fields>`
#' The uncertainty mapping is parsed into `scenario$uncertainty_spec` for use
#' with [run_scenario_ensemble()].
#'
#' Density configuration can be supplied via an optional `density` block:
#' - `density.survival`, `density.breeding`, `density.fecundity`
#' - each channel supports either:
#'   - `fun`: function name/reference,
#'   - `model: constant` + `multiplier`,
#'   - `model: ceiling` + `K` or `K_patches`.
#' - shorthand `density.K` / `density.K_patches` maps to
#'   `density.survival` with `model: ceiling`.
#' Legacy top-level `K`/`K_patches` remain supported but cannot be combined with
#' an explicit `density` block in the same YAML file.
#' An optional top-level `seed` can be supplied for deterministic replicate
#' outputs.
#' An optional top-level `require_mate` logical controls whether unmated
#' females can produce offspring (`FALSE`, legacy default) or are skipped
#' during reproduction (`TRUE`).
#' An optional top-level `record_population_history` logical can be set to
#' `TRUE` to retain per-year population snapshots in scenario outputs for
#' spatial/genetic time-series summary helpers.
#'
#' @return An `openpva_scenario` object.
#' @export
read_scenario_yaml <- function(path) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required to read scenario YAML files. Please install it.", call. = FALSE)
  }
  cfg <- yaml::read_yaml(path)
  if (is.null(cfg) || !is.list(cfg)) {
    stop("YAML scenario file must parse to a named list.", call. = FALSE)
  }

  schema_version <- .normalize_yaml_schema_version(cfg)
  if (schema_version == 0L) {
    cfg <- .migrate_yaml_legacy_to_v1(cfg)
    schema_version <- 1L
  }

  if (schema_version == 1L) {
    cfg <- .validate_yaml_cfg_v1(cfg)
  } else if (schema_version == 2L) {
    cfg <- .migrate_yaml_v1_to_v2(cfg)
    cfg <- .validate_yaml_cfg_v2(cfg)
  } else if (schema_version == 3L) {
    cfg <- .migrate_yaml_v1_to_v2(cfg)
    cfg <- .migrate_yaml_v2_to_v3(cfg)
    cfg <- .validate_yaml_cfg_v3(cfg)
  } else {
    stop(
      "Unsupported schema_version: ", schema_version,
      ". Supported versions are 0 (legacy), 1, 2, and 3.",
      call. = FALSE
    )
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
  breeding_prob_fun_name <- cfg$breeding_prob_fun %||% NULL
  fecundity_lambda_fun_name <- cfg$fecundity_lambda_fun %||% NULL
  mating_fun_name <- cfg$mating_fun %||% "default_mating_fun"
  dispersal_fun_name <- cfg$dispersal_fun %||% "default_dispersal_fun"
  inherit_fun_name <- cfg$inherit_fun %||% NULL
  survival_fun <- .resolve_function(survival_fun_name)
  breeding_fun <- .resolve_function(breeding_fun_name)
  fecundity_fun <- .resolve_function(fecundity_fun_name)
  breeding_prob_fun <- if (is.null(breeding_prob_fun_name)) NULL else .resolve_function(breeding_prob_fun_name)
  fecundity_lambda_fun <- if (is.null(fecundity_lambda_fun_name)) NULL else .resolve_function(fecundity_lambda_fun_name)
  mating_fun <- .resolve_function(mating_fun_name)
  dispersal_fun <- .resolve_function(dispersal_fun_name)
  inherit_fun <- if (is.null(inherit_fun_name)) NULL else .resolve_function(inherit_fun_name)
  if (schema_version >= 2L) {
    if (is.null(breeding_prob_fun) && !is.null(cfg$breeding_fun)) {
      breeding_prob_fun <- as_breeding_prob_fun(breeding_fun)
    }
    if (is.null(fecundity_lambda_fun) && !is.null(cfg$fecundity_fun)) {
      fecundity_lambda_fun <- as_fecundity_lambda_fun(fecundity_fun)
    }
  }

  lifecycle_steps <- cfg$lifecycle_steps %||% default_lifecycle_steps()
  lifecycle_steps <- unlist(lifecycle_steps)

  management <- cfg$management %||% list()
  harvest_quota <- if (!is.null(management$harvest_quota)) management$harvest_quota else cfg$harvest_quota
  supplement_quota <- management$supplement_quota %||% NULL
  supplement_patch <- management$supplement_patch %||% NULL

  demography <- cfg$demography %||% NULL
  demography_survival <- if (is.null(demography)) NULL else demography[["survival"]]
  demography_breeding <- if (is.null(demography)) NULL else demography[["breeding"]]
  demography_fecundity <- if (is.null(demography)) NULL else demography[["fecundity"]]
  demography_breeding_prob <- if (is.null(demography)) NULL else demography[["breeding_prob"]]
  demography_fecundity_lambda <- if (is.null(demography)) NULL else demography[["fecundity_lambda"]]

  to_df <- function(tbl) {
    if (is.null(tbl)) return(NULL)
    if (is.data.frame(tbl)) return(tbl)
    if (is.list(tbl)) return(dplyr::bind_rows(tbl))
    stop("Demography tables must be data frames or lists", call. = FALSE)
  }

  if (!is.null(demography_survival) && !is.null(demography_survival[["table"]])) {
    surv_tbl <- to_df(demography_survival[["table"]])
    surv_tbl <- validate_survival_table(surv_tbl)
    survival_fun <- build_survival_fun_from_table(surv_tbl)
  }
  if (!is.null(demography_breeding) && !is.null(demography_breeding[["table"]])) {
    breed_tbl <- to_df(demography_breeding[["table"]])
    breed_tbl <- validate_breeding_table(breed_tbl)
    breeding_fun <- build_breeding_fun_from_table(breed_tbl)
    if (is.null(breeding_prob_fun)) {
      breeding_prob_fun <- as_breeding_prob_fun(breeding_fun)
    }
  }
  if (!is.null(demography_fecundity) && !is.null(demography_fecundity[["table"]])) {
    fec_tbl <- to_df(demography_fecundity[["table"]])
    fec_tbl <- validate_fecundity_table(fec_tbl)
    fecundity_fun <- build_fecundity_fun_from_table(fec_tbl)
    if (is.null(fecundity_lambda_fun)) {
      fecundity_lambda_fun <- build_fecundity_lambda_fun_from_table(fec_tbl)
    }
  }
  if (!is.null(demography_breeding_prob) && !is.null(demography_breeding_prob[["table"]])) {
    breed_prob_tbl <- to_df(demography_breeding_prob[["table"]])
    breed_prob_tbl <- validate_breeding_prob_table(breed_prob_tbl)
    breeding_prob_fun <- build_breeding_prob_fun_from_table(breed_prob_tbl)
    breeding_fun <- as_breeding_fun(breeding_prob_fun)
  }
  if (!is.null(demography_fecundity_lambda) && !is.null(demography_fecundity_lambda[["table"]])) {
    fec_lambda_tbl <- to_df(demography_fecundity_lambda[["table"]])
    fec_lambda_tbl <- validate_fecundity_lambda_table(fec_lambda_tbl)
    fecundity_lambda_fun <- build_fecundity_lambda_fun_from_table(fec_lambda_tbl)
    fecundity_fun <- as_fecundity_fun(fecundity_lambda_fun)
  }

  env_surv_sd <- cfg$env_surv_sd %||% 0
  cat_surv_prob <- cfg$cat_surv_prob %||% 0
  cat_surv_mult <- cfg$cat_surv_mult %||% 1
  repro_ev <- cfg$reproduction_ev %||% list()
  if (!is.list(repro_ev)) {
    stop("reproduction_ev must be a mapping/list", call. = FALSE)
  }
  env_repro_p_sd <- repro_ev$env_repro_p_sd %||% cfg$env_repro_p_sd %||% 0
  env_repro_lambda_sd <- repro_ev$env_repro_lambda_sd %||% cfg$env_repro_lambda_sd %||% 0
  cat_repro_prob <- repro_ev$cat_repro_prob %||% cfg$cat_repro_prob %||% 0
  cat_repro_mult <- repro_ev$cat_repro_mult %||% cfg$cat_repro_mult %||% 1
  uncertainty_spec <- NULL
  if (schema_version >= 3L) {
    uncertainty_spec <- .parse_uncertainty_yaml(cfg$uncertainty %||% NULL)
  }
  density_spec <- .build_density_spec_from_yaml(cfg$density %||% NULL)
  require_mate <- cfg$require_mate %||% FALSE
  record_population_history <- cfg$record_population_history %||% FALSE
  seed <- cfg$seed %||% NULL

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
  env_repro_p_sd <- as.numeric(env_repro_p_sd)
  if (length(env_repro_p_sd) != 1L || is.na(env_repro_p_sd) || env_repro_p_sd < 0) {
    stop("env_repro_p_sd must be a non-negative numeric value", call. = FALSE)
  }
  env_repro_lambda_sd <- as.numeric(env_repro_lambda_sd)
  if (length(env_repro_lambda_sd) != 1L || is.na(env_repro_lambda_sd) || env_repro_lambda_sd < 0) {
    stop("env_repro_lambda_sd must be a non-negative numeric value", call. = FALSE)
  }
  cat_repro_prob <- as.numeric(cat_repro_prob)
  if (length(cat_repro_prob) != 1L || is.na(cat_repro_prob) ||
      cat_repro_prob < 0 || cat_repro_prob > 1) {
    stop("cat_repro_prob must be within [0, 1]", call. = FALSE)
  }
  cat_repro_mult <- as.numeric(cat_repro_mult)
  if (length(cat_repro_mult) != 1L || is.na(cat_repro_mult) || cat_repro_mult < 0) {
    stop("cat_repro_mult must be a numeric value >= 0", call. = FALSE)
  }
  if (!is.logical(require_mate) || length(require_mate) != 1L || is.na(require_mate)) {
    stop("require_mate must be a logical scalar", call. = FALSE)
  }
  if (!is.logical(record_population_history) ||
      length(record_population_history) != 1L ||
      is.na(record_population_history)) {
    stop("record_population_history must be a logical scalar", call. = FALSE)
  }
  if (!is.null(density_spec) && (!is.null(cfg$K) || !is.null(cfg$K_patches))) {
    stop("YAML cannot combine density block with top-level K/K_patches", call. = FALSE)
  }

  scenario <- scenario_spec(
    name = cfg$name,
    n_runs = cfg$n_runs,
    n_years = cfg$n_years,
    init_fun = init_fun,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun,
    breeding_prob_fun = breeding_prob_fun,
    fecundity_lambda_fun = fecundity_lambda_fun,
    K = cfg$K,
    K_patches = cfg$K_patches %||% NULL,
    harvest_quota = harvest_quota,
    lifecycle_steps = lifecycle_steps,
    mating_fun = mating_fun,
    inherit_fun = inherit_fun,
    dispersal_fun = dispersal_fun,
    require_mate = require_mate,
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
    uncertainty_spec = uncertainty_spec,
    density_spec = density_spec
  )
  attr(scenario, "yaml_schema_version") <- schema_version
  scenario
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
  if (!is.null(scenario$density_spec) &&
      (!is.null(scenario$K) || !is.null(scenario$K_patches))) {
    stop("Specify either density_spec or K/K_patches in scenario_spec(), not both", call. = FALSE)
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
  if (!is.null(scenario$breeding_prob_fun) && !is.function(scenario$breeding_prob_fun)) {
    stop("breeding_prob_fun must be NULL or a function")
  }
  if (!is.null(scenario$fecundity_lambda_fun) && !is.function(scenario$fecundity_lambda_fun)) {
    stop("fecundity_lambda_fun must be NULL or a function")
  }
  if (!is.null(scenario$uncertainty_spec)) {
    scenario$uncertainty_spec <- .validate_uncertainty_spec(scenario$uncertainty_spec)
  }
  if (!is.null(scenario$density_spec)) {
    scenario$density_spec <- validate_density_spec(scenario$density_spec)
  }
  if (!is.function(scenario$mating_fun)) stop("mating_fun must be a function")
  require_mate <- scenario$require_mate %||% FALSE
  if (!is.logical(require_mate) || length(require_mate) != 1L || is.na(require_mate)) {
    stop("require_mate must be a single logical value", call. = FALSE)
  }
  scenario$require_mate <- require_mate
  record_population_history <- scenario$record_population_history %||% FALSE
  if (!is.logical(record_population_history) ||
      length(record_population_history) != 1L ||
      is.na(record_population_history)) {
    stop("record_population_history must be a single logical value", call. = FALSE)
  }
  scenario$record_population_history <- record_population_history
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
  env_repro_p_sd <- as.numeric(scenario$env_repro_p_sd %||% 0)
  if (length(env_repro_p_sd) != 1L || is.na(env_repro_p_sd) || env_repro_p_sd < 0) {
    stop("env_repro_p_sd must be a non-negative numeric value", call. = FALSE)
  }
  env_repro_lambda_sd <- as.numeric(scenario$env_repro_lambda_sd %||% 0)
  if (length(env_repro_lambda_sd) != 1L || is.na(env_repro_lambda_sd) || env_repro_lambda_sd < 0) {
    stop("env_repro_lambda_sd must be a non-negative numeric value", call. = FALSE)
  }
  cat_repro_prob <- as.numeric(scenario$cat_repro_prob %||% 0)
  if (length(cat_repro_prob) != 1L || is.na(cat_repro_prob) ||
      cat_repro_prob < 0 || cat_repro_prob > 1) {
    stop("cat_repro_prob must be within [0, 1]", call. = FALSE)
  }
  cat_repro_mult <- as.numeric(scenario$cat_repro_mult %||% 1)
  if (length(cat_repro_mult) != 1L || is.na(cat_repro_mult) || cat_repro_mult < 0) {
    stop("cat_repro_mult must be a numeric value >= 0", call. = FALSE)
  }
  scenario$seed <- .normalize_optional_seed(scenario$seed %||% NULL)
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
