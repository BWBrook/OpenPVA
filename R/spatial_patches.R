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

.normalize_patch_counts <- function(n_per_patch) {
  if (!is.numeric(n_per_patch) || !length(n_per_patch)) {
    stop("n_per_patch must be a non-empty numeric vector", call. = FALSE)
  }
  n_int <- suppressWarnings(as.integer(n_per_patch))
  if (any(is.na(n_int)) || any(n_int < 0) || any(n_int != n_per_patch)) {
    stop("n_per_patch must contain non-negative integer counts", call. = FALSE)
  }
  if (sum(n_int) <= 0L) {
    stop("n_per_patch must sum to at least 1", call. = FALSE)
  }
  n_int
}

#' Initialize a spatial population from patch counts
#'
#' Creates a population with explicit `patch_id` assignment based on
#' patch-specific starting abundances.
#'
#' @param n_per_patch Non-empty numeric vector of non-negative integer counts
#'   (one value per patch).
#' @param max_age Maximum age passed to [initialize_population()].
#'
#' @return A population list with `patch_id` initialized from `n_per_patch`.
#' @export
initialize_spatial_population <- function(n_per_patch, max_age = 5L) {
  patch_counts <- .normalize_patch_counts(n_per_patch)
  total_n <- sum(patch_counts)
  pop <- initialize_population(n = total_n, max_age = max_age)
  patch_ids <- rep.int(seq_along(patch_counts), patch_counts)
  initialize_patches(pop, patch_ids = patch_ids)
}

#' Initialize a spatial + genetic population from patch counts
#'
#' Creates a spatially structured population and initializes diploid genotypes
#' for all individuals.
#'
#' @param n_per_patch Non-empty numeric vector of non-negative integer counts
#'   (one value per patch).
#' @param n_loci Number of loci passed to [initialize_genotypes()].
#' @param n_alleles Number of allele states passed to [initialize_genotypes()].
#' @param max_age Maximum age passed to [initialize_population()].
#'
#' @return A population list with `patch_id`, `alleles`, and `F` initialized.
#' @export
initialize_spatial_genetic_population <- function(
    n_per_patch,
    n_loci = 10L,
    n_alleles = 2L,
    max_age = 5L) {
  pop <- initialize_spatial_population(
    n_per_patch = n_per_patch,
    max_age = max_age
  )
  initialize_genotypes(pop, n_loci = n_loci, n_alleles = n_alleles)
}
