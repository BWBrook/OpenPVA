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
  if (!is.numeric(n_remove) || length(n_remove) != 1L ||
      !is.finite(n_remove) || n_remove < 0 || n_remove != floor(n_remove)) {
    stop("n_remove must be a finite non-negative integer")
  }
  n_remove <- suppressWarnings(as.integer(n_remove))
  if (is.na(n_remove)) {
    stop("n_remove must be representable as an integer")
  }

  if (!length(population)) {
    return(list(population = population, n_harvested = 0L))
  }

  if (n_remove == 0L) {
    return(list(population = population, n_harvested = 0L))
  }

  alive_flags <- vapply(population, function(ind) isTRUE(ind$alive), logical(1))
  alive_indices <- which(alive_flags)

  if (!length(alive_indices)) {
    return(list(population = population, n_harvested = 0L))
  }

  n_effective <- min(length(alive_indices), n_remove)
  if (n_effective <= 0) {
    return(list(population = population, n_harvested = 0L))
  }

  harvested_indices <- sample(alive_indices, n_effective)
  for (idx in harvested_indices) {
    population[[idx]]$alive <- FALSE
  }

  list(population = population, n_harvested = n_effective)
}
