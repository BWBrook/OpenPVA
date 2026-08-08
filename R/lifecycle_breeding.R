#' Determine breeding-eligible individuals
#'
#' Filters the population to return all living females meeting the breeding criteria.
#'
#' @param population List of individual objects.
#' @param breeding_fun Function that returns TRUE for individuals eligible to breed.
#'
#' @return List of individual objects eligible to breed.
#' @export
determine_breeding <- function(population, breeding_fun) {
  Filter(function(ind) {
    ind$alive && ind$sex == "F" && breeding_fun(ind)
  }, population)
}

#' Default mating function (random alive male)
#'
#' Selects a random alive male partner for a breeding female.
#'
#' @param population List of individual objects.
#' @param breeder Breeding individual (typically a female).
#'
#' @return An individual object representing the chosen male, or `NULL`
#'   if no alive males exist.
#' @export
default_mating_fun <- function(population, breeder) {
  alive_males <- Filter(function(ind) ind$alive && ind$sex == "M", population)
  if (!length(alive_males)) {
    return(NULL)
  }
  alive_males[[sample.int(length(alive_males), 1L)]]
}

#' Default breeding function
#'
#' Returns `TRUE` when the default breeding probability is positive.
#'
#' @param ind Individual object.
#'
#' @return Logical. TRUE if eligible to breed.
#' @export
default_breeding_fun <- function(ind) {
  default_breeding_prob_fun(ind) > 0
}
