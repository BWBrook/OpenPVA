#' Default dispersal function (no movement)
#'
#' Returns the individual's current `patch_id`, implying no dispersal.
#'
#' @param ind Individual object.
#' @param population Full population list (unused, but part of the interface).
#'
#' @return The individual's existing `patch_id`.
#' @export
default_dispersal_fun <- function(ind, population) {
  ind$patch_id
}

#' Apply dispersal to a population
#'
#' Updates each living individual's `patch_id` according to a user-supplied
#' dispersal rule.
#'
#' @param population List of individual objects.
#' @param dispersal_fun Function with signature `function(ind, population)` that
#'   returns a new patch identifier (integer or `NA`).
#'
#' @return Modified population with updated `patch_id` values.
#' @export
apply_dispersal <- function(population, dispersal_fun) {
  if (!is.function(dispersal_fun)) {
    stop("dispersal_fun must be a function", call. = FALSE)
  }
  if (!length(population)) {
    return(population)
  }

  population <- Map(
    function(ind) {
      if (isTRUE(ind$alive)) {
        new_pid <- dispersal_fun(ind, population)
        if (length(new_pid) == 0L || is.null(new_pid)) {
          ind$patch_id <- NA_integer_
        } else {
          new_pid <- as.integer(new_pid[1L])
          if (is.na(new_pid)) {
            ind$patch_id <- NA_integer_
          } else {
            ind$patch_id <- new_pid
          }
        }
      }
      ind
    },
    population,
    USE.NAMES = FALSE
  )
  population
}

#' Create a Markov dispersal function
#'
#' Converts a patch-to-patch transition matrix into a dispersal function
#' compatible with `apply_dispersal()`.
#'
#' @param transition_matrix Square numeric matrix where rows correspond to
#'   origin patches and columns to destination patches. Entries must be
#'   non-negative; rows are normalised internally.
#'
#' @return A function with signature `function(ind, population)` that returns a
#'   destination patch identifier.
#' @export
make_markov_dispersal_fun <- function(transition_matrix) {
  if (!is.matrix(transition_matrix)) {
    stop("transition_matrix must be a matrix", call. = FALSE)
  }
  if (nrow(transition_matrix) != ncol(transition_matrix)) {
    stop("transition_matrix must be square", call. = FALSE)
  }
  if (any(!is.finite(transition_matrix)) || any(transition_matrix < 0)) {
    stop("transition_matrix must contain non-negative finite values", call. = FALSE)
  }
  n_patches <- nrow(transition_matrix)
  probs <- matrix(0, nrow = n_patches, ncol = n_patches)
  for (i in seq_len(n_patches)) {
    row_sum <- sum(transition_matrix[i, ])
    if (row_sum <= 0) {
      stop("Each row of transition_matrix must have positive sum", call. = FALSE)
    }
    probs[i, ] <- transition_matrix[i, ] / row_sum
  }
  function(ind, population) {
    pid <- ind$patch_id
    if (is.null(pid) || is.na(pid)) {
      return(ind$patch_id)
    }
    pid_int <- as.integer(pid)
    if (pid_int < 1L || pid_int > n_patches) {
      return(ind$patch_id)
    }
    dest <- base::sample.int(n = n_patches, size = 1L, prob = probs[pid_int, ])
    as.integer(dest)
  }
}

.fixed_markov_dispersal <- function(transition_matrix) {
  dispersal_fun <- make_markov_dispersal_fun(transition_matrix)
  function(ind, population) dispersal_fun(ind, population)
}

#' Low-connectivity dispersal regime (3 patches)
#'
#' A convenience dispersal rule for fragmented systems where most individuals
#' remain in their current patch each year.
#'
#' @param ind Individual object.
#' @param population Full population list (unused, but part of the interface).
#'
#' @return Destination `patch_id` sampled from a low-connectivity transition
#'   matrix.
#' @export
dispersal_low_connectivity_fun <- local({
  f <- .fixed_markov_dispersal(
    matrix(
      c(
        0.95, 0.04, 0.01,
        0.03, 0.94, 0.03,
        0.02, 0.05, 0.93
      ),
      nrow = 3,
      byrow = TRUE
    )
  )
  function(ind, population) f(ind, population)
})

#' High-connectivity dispersal regime (3 patches)
#'
#' A convenience dispersal rule for connected systems with substantial
#' cross-patch movement.
#'
#' @param ind Individual object.
#' @param population Full population list (unused, but part of the interface).
#'
#' @return Destination `patch_id` sampled from a high-connectivity transition
#'   matrix.
#' @export
dispersal_high_connectivity_fun <- local({
  f <- .fixed_markov_dispersal(
    matrix(
      c(
        0.55, 0.25, 0.20,
        0.25, 0.50, 0.25,
        0.20, 0.25, 0.55
      ),
      nrow = 3,
      byrow = TRUE
    )
  )
  function(ind, population) f(ind, population)
})

#' Asymmetric-flow dispersal regime (3 patches)
#'
#' A convenience dispersal rule where movement probabilities differ strongly by
#' origin patch, producing directional flow patterns.
#'
#' @param ind Individual object.
#' @param population Full population list (unused, but part of the interface).
#'
#' @return Destination `patch_id` sampled from an asymmetric transition matrix.
#' @export
dispersal_asymmetric_flow_fun <- local({
  f <- .fixed_markov_dispersal(
    matrix(
      c(
        0.78, 0.18, 0.04,
        0.12, 0.72, 0.16,
        0.35, 0.10, 0.55
      ),
      nrow = 3,
      byrow = TRUE
    )
  )
  function(ind, population) f(ind, population)
})
