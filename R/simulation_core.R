#' Run a basic demographic simulation
#'
#' Applies ageing, survival, density-adjusted reproduction, and optional
#' management processes over multiple years.
#'
#' @param initial_population List of individuals (for example from
#'   [initialize_population()]).
#' @param n_years Integer number of years to simulate (must be `>= 0`).
#' @param survival_fun Function returning survival probabilities for
#'   individuals.
#' @param breeding_prob_fun Baseline breeding-probability function returning
#'   values in `[0, 1]`.
#' @param fecundity_lambda_fun Baseline fecundity-mean function returning
#'   `lambda >= 0`.
#' @param density_spec Optional density module specification from
#'   [density_spec()]. Defines channel-specific density multipliers for
#'   survival, breeding probability, and fecundity lambda.
#' @param harvest_quota Optional harvest quota (single value or length
#'   `n_years` vector). If `lifecycle_steps` omits `"harvest"`, quotas are
#'   ignored.
#' @param lifecycle_steps Character vector of lifecycle step labels describing
#'   the order in which processes occur. Allowed values are `"age"`,
#'   `"survival"`, `"dispersal"`, `"supplementation"`, `"breeding_births"`, and
#'   `"harvest"`.
#' @param mating_fun Function selecting mates for breeding females. Defaults to
#'   [default_mating_fun()].
#' @param require_mate Logical; if `TRUE`, females without a selected mate do
#'   not produce offspring in reproduction steps.
#' @param inherit_fun Optional function taking `(mother, father)` and returning
#'   an allele matrix for newborns (for example
#'   [inherit_genotype_simple()]). Defaults to `NULL`, which leaves newborn
#'   alleles as `NULL`.
#' @param dispersal_fun Function with signature `function(ind, population)`
#'   returning a new `patch_id` for the individual. Defaults to
#'   [default_dispersal_fun()].
#' @param supplement_quota Optional supplementation quota (single value or
#'   length `n_years` vector). Applied only if `"supplementation"` is in
#'   `lifecycle_steps`.
#' @param supplement_patch Optional patch identifier assigned to all
#'   supplemented individuals (defaults to `NA`).
#' @param env_surv_sd Standard deviation of a lognormal year-level multiplier on
#'   survival (environmental variation). Set to `0` to disable.
#' @param cat_surv_prob Per-year probability of a catastrophic survival event
#'   (Bernoulli). Set to `0` to disable.
#' @param cat_surv_mult Multiplicative factor applied to survival probabilities
#'   in catastrophe years.
#' @param env_repro_p_sd Standard deviation of a lognormal year-level multiplier
#'   on breeding probability.
#' @param env_repro_lambda_sd Standard deviation of a lognormal year-level
#'   multiplier on fecundity lambda.
#' @param cat_repro_prob Per-year probability of a reproduction catastrophe.
#' @param cat_repro_mult Multiplicative factor applied to breeding probability
#'   and fecundity lambda in reproduction catastrophe years.
#' @param record_population_history Logical; if `TRUE`, stores a per-year
#'   population snapshot in `population_history`.
#'
#' @return List with the final `population` and a `summary` tibble of yearly
#'   metrics. If `record_population_history = TRUE`, includes
#'   `population_history` (list of length `n_years`) with per-year snapshots.
#' @export
run_basic_simulation <- function(
    initial_population,
    n_years,
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
    record_population_history = FALSE) {
  args <- .normalize_simulation_args(
    n_years = n_years,
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
    record_population_history = record_population_history
  )

  population <- initial_population
  if (args$n_years == 0L) {
    out <- list(population = population, summary = .empty_summary_tibble())
    if (isTRUE(args$record_population_history)) {
      out$population_history <- list()
    }
    return(out)
  }

  summary_rows <- vector("list", args$n_years)
  population_history <- if (isTRUE(args$record_population_history)) {
    vector("list", args$n_years)
  } else {
    NULL
  }

  for (year in seq_len(args$n_years)) {
    year_modifiers <- .draw_year_modifiers(
      env_surv_sd = args$env_surv_sd,
      cat_surv_prob = args$cat_surv_prob,
      cat_surv_mult = args$cat_surv_mult,
      env_repro_p_sd = args$env_repro_p_sd,
      env_repro_lambda_sd = args$env_repro_lambda_sd,
      cat_repro_prob = args$cat_repro_prob,
      cat_repro_mult = args$cat_repro_mult
    )
    counters <- list(
      n_births = 0L,
      n_harvested = 0L,
      n_supplemented = 0L,
      survival_scale = 1
    )

    for (step in args$lifecycle_steps) {
      if (step == "age") {
        population <- age_individuals(population)
      } else if (step == "survival") {
        population <- .apply_survival_step(
          population = population,
          survival_fun = args$survival_fun,
          density_spec = args$density_spec,
          year_modifiers = year_modifiers
        )
      } else if (step == "dispersal") {
        population <- apply_dispersal(population, args$dispersal_fun)
      } else if (step == "supplementation") {
        supplementation <- .apply_supplementation_step(
          population = population,
          quota = args$supplement_vec[[year]],
          patch_id = args$supplement_patch
        )
        population <- supplementation$population
        counters$n_supplemented <- counters$n_supplemented + supplementation$n_added
      } else if (step == "breeding_births") {
        reproduction <- .apply_reproduction_rate_step(
          population = population,
          breeding_prob_fun = args$breeding_prob_fun,
          fecundity_lambda_fun = args$fecundity_lambda_fun,
          density_spec = args$density_spec,
          year_modifiers = year_modifiers,
          mating_fun = args$mating_fun,
          require_mate = args$require_mate,
          inherit_fun = args$inherit_fun
        )
        population <- reproduction$population
        counters$n_births <- counters$n_births + reproduction$n_births
      } else if (step == "harvest") {
        harvest <- .apply_harvest_step(
          population = population,
          quota = args$harvest_vec[[year]]
        )
        population <- harvest$population
        counters$n_harvested <- counters$n_harvested + harvest$n_harvested
      }
    }

    summary_rows[[year]] <- .build_summary_row(
      year = year,
      population = population,
      counters = counters,
      year_modifiers = year_modifiers
    )
    if (isTRUE(args$record_population_history)) {
      population_history[[year]] <- .clone_population(population)
    }
  }

  out <- list(
    population = population,
    summary = .summary_rows_to_tibble(summary_rows)
  )
  if (isTRUE(args$record_population_history)) {
    out$population_history <- population_history
  }
  out
}

