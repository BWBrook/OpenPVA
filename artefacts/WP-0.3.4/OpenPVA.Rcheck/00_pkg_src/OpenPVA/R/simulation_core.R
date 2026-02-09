#' Run a basic demographic simulation
#'
#' Applies ageing, survival, and reproduction processes over multiple years.
#'
#' @param initial_population List of individuals (e.g. from `initialize_population()`).
#' @param n_years Integer number of years to simulate (must be >= 0).
#' @param survival_fun Function returning survival probabilities for individuals.
#' @param breeding_fun Function identifying breeding-eligible individuals.
#' @param fecundity_fun Function returning offspring counts for breeders.
#'
#' @param K Optional numeric carrying capacity for ceiling-based survival scaling.
#' @param K_patches Optional numeric vector of patch-specific carrying capacities.
#'   Provide either `K` or `K_patches`, not both. When `K_patches` is used,
#'   density dependence is applied per patch based on `patch_id` and the
#'   `survival_scale` summary column is set to `NA`.
#' @param harvest_quota Optional harvest quota (single value or length `n_years` vector). If
#'   `lifecycle_steps` does not include `"harvest"`, quotas are ignored.
#' @param lifecycle_steps Character vector of lifecycle step labels describing the order in
#'   which processes occur. Allowed values are `"age"`, `"survival"`, `"breeding_births"`,
#'   and `"harvest"`. Steps omitted from the vector are skipped.
#' @param mating_fun Function selecting mates for breeding females. Defaults to
#'   `default_mating_fun`.
#' @param inherit_fun Optional function taking `(mother, father)` and returning an
#'   allele matrix for newborns (e.g. `inherit_genotype_simple`). Defaults to `NULL`,
#'   which leaves newborn alleles as `NULL`.
#' @param dispersal_fun Function with signature `function(ind, population)`
#'   returning a new `patch_id` for the individual. Defaults to
#'   `default_dispersal_fun` (no movement).
#'
#' @param supplement_quota Optional supplementation quota (single value or length
#'   `n_years` vector). Applied only if `"supplementation"` is in `lifecycle_steps`.
#' @param supplement_patch Optional patch identifier assigned to all
#'   supplemented individuals (defaults to `NA`).
#' @param env_surv_sd Standard deviation of a lognormal year-level multiplier on
#'   survival (environmental variation). Set to 0 to disable.
#' @param cat_surv_prob Per-year probability of a catastrophic survival event
#'   (Bernoulli). Set to 0 to disable.
#' @param cat_surv_mult Multiplicative factor applied to survival probabilities
#'   in catastrophe years. Typical values lie within (0, 1]; set to 1 to make
#'   catastrophes neutral even if they occur.
#'
#' @return List with the final `population` and a `summary` tibble of yearly metrics
#'   (including `n_supplemented`, `env_surv_mult`, `cat_surv_mult`, and
#'   `catastrophe` flags).
#' @export
run_basic_simulation <- function(
    initial_population,
    n_years,
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
  lifecycle_steps <- force(lifecycle_steps)
  if (!is.numeric(n_years) || length(n_years) != 1L || n_years < 0) {
    stop("n_years must be a single non-negative numeric value")
  }

  if (!is.null(K)) {
    if (!is.numeric(K) || length(K) != 1L || K <= 0) {
      stop("K must be NULL or a single numeric value greater than zero")
    }
    K <- as.numeric(K)
  }
  if (!is.null(K_patches)) {
    if (!is.numeric(K_patches) || !length(K_patches)) {
      stop("K_patches must be NULL or a numeric vector", call. = FALSE)
    }
    if (any(K_patches <= 0)) {
      stop("K_patches values must be greater than zero", call. = FALSE)
    }
    K_patches <- as.numeric(K_patches)
  }
  if (!is.null(K) && !is.null(K_patches)) {
    stop("Specify either K or K_patches, not both", call. = FALSE)
  }

  if (is.null(harvest_quota)) {
    harvest_vec <- if (n_years > 0) rep.int(0L, n_years) else integer(0)
  } else {
    if (!is.numeric(harvest_quota)) {
      stop("harvest_quota must be numeric or integer")
    }
    if (any(harvest_quota < 0)) {
      stop("harvest_quota values must be non-negative")
    }
    if (!length(harvest_quota) %in% c(1L, n_years)) {
      stop("harvest_quota must have length 1 or length equal to n_years")
    }
    harvest_vec <- as.integer(round(harvest_quota))
    if (length(harvest_vec) == 1L && n_years > 0) {
      harvest_vec <- rep.int(harvest_vec, n_years)
    }
  }

  if (is.null(supplement_quota)) {
    supplement_vec <- if (n_years > 0) rep.int(0L, n_years) else integer(0)
  } else {
    if (!is.numeric(supplement_quota)) {
      stop("supplement_quota must be numeric or integer", call. = FALSE)
    }
    if (!length(supplement_quota) %in% c(1L, n_years)) {
      stop("supplement_quota must have length 1 or length equal to n_years", call. = FALSE)
    }
    supplement_vec <- as.integer(round(supplement_quota))
    if (length(supplement_vec) == 1L && n_years > 0) {
      supplement_vec <- rep.int(supplement_vec, n_years)
    }
  }

  if (!is.null(supplement_patch)) {
    supplement_patch <- as.integer(supplement_patch)
  }

  env_surv_sd <- as.numeric(env_surv_sd)
  if (length(env_surv_sd) != 1L || is.na(env_surv_sd) || env_surv_sd < 0) {
    stop("env_surv_sd must be a single non-negative numeric value", call. = FALSE)
  }
  cat_surv_prob <- as.numeric(cat_surv_prob)
  if (length(cat_surv_prob) != 1L || is.na(cat_surv_prob) ||
      cat_surv_prob < 0 || cat_surv_prob > 1) {
    stop("cat_surv_prob must be within [0, 1]", call. = FALSE)
  }
  cat_surv_mult <- as.numeric(cat_surv_mult)
  if (length(cat_surv_mult) != 1L || is.na(cat_surv_mult) || cat_surv_mult < 0) {
    stop("cat_surv_mult must be a single numeric value >= 0", call. = FALSE)
  }

  .validate_lifecycle_steps(lifecycle_steps)

  population <- initial_population

  if (n_years == 0) {
    summary_tbl <- tibble::tibble(
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
      catastrophe = logical()
    )
    return(list(population = population, summary = summary_tbl))
  }

  summary_rows <- vector("list", n_years)

  for (year in seq_len(n_years)) {
    n_births_year <- 0L
    n_harvested_year <- 0L
    n_supplemented_year <- 0L
    survival_scale_year <- 1

    env_surv_mult_year <- if (env_surv_sd > 0) {
      mu <- -0.5 * env_surv_sd^2
      stats::rnorm(1L, mean = mu, sd = env_surv_sd) |> base::exp()
    } else {
      1
    }

    cat_event_year <- FALSE
    cat_surv_mult_year <- 1
    if (cat_surv_prob > 0 && cat_surv_mult < 1) {
      if (stats::runif(1L) < cat_surv_prob) {
        cat_event_year <- TRUE
        cat_surv_mult_year <- cat_surv_mult
      }
    }

    for (step in lifecycle_steps) {
      if (step == "age") {
        population <- age_individuals(population)
      } else if (step == "survival") {
        alive_flags_pre <- vapply(population, function(ind) isTRUE(ind$alive), logical(1))
        if (!is.null(K_patches)) {
          patch_ids_pre <- vapply(
            population,
            function(ind) {
              pid <- ind$patch_id
              if (is.null(pid) || is.na(pid)) NA_integer_ else as.integer(pid)
            },
            integer(1)
          )
          patch_counts <- integer(length(K_patches))
          if (length(population)) {
            for (idx in seq_along(population)) {
              pid <- patch_ids_pre[idx]
              if (!is.na(pid) &&
                  pid >= 1L && pid <= length(K_patches) &&
                  alive_flags_pre[idx]) {
                patch_counts[pid] <- patch_counts[pid] + 1L
              }
            }
          }
          patch_scales <- rep(1, length(K_patches))
          for (pid in seq_along(K_patches)) {
            if (patch_counts[pid] > K_patches[pid]) {
              patch_scales[pid] <- K_patches[pid] / patch_counts[pid]
            }
          }
          survival_scale_year <- NA_real_
          survival_fun_year <- function(ind) {
            p <- survival_fun(ind)
            scale <- 1
            pid <- ind$patch_id
            if (!is.null(pid) && !is.na(pid)) {
              pid_int <- as.integer(pid)
              if (pid_int >= 1L && pid_int <= length(patch_scales)) {
                scale <- patch_scales[pid_int]
              }
            }
            p_scaled <- p * scale * env_surv_mult_year * cat_surv_mult_year
            if (p_scaled < 0) p_scaled <- 0
            if (p_scaled > 1) p_scaled <- 1
            p_scaled
          }
        } else {
          n_alive_pre <- sum(alive_flags_pre)
          survival_scale_year <- compute_survival_scale(n_alive_pre, K)
          survival_fun_year <- function(ind) {
            p <- survival_fun(ind)
            p_scaled <- p * survival_scale_year * env_surv_mult_year * cat_surv_mult_year
            if (p_scaled < 0) p_scaled <- 0
            if (p_scaled > 1) p_scaled <- 1
            p_scaled
          }
        }
        population <- apply_survival(population, survival_fun_year)
      } else if (step == "dispersal") {
        population <- apply_dispersal(population, dispersal_fun)
      } else if (step == "supplementation") {
        quota_this_year <- if (length(supplement_vec)) supplement_vec[year] else 0L
        if (!is.na(quota_this_year) && quota_this_year > 0L) {
          supplement_result <- apply_supplementation(
            population = population,
            n_add = quota_this_year,
            patch_id = supplement_patch
          )
          population <- supplement_result$population
          n_supplemented_year <- n_supplemented_year + supplement_result$n_added
        }
      } else if (step == "breeding_births") {
        breeders <- determine_breeding(population, breeding_fun)
        pre_birth_count <- length(population)
        population <- apply_reproduction(
          population = population,
          breeders = breeders,
          fecundity_fun = fecundity_fun,
          mating_fun = mating_fun,
          inherit_fun = inherit_fun
        )
        n_births_year <- n_births_year + as.integer(length(population) - pre_birth_count)
      } else if (step == "harvest") {
        quota_this_year <- if (length(harvest_vec)) harvest_vec[year] else 0L
        if (quota_this_year > 0) {
          harvest_result <- apply_harvest_quota(population, quota_this_year)
          population <- harvest_result$population
          n_harvested_year <- n_harvested_year + harvest_result$n_harvested
        }
      }
    }

    alive_flags <- vapply(population, function(ind) isTRUE(ind$alive), logical(1))
    sexes <- vapply(population, function(ind) ind$sex, character(1))

    n_alive <- sum(alive_flags)
    n_female_alive <- sum(alive_flags & sexes == "F")
    n_male_alive <- sum(alive_flags & sexes == "M")

    summary_rows[[year]] <- list(
      year = year,
      n_alive = n_alive,
      n_female_alive = n_female_alive,
      n_male_alive = n_male_alive,
      n_births = n_births_year,
      n_harvested = n_harvested_year,
      n_supplemented = n_supplemented_year,
      survival_scale = survival_scale_year,
      env_surv_mult = env_surv_mult_year,
      cat_surv_mult = cat_surv_mult_year,
      catastrophe = cat_event_year
    )
  }

  summary_tbl <- tibble::tibble(
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
    catastrophe = vapply(summary_rows, function(x) x$catastrophe, logical(1))
  )

  list(population = population, summary = summary_tbl)
}

