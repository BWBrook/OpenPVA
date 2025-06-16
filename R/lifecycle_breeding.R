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

#' Default breeding function
#'
#' Returns TRUE for females aged 4 or older.
#'
#' @param ind Individual object.
#'
#' @return Logical. TRUE if eligible to breed.
#' @export
default_breeding_fun <- function(ind) {
  ind$age >= 4
}
