#' Create an individual agent
#'
#' Initializes a list representing one demographic individual. Optional
#' pedigree fields are added explicitly with the pedigree helpers.
#'
#' @param id Integer. Unique identifier.
#' @param sex Character. "M" or "F".
#' @param age Integer. Age in years.
#' @param alive Logical. Is the individual alive? Defaults to TRUE.
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
    mother_id = NA_integer_,
    father_id = NA_integer_,
    patch_id = NA_integer_) {
  id <- .normalize_integer_scalar(id, "id", minimum = 1L)
  age <- .normalize_integer_scalar(age, "age", minimum = 0L)
  mother_id <- .normalize_integer_scalar(
    mother_id, "mother_id", allow_na = TRUE, minimum = 1L
  )
  father_id <- .normalize_integer_scalar(
    father_id, "father_id", allow_na = TRUE, minimum = 1L
  )
  patch_id <- .normalize_integer_scalar(
    patch_id, "patch_id", allow_na = TRUE, minimum = 1L
  )
  list(
    id = id,
    sex = as.character(sex),
    age = age,
    alive = as.logical(alive),
    mother_id = mother_id,
    father_id = father_id,
    patch_id = patch_id
  )
}