#' Run replicated demographic simulations
#'
#' Executes multiple independent runs of `run_basic_simulation()` and collates
#' per-year summaries along with extinction metrics.
#'
#' @param n_runs Integer number of independent simulation runs (must be >= 1).
#' @param n_years Integer number of years per run (must be >= 1).
#' @param init_fun Function with no arguments that returns an initial population.
#' @param survival_fun Function returning survival probabilities for individuals.
#' @param breeding_fun Function identifying breeding-eligible individuals.
#' @param fecundity_fun Function returning offspring counts for breeders.
#'
#' @param K Optional numeric carrying capacity for ceiling-based survival scaling.
#' @param harvest_quota Optional harvest quota (single value or length `n_years` vector). If
#'   `lifecycle_steps` omits `"harvest"`, quotas are ignored.
#' @param lifecycle_steps Character vector specifying lifecycle order for each run.
#' @param K_patches Optional numeric vector of patch-specific carrying capacities.
#'   Provide either `K` or `K_patches`, not both.
#' @param mating_fun Function used for mate selection within each run.
#' @param inherit_fun Optional inheritance function applied to newborns.
#' @param dispersal_fun Function applied during the `"dispersal"` lifecycle step.
#' @param supplement_quota Optional supplementation quota (single value or length
#'   `n_years` vector). Applied only if `"supplementation"` is in `lifecycle_steps`.
#' @param supplement_patch Optional patch identifier assigned to all
#'   supplemented individuals (defaults to `NA`).
#' @param env_surv_sd Standard deviation of a lognormal year-level multiplier on
#'   survival (environmental variation). Set to 0 to disable.
#' @param cat_surv_prob Per-year probability of a catastrophic survival event
#'   (Bernoulli). Set to 0 to disable.
#' @param cat_surv_mult Multiplicative factor applied to survival probabilities
#'   in catastrophe years. Typical values lie within (0, 1]; set to 1 to make
#'   catastrophes neutral even if they occur.
#'
#' @return A list with elements:
#'   \itemize{
#'     \item `runs`: list of length `n_runs`, each containing the output of `run_basic_simulation()`.
#'     \item `summary`: tibble with columns `run`, `year`, `n_alive`, `n_female_alive`, `n_male_alive`, `n_births`, `n_harvested`, `n_supplemented`, `survival_scale`, `env_surv_mult`, `cat_surv_mult`, `catastrophe`.
#'     \item `extinction`: tibble with columns `run`, `went_extinct`, `time_to_extinction`.
#'   }
#' @export
run_basic_simulation_replicates <- function(
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
  lifecycle_steps <- force(lifecycle_steps)
  if (!is.numeric(n_runs) || length(n_runs) != 1L || n_runs < 1) {
    stop("n_runs must be a single numeric value greater than or equal to 1")
  }
  if (!is.numeric(n_years) || length(n_years) != 1L || n_years < 1) {
    stop("n_years must be a single numeric value greater than or equal to 1")
  }
  if (!is.function(init_fun)) {
    stop("init_fun must be a function returning an initial population")
  }

  n_runs <- as.integer(n_runs)
  n_years <- as.integer(n_years)

  if (!is.null(K) && !is.null(K_patches)) {
    stop("Specify either K or K_patches, not both", call. = FALSE)
  }
  if (!is.null(K_patches)) {
    if (!is.numeric(K_patches) || !length(K_patches)) {
      stop("K_patches must be NULL or a numeric vector", call. = FALSE)
    }
    if (any(K_patches <= 0)) {
      stop("K_patches values must be greater than zero", call. = FALSE)
    }
    K_patches <- as.numeric(K_patches)
  }

  if (!is.null(supplement_quota)) {
    if (!is.numeric(supplement_quota)) {
      stop("supplement_quota must be numeric or integer", call. = FALSE)
    }
    if (!length(supplement_quota) %in% c(1L, n_years)) {
      stop("supplement_quota must have length 1 or length equal to n_years", call. = FALSE)
    }
  }
  if (!is.null(supplement_patch)) {
    supplement_patch <- as.integer(supplement_patch)
  }

  env_surv_sd <- as.numeric(env_surv_sd)
  if (length(env_surv_sd) != 1L || is.na(env_surv_sd) || env_surv_sd < 0) {
    stop("env_surv_sd must be a single non-negative numeric value", call. = FALSE)
  }
  cat_surv_prob <- as.numeric(cat_surv_prob)
  if (length(cat_surv_prob) != 1L || is.na(cat_surv_prob) ||
      cat_surv_prob < 0 || cat_surv_prob > 1) {
    stop("cat_surv_prob must be within [0, 1]", call. = FALSE)
  }
  cat_surv_mult <- as.numeric(cat_surv_mult)
  if (length(cat_surv_mult) != 1L || is.na(cat_surv_mult) || cat_surv_mult < 0) {
    stop("cat_surv_mult must be a single numeric value >= 0", call. = FALSE)
  }

  run_results <- vector("list", n_runs)
  run_summaries <- vector("list", n_runs)

  for (run in seq_len(n_runs)) {
    initial_population <- init_fun()
    sim_result <- run_basic_simulation(
      initial_population = initial_population,
      n_years = n_years,
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
    run_results[[run]] <- sim_result
    run_summaries[[run]] <- sim_result$summary
  }

  summary_tbl <- purrr::map2_dfr(
    run_summaries,
    seq_len(n_runs),
    function(summary, run_id) {
      tibble::add_column(summary, run = as.integer(run_id), .before = 1)
    }
  )

  extinction_tbl <- tibble::tibble(
    run = seq_len(n_runs),
    went_extinct = vapply(
      run_summaries,
      function(summary) any(summary$n_alive == 0),
      logical(1)
    ),
    time_to_extinction = vapply(
      run_summaries,
      function(summary) {
        extinction_years <- summary$year[summary$n_alive == 0]
        if (length(extinction_years)) {
          min(extinction_years)
        } else {
          NA_integer_
        }
      },
      integer(1)
    )
  )

  list(
    runs = run_results,
    summary = summary_tbl,
    extinction = extinction_tbl
  )
}

compute_survival_scale <- function(n_alive, K) {
  if (is.null(K) || n_alive <= 0) {
    return(1)
  }
  if (n_alive <= K) {
    return(1)
  }
  K / n_alive
}
