#' Construct a density module specification
#'
#' Density modules provide channel-specific multiplicative modifiers for
#' controller vital-rate calculations.
#'
#' @param survival_fun Optional function with signature
#'   `function(population, ind)` returning a finite numeric multiplier `>= 0`
#'   for survival probabilities.
#' @param breeding_fun Optional function with signature
#'   `function(population, ind)` returning a finite numeric multiplier `>= 0`
#'   for breeding probabilities.
#' @param fecundity_fun Optional function with signature
#'   `function(population, ind)` returning a finite numeric multiplier `>= 0`
#'   for fecundity lambdas.
#'
#' @return An object of class `openpva_density_spec`.
#' @export
density_spec <- function(
    survival_fun = NULL,
    breeding_fun = NULL,
    fecundity_fun = NULL) {
  spec <- list(
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun
  )
  validate_density_spec(spec)
}

#' Validate a density module specification
#'
#' @param spec Object returned by [density_spec()].
#'
#' @return A validated `openpva_density_spec` object.
#' @export
validate_density_spec <- function(spec) {
  if (!is.list(spec)) {
    stop("density spec must be a list", call. = FALSE)
  }

  allowed <- c("survival_fun", "breeding_fun", "fecundity_fun")
  unknown <- setdiff(names(spec), allowed)
  if (length(unknown)) {
    stop(
      "density spec has unknown fields: ",
      paste(unknown, collapse = ", "),
      call. = FALSE
    )
  }

  for (nm in allowed) {
    fn <- spec[[nm]]
    if (!is.null(fn) && !is.function(fn)) {
      stop(nm, " must be NULL or a function", call. = FALSE)
    }
  }

  if (all(vapply(spec[allowed], is.null, logical(1)))) {
    stop("density spec must define at least one channel function", call. = FALSE)
  }

  class(spec) <- c("openpva_density_spec", "list")
  spec
}

#' Build a ceiling-style density multiplier function
#'
#' @param K Optional global carrying capacity (> 0).
#' @param K_patches Optional patch-specific carrying capacities (numeric vector
#'   with all values > 0). Provide either `K` or `K_patches`, not both.
#'
#' @return A function with signature `function(population, ind)` returning a
#'   density multiplier in `(0, 1]`.
#' @export
make_ceiling_density_fun <- function(K = NULL, K_patches = NULL) {
  if (!is.null(K) && !is.null(K_patches)) {
    stop("Specify either K or K_patches, not both", call. = FALSE)
  }

  if (!is.null(K)) {
    if (!is.numeric(K) || length(K) != 1L || is.na(K) || K <= 0) {
      stop("K must be a single numeric value > 0", call. = FALSE)
    }
    K <- as.numeric(K)
  }

  if (!is.null(K_patches)) {
    if (!is.numeric(K_patches) || !length(K_patches) ||
        any(is.na(K_patches)) || any(K_patches <= 0)) {
      stop("K_patches must be a numeric vector with all values > 0", call. = FALSE)
    }
    K_patches <- as.numeric(K_patches)
  }

  if (is.null(K) && is.null(K_patches)) {
    stop("Provide at least one of K or K_patches", call. = FALSE)
  }

  function(population, ind) {
    alive_flags <- vapply(population, function(x) isTRUE(x$alive), logical(1))
    n_alive <- sum(alive_flags)
    if (n_alive <= 0L) {
      return(1)
    }

    if (!is.null(K)) {
      if (n_alive <= K) {
        return(1)
      }
      return(K / n_alive)
    }

    pid <- ind$patch_id
    if (is.null(pid) || is.na(pid)) {
      return(1)
    }
    pid <- as.integer(pid)
    if (pid < 1L || pid > length(K_patches)) {
      return(1)
    }

    patch_ids <- vapply(
      population,
      function(x) {
        p <- x$patch_id
        if (is.null(p) || is.na(p)) {
          return(NA_integer_)
        }
        as.integer(p)
      },
      integer(1)
    )
    n_patch_alive <- sum(alive_flags & !is.na(patch_ids) & patch_ids == pid)
    if (n_patch_alive <= K_patches[pid]) {
      return(1)
    }
    K_patches[pid] / n_patch_alive
  }
}

.eval_density_multiplier <- function(
    density_fun,
    population,
    ind,
    channel_label) {
  if (is.null(density_fun)) {
    return(1)
  }
  mult <- density_fun(population, ind)
  if (!is.numeric(mult) || length(mult) != 1L || is.na(mult) ||
      !is.finite(mult) || mult < 0) {
    stop(
      channel_label, " density function must return a single finite numeric value >= 0",
      call. = FALSE
    )
  }
  as.numeric(mult)
}