#' Run replicated demographic simulations
#'
#' Executes multiple independent runs of [run_basic_simulation()] and collates
#' per-year summaries along with extinction metrics.
#'
#' @param n_runs Integer number of independent simulation runs (must be `>= 1`).
#' @param n_years Integer number of years per run (must be `>= 1`).
#' @param init_fun Function with no arguments that returns an initial
#'   population.
#' @param survival_fun Function returning survival probabilities for
#'   individuals.
#' @param breeding_prob_fun Baseline breeding-probability function returning
#'   values in `[0, 1]`.
#' @param fecundity_lambda_fun Baseline fecundity-mean function returning
#'   `lambda >= 0`.
#' @param density_spec Optional density module specification from
#'   [density_spec()]. Defines channel-specific density multipliers for
#'   survival, breeding probability, and fecundity lambda.
#' @param harvest_quota Optional harvest quota (single value or length
#'   `n_years` vector). If `lifecycle_steps` omits `"harvest"`, quotas are
#'   ignored.
#' @param lifecycle_steps Character vector specifying lifecycle order for each
#'   run.
#' @param mating_fun Function used for mate selection within each run.
#' @param require_mate Logical; if `TRUE`, females without a selected mate do
#'   not produce offspring in reproduction steps.
#' @param inherit_fun Optional inheritance function applied to newborns.
#' @param dispersal_fun Function applied during the `"dispersal"` lifecycle
#'   step.
#' @param supplement_quota Optional supplementation quota (single value or
#'   length `n_years` vector). Applied only if `"supplementation"` is in
#'   `lifecycle_steps`.
#' @param supplement_patch Optional patch identifier assigned to all
#'   supplemented individuals (defaults to `NA`).
#' @param env_surv_sd Standard deviation of a lognormal year-level multiplier on
#'   survival (environmental variation). Set to `0` to disable.
#' @param cat_surv_prob Per-year probability of a catastrophic survival event
#'   (Bernoulli). Set to `0` to disable.
#' @param cat_surv_mult Multiplicative factor applied to survival probabilities
#'   in catastrophe years.
#' @param env_repro_p_sd Standard deviation of a lognormal year-level multiplier
#'   on breeding probability.
#' @param env_repro_lambda_sd Standard deviation of a lognormal year-level
#'   multiplier on fecundity lambda.
#' @param cat_repro_prob Per-year probability of a reproduction catastrophe.
#' @param cat_repro_mult Multiplicative factor applied to breeding probability
#'   and fecundity lambda in reproduction catastrophe years.
#' @param record_population_history Logical; if `TRUE`, each run output includes
#'   a `population_history` list with per-year snapshots.
#' @param seed Optional integer random seed. When provided, replicate runs are
#'   deterministic and the caller RNG state is restored on exit.
#'
#' @return A list with elements:
#'   \itemize{
#'     \item `runs`: list of length `n_runs`, each containing the output of
#'       [run_basic_simulation()].
#'     \item `summary`: tibble with columns `run`, `year`, `n_alive`,
#'       `n_female_alive`, `n_male_alive`, `n_births`, `n_harvested`,
#'       `n_supplemented`, `survival_scale`, `env_surv_mult`, `cat_surv_mult`,
#'       `catastrophe`, `env_repro_p_mult`, `env_repro_lambda_mult`,
#'       `cat_repro_mult`, and `repro_catastrophe`.
#'     \item `extinction`: tibble with columns `run`, `went_extinct`,
#'       `time_to_extinction`.
#'   }
#' @export
run_basic_simulation_replicates <- function(
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
    seed = NULL) {
  n_runs <- .normalize_positive_count(n_runs, "n_runs")
  n_years <- .normalize_positive_count(n_years, "n_years")
  if (!is.function(init_fun)) {
    stop("init_fun must be a function returning an initial population", call. = FALSE)
  }

  seed <- .normalize_optional_seed(seed)
  run_results <- .with_optional_seed(seed, {
    lapply(seq_len(n_runs), function(run_id) {
      run_basic_simulation(
        initial_population = init_fun(),
        n_years = n_years,
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
        record_population_history = record_population_history
      )
    })
  })

  summary_tbl <- purrr::imap_dfr(run_results, function(run_output, idx) {
    tibble::add_column(run_output$summary, run = as.integer(idx), .before = 1)
  })

  list(
    runs = run_results,
    summary = summary_tbl,
    extinction = .summarise_extinction_runs(run_results)
  )
}

