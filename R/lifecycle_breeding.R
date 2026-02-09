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

#' Build a mate-limited mating function
#'
#' Returns a mating function compatible with [apply_reproduction()] that limits
#' how many times any individual male can be selected as a mate within a single
#' reproduction call (typically one simulation year).
#'
#' @param max_mates_per_male Positive integer limit for male mating assignments.
#'
#' @return Function with signature `function(population, breeder, context = NULL)`.
#'   When `context` is provided by [apply_reproduction()], male usage counts are
#'   tracked and enforced up to `max_mates_per_male`.
#' @export
make_mate_limited_mating_fun <- function(max_mates_per_male = 1L) {
  max_mates_per_male <- as.integer(max_mates_per_male)
  if (length(max_mates_per_male) != 1L || is.na(max_mates_per_male) ||
      max_mates_per_male <= 0L) {
    stop("max_mates_per_male must be a single positive integer", call. = FALSE)
  }

  function(population, breeder, context = NULL) {
    alive_males <- Filter(function(ind) ind$alive && ind$sex == "M", population)
    if (!length(alive_males)) {
      return(NULL)
    }

    if (!is.null(context)) {
      if (is.null(context$male_matings)) {
        context$male_matings <- integer()
      }
      male_ids <- vapply(alive_males, function(ind) as.character(ind$id), character(1))
      used_counts <- context$male_matings[male_ids]
      used_counts[is.na(used_counts)] <- 0L
      eligible <- alive_males[used_counts < max_mates_per_male]
      if (!length(eligible)) {
        return(NULL)
      }
      chosen <- eligible[[sample.int(length(eligible), 1L)]]
      chosen_id <- as.character(chosen$id)
      current <- context$male_matings[chosen_id]
      if (is.na(current)) {
        current <- 0L
      }
      context$male_matings[chosen_id] <- as.integer(current + 1L)
      return(chosen)
    }

    alive_males[[sample.int(length(alive_males), 1L)]]
  }
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
