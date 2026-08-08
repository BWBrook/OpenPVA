#' Default fecundity function
#'
#' Draws a Poisson-distributed litter size from the default fecundity lambda.
#'
#' @param ind Individual object.
#'
#' @return Integer number of offspring (greater than or equal to zero).
#' @export
default_fecundity_fun <- function(ind) {
  stats::rpois(1L, lambda = default_fecundity_lambda_fun(ind))
}
