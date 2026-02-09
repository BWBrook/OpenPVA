#' Assign individuals to spatial patches
#'
#' Populates the `patch_id` field for each individual either from an explicit
#' vector or by applying a deterministic assignment rule across a specified
#' number of patches.
#'
#' @param population List of individual objects.
#' @param n_patches Positive integer number of patches (required unless
#'   `patch_ids` is supplied).
#' @param patch_ids Optional integer vector with one entry per individual. When
#'   provided, it is used directly and overrides `n_patches` and
#'   `assignment_fun`.
#' @param assignment_fun Optional function with signature
#'   `function(population, n_patches)` that returns a vector of patch identifiers
#'   (coercible to integer) for each individual.
#'
#' @return The population list with updated `patch_id` entries.
#' @export
initialize_patches <- function(
    population,
    n_patches = NULL,
    patch_ids = NULL,
    assignment_fun = NULL) {
  if (!length(population)) {
    return(population)
  }

  assign_patch_ids <- NULL

  if (!is.null(patch_ids)) {
    if (length(patch_ids) != length(population)) {
      stop("patch_ids must have length equal to the population size", call. = FALSE)
    }
    assign_patch_ids <- as.integer(patch_ids)
  } else {
    if (is.null(n_patches) || !is.numeric(n_patches) || length(n_patches) != 1L || n_patches <= 0) {
      stop("n_patches must be a positive integer when patch_ids is NULL", call. = FALSE)
    }
    n_patches <- as.integer(n_patches)

    if (is.null(assignment_fun)) {
      assign_patch_ids <- as.integer(((seq_along(population) - 1L) %% n_patches) + 1L)
    } else {
      if (!is.function(assignment_fun)) {
        stop("assignment_fun must be a function", call. = FALSE)
      }
      assign_patch_ids <- assignment_fun(population, n_patches)
      if (length(assign_patch_ids) != length(population)) {
        stop("assignment_fun must return one patch per individual", call. = FALSE)
      }
      assign_patch_ids <- as.integer(assign_patch_ids)
    }
  }

  Map(
    function(ind, pid) {
      ind$patch_id <- pid
      ind
    },
    population,
    assign_patch_ids,
    USE.NAMES = FALSE
  )
}
