#' Apply a simple harvest quota
#'
#' Removes a specified number of living individuals from the population.
#'
#' @param population List of individual objects.
#' @param n_remove Numeric or integer scalar giving the desired number to remove.
#'
#' @return A list with elements `population` (updated list) and
#'   `n_harvested` (actual number removed).
#' @export
apply_harvest_quota <- function(population, n_remove) {
  if (!length(population)) {
    return(list(population = population, n_harvested = 0L))
  }

  if (!is.numeric(n_remove) || length(n_remove) != 1L) {
    stop("n_remove must be a single numeric value")
  }

  if (n_remove <= 0) {
    return(list(population = population, n_harvested = 0L))
  }

  alive_flags <- vapply(population, function(ind) isTRUE(ind$alive), logical(1))
  alive_indices <- which(alive_flags)

  if (!length(alive_indices)) {
    return(list(population = population, n_harvested = 0L))
  }

  n_effective <- min(length(alive_indices), as.integer(floor(n_remove)))
  if (n_effective <= 0) {
    return(list(population = population, n_harvested = 0L))
  }

  harvested_indices <- sample(alive_indices, n_effective)
  for (idx in harvested_indices) {
    population[[idx]]$alive <- FALSE
  }

  list(population = population, n_harvested = n_effective)
}
