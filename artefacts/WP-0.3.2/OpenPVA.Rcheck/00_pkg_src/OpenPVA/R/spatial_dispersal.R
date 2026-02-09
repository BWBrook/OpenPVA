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
