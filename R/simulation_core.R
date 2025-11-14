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
#' @param harvest_quota Optional harvest quota (single value or length `n_years` vector).
#'
#' @return List with the final `population` and a `summary` tibble of yearly metrics.
#' @export
run_basic_simulation <- function(
    initial_population,
    n_years,
    survival_fun = default_survival_fun,
    breeding_fun = default_breeding_fun,
    fecundity_fun = default_fecundity_fun,
    K = NULL,
    harvest_quota = NULL) {
  if (!is.numeric(n_years) || length(n_years) != 1L || n_years < 0) {
    stop("n_years must be a single non-negative numeric value")
  }

  if (!is.null(K)) {
    if (!is.numeric(K) || length(K) != 1L || K <= 0) {
      stop("K must be NULL or a single numeric value greater than zero")
    }
    K <- as.numeric(K)
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

  population <- initial_population

  if (n_years == 0) {
    summary_tbl <- tibble::tibble(
      year = integer(),
      n_alive = integer(),
      n_female_alive = integer(),
      n_male_alive = integer(),
      n_births = integer(),
      n_harvested = integer(),
      survival_scale = numeric()
    )
    return(list(population = population, summary = summary_tbl))
  }

  summary_rows <- vector("list", n_years)

  for (year in seq_len(n_years)) {
    population <- age_individuals(population)

    alive_flags_pre <- vapply(population, function(ind) isTRUE(ind$alive), logical(1))
    n_alive_pre <- sum(alive_flags_pre)
    survival_scale <- compute_survival_scale(n_alive_pre, K)
    survival_fun_year <- function(ind) {
      p <- survival_fun(ind)
      p_scaled <- p * survival_scale
      if (p_scaled < 0) p_scaled <- 0
      if (p_scaled > 1) p_scaled <- 1
      p_scaled
    }

    population <- apply_survival(population, survival_fun_year)
    breeders <- determine_breeding(population, breeding_fun)
    pre_birth_count <- length(population)
    population <- apply_reproduction(population, breeders, fecundity_fun)
    n_births <- length(population) - pre_birth_count

    quota_this_year <- if (length(harvest_vec)) harvest_vec[year] else 0L
    if (quota_this_year > 0) {
      harvest_result <- apply_harvest_quota(population, quota_this_year)
      population <- harvest_result$population
      n_harvested <- harvest_result$n_harvested
    } else {
      n_harvested <- 0L
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
      n_births = n_births,
      n_harvested = n_harvested,
      survival_scale = survival_scale
    )
  }

  summary_tbl <- tibble::tibble(
    year = vapply(summary_rows, function(x) x$year, integer(1)),
    n_alive = vapply(summary_rows, function(x) x$n_alive, integer(1)),
    n_female_alive = vapply(summary_rows, function(x) x$n_female_alive, integer(1)),
    n_male_alive = vapply(summary_rows, function(x) x$n_male_alive, integer(1)),
    n_births = vapply(summary_rows, function(x) x$n_births, integer(1)),
    n_harvested = vapply(summary_rows, function(x) x$n_harvested, integer(1)),
    survival_scale = vapply(summary_rows, function(x) x$survival_scale, numeric(1))
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
#' @param harvest_quota Optional harvest quota (single value or length `n_years` vector).
#'
#' @return A list with elements:
#'   \itemize{
#'     \item `runs`: list of length `n_runs`, each containing the output of `run_basic_simulation()`.
#'     \item `summary`: tibble with columns `run`, `year`, `n_alive`, `n_female_alive`, `n_male_alive`, `n_births`, `n_harvested`, `survival_scale`.
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
    harvest_quota = NULL) {
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
      harvest_quota = harvest_quota
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
