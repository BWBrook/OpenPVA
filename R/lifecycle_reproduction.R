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
#'   Functions may optionally accept a third `context` argument for stateful
#'   mating controls (for example, male mate quotas).
#' @param require_mate Logical; if `TRUE`, breeders without an assigned mate do
#'   not produce offspring. Defaults to `FALSE` for backward compatibility.
#' @param inherit_fun Optional function taking `(mother, father)` and returning an
#'   allele matrix for the offspring. Defaults to `NULL`, in which case newborns
#'   inherit no genotype (alleles remain `NULL`).
#'
#' @return Updated population list containing newborn individuals appended.
#' @export
apply_reproduction <- function(
    population,
    breeders,
    fecundity_fun = default_fecundity_fun,
    mating_fun = default_mating_fun,
    require_mate = FALSE,
    inherit_fun = NULL) {
  if (!is.logical(require_mate) || length(require_mate) != 1L || is.na(require_mate)) {
    stop("require_mate must be a single logical value", call. = FALSE)
  }

  if (!length(population)) {
    max_id <- 0L
  } else {
    max_id <- max(vapply(population, function(ind) ind$id, integer(1)))
  }

  newborns <- list()
  mating_context <- new.env(parent = emptyenv())
  mating_context$male_matings <- integer()

  if (length(breeders)) {
    for (breeder in breeders) {
      mother <- breeder
      mother_id <- mother$id
      father <- if (is.null(mating_fun)) {
        NULL
      } else {
        .call_mating_fun(
          mating_fun = mating_fun,
          population = population,
          breeder = mother,
          context = mating_context
        )
      }
      if (require_mate && is.null(father)) {
        next
      }
      father_id <- if (is.null(father)) NA_integer_ else father$id

      n_offspring <- fecundity_fun(mother)
      if (!is.numeric(n_offspring) || length(n_offspring) != 1L) {
        stop("fecundity_fun must return a single numeric value")
      }
      n_offspring <- as.integer(floor(n_offspring))
      if (n_offspring <= 0) {
        next
      }
      for (i in seq_len(n_offspring)) {
        max_id <- max_id + 1L
        alleles_new <- NULL
        if (!is.null(inherit_fun) &&
            !is.null(mother$alleles) &&
            !is.null(father) &&
            !is.null(father$alleles)) {
          alleles_new <- inherit_fun(mother, father)
        }
        F_new <- if (is.null(alleles_new)) NA_real_ else .Fhat_from_alleles(alleles_new)
        newborns[[length(newborns) + 1L]] <- create_individual(
          id = max_id,
          sex = sample(c("M", "F"), 1L),
          age = 0L,
          inbreeding_coeff = F_new,
          alleles = alleles_new,
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

.call_mating_fun <- function(mating_fun, population, breeder, context) {
  formal_names <- names(formals(mating_fun))
  supports_context <- !is.null(formal_names) &&
    ("..." %in% formal_names || length(formal_names) >= 3L)

  if (supports_context) {
    return(mating_fun(population, breeder, context))
  }

  mating_fun(population, breeder)
}
