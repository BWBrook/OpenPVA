#' Default fecundity function
#'
#' Draws a Poisson-distributed litter size for a breeding individual.
#'
#' @param ind Individual object.
#'
#' @return Integer number of offspring (greater than or equal to zero).
#' @export
default_fecundity_fun <- function(ind) {
  stats::rpois(1L, lambda = 1.5)
}

#' Apply reproduction to a population
#'
#' Adds newborn individuals for each breeder based on a fecundity function.
#'
#' @param population List of individual objects.
#' @param breeders List of individual objects eligible to breed.
#' @param fecundity_fun Function returning the number of offspring for a breeder.
#' @param mating_fun Function selecting a mate for each breeder. Defaults to
#'   `default_mating_fun` and may be `NULL` if fathers should not be recorded.
#'
#' @return Updated population list containing newborn individuals appended.
#' @export
apply_reproduction <- function(
    population,
    breeders,
    fecundity_fun = default_fecundity_fun,
    mating_fun = default_mating_fun) {
  if (!length(population)) {
    max_id <- 0L
  } else {
    max_id <- max(vapply(population, function(ind) ind$id, integer(1)))
  }

  newborns <- list()

  if (length(breeders)) {
    for (breeder in breeders) {
      mother_id <- breeder$id
      father <- if (is.null(mating_fun)) NULL else mating_fun(population, breeder)
      father_id <- if (is.null(father)) NA_integer_ else father$id

      n_offspring <- fecundity_fun(breeder)
      if (!is.numeric(n_offspring) || length(n_offspring) != 1L) {
        stop("fecundity_fun must return a single numeric value")
      }
      n_offspring <- as.integer(floor(n_offspring))
      if (n_offspring <= 0) {
        next
      }
      for (i in seq_len(n_offspring)) {
        max_id <- max_id + 1L
        newborns[[length(newborns) + 1L]] <- create_individual(
          id = max_id,
          sex = sample(c("M", "F"), 1L),
          age = 0L,
          mother_id = mother_id,
          father_id = father_id
        )
      }
    }
  }

  if (length(newborns)) {
    population <- c(population, newborns)
  }

  population
}