.normalize_simulation_args <- function(
    n_years,
    survival_fun,
    breeding_prob_fun,
    fecundity_lambda_fun,
    density_spec,
    harvest_quota,
    lifecycle_steps,
    mating_fun,
    require_mate,
    inherit_fun,
    dispersal_fun,
    supplement_quota,
    supplement_patch,
    env_surv_sd,
    cat_surv_prob,
    cat_surv_mult,
    env_repro_p_sd,
    env_repro_lambda_sd,
    cat_repro_prob,
    cat_repro_mult,
    record_population_history) {
  if (!is.numeric(n_years) || length(n_years) != 1L || !is.finite(n_years) ||
      n_years < 0 || n_years != floor(n_years)) {
    stop("n_years must be a single non-negative integer", call. = FALSE)
  }
  n_years_int <- suppressWarnings(as.integer(n_years))
  if (is.na(n_years_int)) {
    stop("n_years must be a single non-negative integer", call. = FALSE)
  }
  if (!is.function(survival_fun)) {
    stop("survival_fun must be a function", call. = FALSE)
  }
  if (!is.function(breeding_prob_fun)) {
    stop("breeding_prob_fun must be a function", call. = FALSE)
  }
  if (!is.function(fecundity_lambda_fun)) {
    stop("fecundity_lambda_fun must be a function", call. = FALSE)
  }
  if (!is.null(density_spec)) {
    density_spec <- validate_density_spec(density_spec)
  }
  if (!is.function(mating_fun)) {
    stop("mating_fun must be a function", call. = FALSE)
  }
  if (!is.null(inherit_fun) && !is.function(inherit_fun)) {
    stop("inherit_fun must be NULL or a function", call. = FALSE)
  }
  if (!is.function(dispersal_fun)) {
    stop("dispersal_fun must be a function", call. = FALSE)
  }
  if (!is.logical(require_mate) || length(require_mate) != 1L || is.na(require_mate)) {
    stop("require_mate must be a single logical value", call. = FALSE)
  }
  if (!is.logical(record_population_history) ||
      length(record_population_history) != 1L ||
      is.na(record_population_history)) {
    stop("record_population_history must be a single logical value", call. = FALSE)
  }

  .validate_lifecycle_steps(lifecycle_steps)

  list(
    n_years = n_years_int,
    survival_fun = survival_fun,
    breeding_prob_fun = breeding_prob_fun,
    fecundity_lambda_fun = fecundity_lambda_fun,
    density_spec = density_spec,
    harvest_vec = .normalize_quota_vector(harvest_quota, n_years, "harvest_quota"),
    lifecycle_steps = lifecycle_steps,
    mating_fun = mating_fun,
    require_mate = require_mate,
    inherit_fun = inherit_fun,
    dispersal_fun = dispersal_fun,
    supplement_vec = .normalize_quota_vector(supplement_quota, n_years, "supplement_quota"),
    supplement_patch = if (is.null(supplement_patch)) NULL else as.integer(supplement_patch),
    env_surv_sd = .normalize_non_negative_numeric(env_surv_sd, "env_surv_sd"),
    cat_surv_prob = .normalize_probability(cat_surv_prob, "cat_surv_prob"),
    cat_surv_mult = .normalize_non_negative_numeric(cat_surv_mult, "cat_surv_mult"),
    env_repro_p_sd = .normalize_non_negative_numeric(env_repro_p_sd, "env_repro_p_sd"),
    env_repro_lambda_sd = .normalize_non_negative_numeric(env_repro_lambda_sd, "env_repro_lambda_sd"),
    cat_repro_prob = .normalize_probability(cat_repro_prob, "cat_repro_prob"),
    cat_repro_mult = .normalize_non_negative_numeric(cat_repro_mult, "cat_repro_mult"),
    record_population_history = record_population_history
  )
}

