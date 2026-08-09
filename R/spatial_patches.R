.normalize_patch_domain <- function(patch_domain, label = "patch_domain") {
  if (!is.numeric(patch_domain) || !length(patch_domain) || anyNA(patch_domain) ||
      any(!is.finite(patch_domain)) || any(patch_domain != floor(patch_domain)) ||
      any(patch_domain <= 0) || any(patch_domain > .Machine$integer.max)) {
    stop(label, " must contain positive integer-like patch identifiers", call. = FALSE)
  }
  domain <- as.integer(patch_domain)
  if (anyDuplicated(domain)) {
    stop(label, " must not contain duplicate patch identifiers", call. = FALSE)
  }
  domain
}

.normalize_patch_ids <- function(patch_ids, patch_domain, label = "patch_ids") {
  if (!is.numeric(patch_ids) || anyNA(patch_ids) ||
      any(!is.finite(patch_ids)) || any(patch_ids != floor(patch_ids)) ||
      any(patch_ids <= 0) || any(patch_ids > .Machine$integer.max)) {
    stop(label, " must contain non-missing positive integer-like values", call. = FALSE)
  }
  patch_ids <- as.integer(patch_ids)
  unknown <- setdiff(unique(patch_ids), patch_domain)
  if (length(unknown)) {
    stop(
      label, " contains identifier(s) outside patch_domain: ",
      paste(unknown, collapse = ", "),
      call. = FALSE
    )
  }
  patch_ids
}

.population_patch_ids <- function(population, patch_domain) {
  if (!length(population)) {
    return(integer())
  }
  values <- vapply(seq_along(population), function(index) {
    individual <- population[[index]]
    if (!is.list(individual) || !"patch_id" %in% names(individual) ||
        is.null(individual$patch_id)) {
      stop(
        "individual ", index, " is missing required field population.patch_id",
        call. = FALSE
      )
    }
    .normalize_patch_ids(
      individual$patch_id,
      patch_domain,
      paste0("population[[", index, "]]$patch_id")
    )
  }, integer(1))
  unname(values)
}

#' Assign explicit patch identifiers
#'
#' Assigns one modeller-supplied `patch_id` to each individual within an
#' explicit ordered patch domain. Empty declared patches are valid; OpenPVA
#' does not invent or balance an initial patch distribution.
#'
#' @param population List of individual records.
#' @param patch_ids Numeric vector containing one positive integer-like patch
#'   identifier per individual.
#' @param patch_domain Ordered numeric vector of unique positive integer-like
#'   patch identifiers. Identifiers need not be consecutive.
#'
#' @return The population list with strict integer `patch_id` fields.
#' @export
initialize_patches <- function(population, patch_ids, patch_domain) {
  if (!is.list(population)) {
    stop("population must be a list", call. = FALSE)
  }
  if (length(population) && !all(vapply(population, is.list, logical(1)))) {
    stop("every population record must be a list", call. = FALSE)
  }
  patch_domain <- .normalize_patch_domain(patch_domain)
  patch_ids <- .normalize_patch_ids(patch_ids, patch_domain)
  if (length(patch_ids) != length(population)) {
    stop("patch_ids must have length equal to the population size", call. = FALSE)
  }
  Map(
    function(individual, patch_id) {
      individual$patch_id <- patch_id
      individual
    },
    population,
    patch_ids,
    USE.NAMES = FALSE
  )
}

#' Construct a patch-abundance snapshot process
#'
#' Counts living individuals in every member of an explicit patch domain at the
#' process's exact lifecycle position. Counts, including zeros, are stored as a
#' keyed integer vector in `state$globals$patch_density_counts`; one
#' `patch_density_snapshot` event is emitted per patch.
#'
#' @param patch_domain Ordered numeric vector of unique positive integer-like
#'   patch identifiers.
#' @param name Process name.
#'
#' @return A validated lifecycle process.
#' @export
patch_density_snapshot_process <- function(
    patch_domain,
    name = "patch_density_snapshot") {
  patch_domain <- .normalize_patch_domain(patch_domain)
  pva_process(
    name = name,
    run = function(state, context, params) {
      patch_ids <- .population_patch_ids(state$population, params$patch_domain)
      alive <- if (length(state$population)) {
        vapply(state$population, function(individual) isTRUE(individual$alive), logical(1))
      } else {
        logical()
      }
      counts <- tabulate(
        match(patch_ids[alive], params$patch_domain),
        nbins = length(params$patch_domain)
      )
      counts <- stats::setNames(as.integer(counts), as.character(params$patch_domain))
      state$globals$patch_density_counts <- counts
      events <- lapply(seq_along(params$patch_domain), function(index) {
        list(
          event_type = "patch_density_snapshot",
          patch_id = params$patch_domain[[index]],
          value = counts[[index]]
        )
      })
      pva_result(state, events)
    },
    params = list(patch_domain = patch_domain),
    requires = c("population.id", "population.alive", "population.patch_id"),
    writes = "globals.patch_density_counts",
    description = "Record living abundance for every declared patch at this position."
  )
}

.normalize_keyed_patch_values <- function(values, label, whole, positive) {
  if (!is.numeric(values) || !length(values) || is.null(names(values)) ||
      anyNA(values) || any(!is.finite(values)) || any(!nzchar(names(values))) ||
      anyDuplicated(names(values))) {
    stop(label, " must be a finite named numeric vector with unique keys", call. = FALSE)
  }
  key_values <- suppressWarnings(as.numeric(names(values)))
  if (anyNA(key_values)) {
    stop(label, " names must be canonical positive integer patch identifiers", call. = FALSE)
  }
  keys <- .normalize_patch_domain(key_values, paste0(label, " names"))
  if (!identical(names(values), as.character(keys))) {
    stop(label, " names must be canonical positive integer patch identifiers", call. = FALSE)
  }
  if (whole && any(values != floor(values))) {
    stop(label, " must contain whole-number values", call. = FALSE)
  }
  if (positive && any(values <= 0)) {
    stop(label, " must contain positive values", call. = FALSE)
  }
  if (!positive && any(values < 0)) {
    stop(label, " must contain non-negative values", call. = FALSE)
  }
  values
}

#' Calculate a keyed patch-density multiplier
#'
#' Strictly matches one patch identifier against complete keyed abundance and
#' capacity vectors, then delegates the biological response to
#' [ceiling_density_multiplier()]. Key order and membership must match exactly.
#'
#' @param patch_id One positive integer-like patch identifier.
#' @param counts Named non-negative whole-number abundance vector.
#' @param capacities Named positive finite capacity vector with keys and order
#'   identical to `counts`.
#'
#' @return A numeric multiplier in `(0, 1]`.
#' @export
patch_density_multiplier <- function(patch_id, counts, capacities) {
  if (length(patch_id) != 1L) {
    stop("patch_id must contain exactly one value", call. = FALSE)
  }
  patch_id <- .normalize_patch_domain(patch_id, "patch_id")
  counts <- .normalize_keyed_patch_values(
    counts, "counts", whole = TRUE, positive = FALSE
  )
  capacities <- .normalize_keyed_patch_values(
    capacities, "capacities", whole = FALSE, positive = TRUE
  )
  if (!identical(names(counts), names(capacities))) {
    stop("counts and capacities must have identical patch keys and order", call. = FALSE)
  }
  key <- as.character(patch_id)
  if (!key %in% names(counts)) {
    stop("patch_id is not present in counts and capacities", call. = FALSE)
  }
  ceiling_density_multiplier(unname(counts[[key]]), unname(capacities[[key]]))
}
