#' Construct a simultaneous patch-transition process
#'
#' Applies one modeller-supplied destination rule to eligible living
#' individuals. Every rule call sees the same pre-process state, after which all
#' validated destinations are applied together. The process emits aggregate
#' `patch_transition` events, including diagonal retention.
#'
#' @param patch_domain Ordered numeric vector of unique positive integer-like
#'   patch identifiers.
#' @param destination Function called as
#'   `destination(individual, state, context, params)` and returning one
#'   destination patch identifier.
#' @param eligible Optional function with the same arguments returning one
#'   non-missing logical value. Dead individuals are never eligible. `NULL`
#'   makes every living individual eligible.
#' @param name Process name.
#' @param requires Additional state paths used by `destination` or `eligible`.
#' @param params Explicit modeller parameters passed to both callbacks.
#'
#' @return A validated lifecycle process.
#' @export
dispersal_process <- function(
    patch_domain,
    destination,
    eligible = NULL,
    name = "dispersal",
    requires = character(),
    params = list()) {
  patch_domain <- .normalize_patch_domain(patch_domain)
  if (!is.function(destination)) {
    stop("destination must be a function", call. = FALSE)
  }
  if (is.null(eligible)) {
    eligible <- function(individual, state, context, params) TRUE
  }
  if (!is.function(eligible)) {
    stop("eligible must be NULL or a function", call. = FALSE)
  }
  if (!is.list(params)) {
    stop("params must be a list", call. = FALSE)
  }

  pva_process(
    name = name,
    run = function(state, context, process_params) {
      pre_state <- state
      patch_ids <- .population_patch_ids(
        pre_state$population,
        process_params$patch_domain
      )
      selected <- if (length(pre_state$population)) {
        vapply(seq_along(pre_state$population), function(index) {
          individual <- pre_state$population[[index]]
          if (!isTRUE(individual$alive)) {
            return(FALSE)
          }
          value <- process_params$eligible(
            individual,
            pre_state,
            context,
            process_params$model
          )
          if (!is.logical(value) || length(value) != 1L || is.na(value)) {
            stop("eligible must return one non-missing logical value", call. = FALSE)
          }
          value
        }, logical(1))
      } else {
        logical()
      }
      indices <- which(selected)
      destinations <- if (length(indices)) {
        vapply(indices, function(index) {
          value <- process_params$destination(
            pre_state$population[[index]],
            pre_state,
            context,
            process_params$destination_model %||% process_params$model
          )
          .normalize_patch_ids(
            value,
            process_params$patch_domain,
            "destination"
          )
        }, integer(1))
      } else {
        integer()
      }

      for (offset in seq_along(indices)) {
        state$population[[indices[[offset]]]]$patch_id <- destinations[[offset]]
      }

      events <- list()
      if (length(indices)) {
        origins <- patch_ids[indices]
        counts <- table(
          factor(origins, levels = process_params$patch_domain),
          factor(destinations, levels = process_params$patch_domain)
        )
        realised <- which(counts > 0L, arr.ind = TRUE)
        events <- lapply(seq_len(nrow(realised)), function(row) {
          list(
            event_type = "patch_transition",
            origin_patch_id = process_params$patch_domain[[realised[row, 1L]]],
            destination_patch_id = process_params$patch_domain[[realised[row, 2L]]],
            value = as.integer(counts[realised[row, 1L], realised[row, 2L]])
          )
        })
      }
      pva_result(state, events)
    },
    params = list(
      patch_domain = patch_domain,
      destination = destination,
      eligible = eligible,
      model = params
    ),
    requires = unique(c(
      "population.id", "population.alive", "population.patch_id", requires
    )),
    writes = "population.patch_id",
    description = "Apply simultaneous modeller-defined discrete patch transitions."
  )
}

.patch_probability_tolerance <- sqrt(.Machine$double.eps)

.validate_transition_matrix <- function(
    transition_matrix,
    patch_domain,
    tolerance = .patch_probability_tolerance) {
  if (!is.matrix(transition_matrix) || !is.numeric(transition_matrix)) {
    stop("transition_matrix must be a numeric matrix", call. = FALSE)
  }
  expected <- length(patch_domain)
  if (!identical(dim(transition_matrix), c(expected, expected))) {
    stop("transition_matrix dimensions must match patch_domain", call. = FALSE)
  }
  if (anyNA(transition_matrix) || any(!is.finite(transition_matrix)) ||
      any(transition_matrix < 0) || any(transition_matrix > 1)) {
    stop("transition_matrix entries must be finite probabilities in [0, 1]", call. = FALSE)
  }
  expected_names <- as.character(patch_domain)
  matrix_names <- dimnames(transition_matrix)
  if (!is.null(matrix_names) &&
      (!identical(matrix_names[[1L]], expected_names) ||
       !identical(matrix_names[[2L]], expected_names))) {
    stop("transition_matrix dimnames must exactly match patch_domain", call. = FALSE)
  }
  if (any(abs(rowSums(transition_matrix) - 1) > tolerance)) {
    stop(
      "transition_matrix rows must sum to 1 within sqrt(.Machine$double.eps)",
      call. = FALSE
    )
  }
  transition_matrix
}

#' Construct a Markov patch-transition process
#'
#' Uses an explicit row-stochastic matrix whose rows and columns follow the
#' supplied ordered patch domain. Rows must already sum to one within
#' `sqrt(.Machine$double.eps)`; they are never normalised internally. If matrix
#' dimnames are supplied, both dimensions must exactly match the domain.
#'
#' @inheritParams dispersal_process
#' @param transition_matrix Numeric square matrix of origin-row to
#'   destination-column probabilities.
#' @param requires Additional state paths used by `eligible`.
#' @param params Explicit modeller parameters passed to `eligible`.
#'
#' @return A validated lifecycle process.
#' @export
markov_dispersal_process <- function(
    patch_domain,
    transition_matrix,
    eligible = NULL,
    name = "dispersal",
    requires = character(),
    params = list()) {
  patch_domain <- .normalize_patch_domain(patch_domain)
  transition_matrix <- .validate_transition_matrix(
    transition_matrix,
    patch_domain
  )
  destination <- function(individual, state, context, params) {
    origin <- match(individual$patch_id, params$patch_domain)
    destination_index <- base::sample.int(
      length(params$patch_domain),
      size = 1L,
      prob = params$transition_matrix[origin, ]
    )
    params$patch_domain[[destination_index]]
  }
  process <- dispersal_process(
    patch_domain = patch_domain,
    destination = destination,
    eligible = eligible,
    name = name,
    requires = requires,
    params = params
  )
  process$params$destination_model <- list(
    patch_domain = patch_domain,
    transition_matrix = transition_matrix
  )
  process$validate_params <- function(process_params) {
    effective_domain <- .normalize_patch_domain(
      process_params$patch_domain,
      "process patch_domain"
    )
    destination_model <- process_params$destination_model
    if (!is.list(destination_model) ||
        !all(c("patch_domain", "transition_matrix") %in% names(destination_model))) {
      stop(
        "Markov destination_model must contain patch_domain and transition_matrix",
        call. = FALSE
      )
    }
    destination_domain <- .normalize_patch_domain(
      destination_model$patch_domain,
      "Markov destination patch_domain"
    )
    if (!identical(destination_domain, effective_domain)) {
      stop(
        "Markov destination patch_domain must match process patch_domain",
        call. = FALSE
      )
    }
    .validate_transition_matrix(
      destination_model$transition_matrix,
      effective_domain
    )
    invisible(process_params)
  }
  process$description <- "Draw simultaneous discrete transitions from an explicit Markov matrix."
  .validate_process(process)
}
