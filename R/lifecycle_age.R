#' Age all individuals in the population
#'
#' Increments the age of every living individual by one year.
#'
#' @param population List of individual objects.
#'
#' @return Modified population list with updated ages.
#' @export
age_individuals <- function(population) {
  lapply(population, function(ind) {
    if (ind$alive) ind$age <- ind$age + 1
    ind
  })
}