.normalize_quota_vector <- function(value, n_years, label) {
  if (is.null(value)) {
    if (n_years == 0L) {
      return(integer())
    }
    return(rep.int(0L, n_years))
  }
  if (!is.numeric(value)) {
    stop(label, " must be numeric or integer", call. = FALSE)
  }
  if (any(!is.finite(value)) || any(value < 0) || any(value != floor(value))) {
    stop(label, " values must be finite non-negative integers", call. = FALSE)
  }
  if (!length(value) %in% c(1L, n_years)) {
    stop(label, " must have length 1 or length equal to n_years", call. = FALSE)
  }
  out <- suppressWarnings(as.integer(value))
  if (anyNA(out)) {
    stop(label, " values must be representable as integers", call. = FALSE)
  }
  if (length(out) == 1L && n_years > 0L) {
    out <- rep.int(out, n_years)
  }
  out
}

.normalize_non_negative_numeric <- function(value, label) {
  value <- as.numeric(value)
  if (length(value) != 1L || !is.finite(value) || value < 0) {
    stop(label, " must be a single non-negative numeric value", call. = FALSE)
  }
  value
}

.normalize_probability <- function(value, label) {
  value <- as.numeric(value)
  if (length(value) != 1L || !is.finite(value) || value < 0 || value > 1) {
    stop(label, " must be within [0, 1]", call. = FALSE)
  }
  value
}

.draw_year_modifiers <- function(
    env_surv_sd,
    cat_surv_prob,
    cat_surv_mult,
    env_repro_p_sd,
    env_repro_lambda_sd,
    cat_repro_prob,
    cat_repro_mult) {
  env_surv_mult <- .draw_lognormal_multiplier(env_surv_sd)
  cat_surv_event <- cat_surv_prob > 0 && cat_surv_mult < 1 && stats::runif(1L) < cat_surv_prob
  surv_cat_multiplier <- if (isTRUE(cat_surv_event)) cat_surv_mult else 1

  env_repro_p_mult <- .draw_lognormal_multiplier(env_repro_p_sd)
  env_repro_lambda_mult <- .draw_lognormal_multiplier(env_repro_lambda_sd)
  cat_repro_event <- cat_repro_prob > 0 && cat_repro_mult != 1 && stats::runif(1L) < cat_repro_prob
  repro_cat_multiplier <- if (isTRUE(cat_repro_event)) cat_repro_mult else 1

  list(
    env_surv_mult = env_surv_mult,
    cat_surv_mult = surv_cat_multiplier,
    catastrophe = isTRUE(cat_surv_event),
    env_repro_p_mult = env_repro_p_mult,
    env_repro_lambda_mult = env_repro_lambda_mult,
    cat_repro_mult = repro_cat_multiplier,
    repro_catastrophe = isTRUE(cat_repro_event)
  )
}

.draw_lognormal_multiplier <- function(sd_value) {
  if (sd_value <= 0) {
    return(1)
  }
  mu <- -0.5 * sd_value^2
  stats::rnorm(1L, mean = mu, sd = sd_value) |> base::exp()
}

