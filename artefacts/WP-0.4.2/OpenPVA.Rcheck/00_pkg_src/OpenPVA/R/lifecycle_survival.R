#' Apply survival to a population
#'
#' Updates each individual's `alive` status based on a survival probability function.
#'
#' @param population List of individual objects.
#' @param survival_fun Function that returns a survival probability for each individual.
#'
#' @return Modified population with updated `alive` status.
#' @export
apply_survival <- function(population, survival_fun) {
  lapply(population, function(ind) {
    if (ind$alive) {
      prob <- survival_fun(ind)
      ind$alive <- stats::runif(1) < prob
    }
    ind
  })
}

#' Default survival function (age-structured)
#'
#' Returns a survival probability based on the age of the individual.
#'
#' @param ind Individual object.
#'
#' @return Numeric. Probability of survival.
#' @export
default_survival_fun <- function(ind) {
  if (ind$age == 0) return(0.85)
  if (ind$age <= 4) return(0.92)
  return(0.70)
}
