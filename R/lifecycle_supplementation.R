#' Apply supplementation/translocation to a population
#'
#' Adds new individuals to the population according to a yearly quota, e.g.
#' for rescue stocking or translocation.
#'
#' @param population List of individual objects.
#' @param n_add Number of individuals to add (integer or coercible numeric).
#' @param patch_id Optional patch identifier to assign to all new individuals.
#'
#' @return A list with `population` (updated) and `n_added` (actual number added).
#' @export
apply_supplementation <- function(population, n_add, patch_id = NULL) {
  if (!is.numeric(n_add) || length(n_add) != 1L || !is.finite(n_add) ||
      n_add < 0 || n_add != floor(n_add)) {
    stop("n_add must be a finite non-negative integer")
  }
  n_add <- suppressWarnings(as.integer(n_add))
  if (is.na(n_add)) {
    stop("n_add must be representable as an integer")
  }
  if (n_add == 0L) {
    return(list(population = population, n_added = 0L))
  }

  max_id <- if (length(population)) {
    max(vapply(population, function(ind) ind$id, integer(1)))
  } else {
    0L
  }

  pid <- if (is.null(patch_id)) NA_integer_ else as.integer(patch_id)
  newcomers <- vector("list", n_add)
  for (i in seq_len(n_add)) {
    max_id <- max_id + 1L
    sex <- sample(c("M", "F"), size = 1L)
    newcomers[[i]] <- create_individual(
      id = max_id,
      sex = sex,
      age = 0L,
      patch_id = pid
    )
  }

  list(
    population = c(population, newcomers),
    n_added = n_add
  )
}
