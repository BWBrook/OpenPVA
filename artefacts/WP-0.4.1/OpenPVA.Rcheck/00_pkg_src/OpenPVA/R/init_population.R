#' Create an individual agent
#'
#' Initializes a list representing a single individual with demographic and optional genetic attributes.
#'
#' @param id Integer. Unique identifier.
#' @param sex Character. "M" or "F".
#' @param age Integer. Age in years.
#' @param alive Logical. Is the individual alive? Defaults to TRUE.
#' @param alleles List or NULL. Placeholder for genetic attributes.
#' @param inbreeding_coeff Numeric. Inbreeding coefficient (F). Defaults to 0.
#' @param mother_id Integer. ID of the mother if known.
#' @param father_id Integer. ID of the father if known.
#' @param patch_id Integer. Optional patch identifier.
#'
#' @return A list representing an individual.
#' @export
create_individual <- function(
    id,
    sex,
    age,
    alive = TRUE,
    alleles = NULL,
    inbreeding_coeff = 0,
    mother_id = NA_integer_,
    father_id = NA_integer_,
    patch_id = NA_integer_) {
  list(
    id = id,
    sex = sex,
    age = age,
    alive = alive,
    alleles = alleles,
    F = inbreeding_coeff,
    mother_id = mother_id,
    father_id = father_id,
    patch_id = patch_id
  )
}

#' Initialise a population of individuals
#'
#' Creates a list of `n` individuals with randomly assigned sex and age.
#'
#' @param n Integer. Number of individuals to initialise.
#' @param max_age Integer. Maximum age for random age assignment. Defaults to 10.
#'
#' @return A list of individual objects.
#' @export
initialize_population <- function(n = 10, max_age = 10) {
  lapply(seq_len(n), function(i) {
    create_individual(
      id = i,
      sex = sample(c("M", "F"), 1),
      age = sample(0:max_age, 1)
    )
  })
}