.apply_survival_step <- function(population, survival_fun, density_spec, year_modifiers) {
  survival_density_fun <- if (is.null(density_spec)) NULL else density_spec$survival_fun %||% NULL
  population_pre_survival <- population
  survival_fun_year <- function(ind) {
    p_base <- survival_fun(ind)
    if (!is.numeric(p_base) || length(p_base) != 1L || !is.finite(p_base) || p_base < 0 || p_base > 1) {
      stop("survival_fun must return a single numeric value in [0, 1]", call. = FALSE)
    }
    density_mult <- .eval_density_multiplier(
      density_fun = survival_density_fun,
      population = population_pre_survival,
      ind = ind,
      channel_label = "survival"
    )
    p_eff <- p_base * density_mult * year_modifiers$env_surv_mult * year_modifiers$cat_surv_mult
    max(0, min(1, p_eff))
  }
  apply_survival(population, survival_fun_year)
}

.apply_reproduction_rate_step <- function(
    population,
    breeding_prob_fun,
    fecundity_lambda_fun,
    density_spec,
    year_modifiers,
    mating_fun,
    require_mate,
    inherit_fun) {
  candidate_breeders <- Filter(function(ind) isTRUE(ind$alive) && ind$sex == "F", population)
  if (!length(candidate_breeders)) {
    return(list(population = population, n_births = 0L))
  }

  breeding_density_fun <- if (is.null(density_spec)) NULL else density_spec$breeding_fun %||% NULL
  fecundity_density_fun <- if (is.null(density_spec)) NULL else density_spec$fecundity_fun %||% NULL

  p_eff <- vapply(candidate_breeders, function(ind) {
    p_base <- breeding_prob_fun(ind)
    if (!is.numeric(p_base) || length(p_base) != 1L || !is.finite(p_base) || p_base < 0 || p_base > 1) {
      stop("breeding_prob_fun must return a single numeric value in [0, 1]", call. = FALSE)
    }
    density_mult <- .eval_density_multiplier(
      density_fun = breeding_density_fun,
      population = population,
      ind = ind,
      channel_label = "breeding"
    )
    p_year <- p_base * density_mult * year_modifiers$env_repro_p_mult * year_modifiers$cat_repro_mult
    max(0, min(1, p_year))
  }, numeric(1))

  breed_draw <- stats::runif(length(candidate_breeders)) < p_eff
  if (!any(breed_draw)) {
    return(list(population = population, n_births = 0L))
  }

  breeders <- candidate_breeders[breed_draw]
  offspring_draws <- vapply(breeders, function(ind) {
    lambda_base <- fecundity_lambda_fun(ind)
    if (!is.numeric(lambda_base) || length(lambda_base) != 1L || !is.finite(lambda_base) || lambda_base < 0) {
      stop("fecundity_lambda_fun must return a single non-negative numeric value", call. = FALSE)
    }
    density_mult <- .eval_density_multiplier(
      density_fun = fecundity_density_fun,
      population = population,
      ind = ind,
      channel_label = "fecundity"
    )
    lambda_year <- lambda_base * density_mult *
      year_modifiers$env_repro_lambda_mult * year_modifiers$cat_repro_mult
    if (!is.finite(lambda_year) || lambda_year < 0) {
      stop("effective fecundity lambda must be a finite non-negative numeric value", call. = FALSE)
    }
    stats::rpois(1L, max(0, lambda_year))
  }, integer(1))
  names(offspring_draws) <- vapply(breeders, function(ind) as.character(ind$id), character(1))

  pre_birth_count <- length(population)
  updated_population <- apply_reproduction(
    population = population,
    breeders = breeders,
    fecundity_fun = function(ind) {
      offspring_draws[[as.character(ind$id)]] %||% 0L
    },
    mating_fun = mating_fun,
    require_mate = require_mate,
    inherit_fun = inherit_fun
  )

  list(
    population = updated_population,
    n_births = as.integer(length(updated_population) - pre_birth_count)
  )
}

.apply_supplementation_step <- function(population, quota, patch_id) {
  if (is.na(quota) || quota <= 0L) {
    return(list(population = population, n_added = 0L))
  }
  apply_supplementation(
    population = population,
    n_add = quota,
    patch_id = patch_id
  )
}

.apply_harvest_step <- function(population, quota) {
  if (is.na(quota) || quota <= 0L) {
    return(list(population = population, n_harvested = 0L))
  }
  apply_harvest_quota(population, quota)
}

