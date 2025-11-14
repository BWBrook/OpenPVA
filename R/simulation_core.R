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
#' @return List with the final `population` and a `summary` tibble of yearly metrics.
#' @export
run_basic_simulation <- function(
    initial_population,
    n_years,
    survival_fun = default_survival_fun,
    breeding_fun = default_breeding_fun,
    fecundity_fun = default_fecundity_fun) {
  if (!is.numeric(n_years) || length(n_years) != 1L || n_years < 0) {
    stop("n_years must be a single non-negative numeric value")
  }

  population <- initial_population

  if (n_years == 0) {
    summary_tbl <- tibble::tibble(
      year = integer(),
      n_alive = integer(),
      n_female_alive = integer(),
      n_male_alive = integer(),
      n_births = integer()
    )
    return(list(population = population, summary = summary_tbl))
  }

  summary_rows <- vector("list", n_years)

  for (year in seq_len(n_years)) {
    population <- age_individuals(population)
    population <- apply_survival(population, survival_fun)
    breeders <- determine_breeding(population, breeding_fun)
    pre_birth_count <- length(population)
    population <- apply_reproduction(population, breeders, fecundity_fun)
    n_births <- length(population) - pre_birth_count

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
      n_births = n_births
    )
  }

  summary_tbl <- tibble::tibble(
    year = vapply(summary_rows, function(x) x$year, integer(1)),
    n_alive = vapply(summary_rows, function(x) x$n_alive, integer(1)),
    n_female_alive = vapply(summary_rows, function(x) x$n_female_alive, integer(1)),
    n_male_alive = vapply(summary_rows, function(x) x$n_male_alive, integer(1)),
    n_births = vapply(summary_rows, function(x) x$n_births, integer(1))
  )

  list(population = population, summary = summary_tbl)
}