.build_summary_row <- function(year, population, counters, year_modifiers) {
  alive_flags <- vapply(population, function(ind) isTRUE(ind$alive), logical(1))
  sexes <- vapply(population, function(ind) ind$sex, character(1))

  list(
    year = as.integer(year),
    n_alive = sum(alive_flags),
    n_female_alive = sum(alive_flags & sexes == "F"),
    n_male_alive = sum(alive_flags & sexes == "M"),
    n_births = as.integer(counters$n_births),
    n_harvested = as.integer(counters$n_harvested),
    n_supplemented = as.integer(counters$n_supplemented),
    survival_scale = as.numeric(counters$survival_scale),
    env_surv_mult = year_modifiers$env_surv_mult,
    cat_surv_mult = year_modifiers$cat_surv_mult,
    catastrophe = year_modifiers$catastrophe,
    env_repro_p_mult = year_modifiers$env_repro_p_mult,
    env_repro_lambda_mult = year_modifiers$env_repro_lambda_mult,
    cat_repro_mult = year_modifiers$cat_repro_mult,
    repro_catastrophe = year_modifiers$repro_catastrophe
  )
}

.summary_rows_to_tibble <- function(summary_rows) {
  tibble::tibble(
    year = vapply(summary_rows, function(x) x$year, integer(1)),
    n_alive = vapply(summary_rows, function(x) x$n_alive, integer(1)),
    n_female_alive = vapply(summary_rows, function(x) x$n_female_alive, integer(1)),
    n_male_alive = vapply(summary_rows, function(x) x$n_male_alive, integer(1)),
    n_births = vapply(summary_rows, function(x) x$n_births, integer(1)),
    n_harvested = vapply(summary_rows, function(x) x$n_harvested, integer(1)),
    n_supplemented = vapply(summary_rows, function(x) x$n_supplemented, integer(1)),
    survival_scale = vapply(summary_rows, function(x) x$survival_scale, numeric(1)),
    env_surv_mult = vapply(summary_rows, function(x) x$env_surv_mult, numeric(1)),
    cat_surv_mult = vapply(summary_rows, function(x) x$cat_surv_mult, numeric(1)),
    catastrophe = vapply(summary_rows, function(x) x$catastrophe, logical(1)),
    env_repro_p_mult = vapply(summary_rows, function(x) x$env_repro_p_mult, numeric(1)),
    env_repro_lambda_mult = vapply(summary_rows, function(x) x$env_repro_lambda_mult, numeric(1)),
    cat_repro_mult = vapply(summary_rows, function(x) x$cat_repro_mult, numeric(1)),
    repro_catastrophe = vapply(summary_rows, function(x) x$repro_catastrophe, logical(1))
  )
}

.empty_summary_tibble <- function() {
  tibble::tibble(
    year = integer(),
    n_alive = integer(),
    n_female_alive = integer(),
    n_male_alive = integer(),
    n_births = integer(),
    n_harvested = integer(),
    n_supplemented = integer(),
    survival_scale = numeric(),
    env_surv_mult = numeric(),
    cat_surv_mult = numeric(),
    catastrophe = logical(),
    env_repro_p_mult = numeric(),
    env_repro_lambda_mult = numeric(),
    cat_repro_mult = numeric(),
    repro_catastrophe = logical()
  )
}

.summarise_extinction_runs <- function(run_results) {
  tibble::tibble(
    run = seq_along(run_results),
    went_extinct = vapply(run_results, function(run_output) {
      any(run_output$summary$n_alive == 0)
    }, logical(1)),
    time_to_extinction = vapply(run_results, function(run_output) {
      extinction_years <- run_output$summary$year[run_output$summary$n_alive == 0]
      if (length(extinction_years)) {
        return(min(extinction_years))
      }
      NA_integer_
    }, integer(1))
  )
}

.with_optional_seed <- function(seed, expr) {
  expr <- substitute(expr)
  if (is.null(seed)) {
    return(eval(expr, envir = parent.frame()))
  }

  had_rng <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_rng) {
    old_rng <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  }
  on.exit({
    if (had_rng) {
      assign(".Random.seed", old_rng, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  set.seed(seed)
  eval(expr, envir = parent.frame())
}

.normalize_optional_seed <- function(seed) {
  if (is.null(seed)) {
    return(NULL)
  }
  if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed)) {
    stop("seed must be NULL or a single integer", call. = FALSE)
  }
  seed_int <- suppressWarnings(as.integer(seed))
  if (is.na(seed_int) || seed_int != seed) {
    stop("seed must be NULL or a single integer", call. = FALSE)
  }
  seed_int
}

.clone_population <- function(population) {
  if (!length(population)) {
    return(population)
  }
  lapply(population, function(ind) ind)
}
