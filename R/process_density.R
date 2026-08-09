#' Construct a global abundance snapshot process
#'
#' The process counts living individuals at its exact position in the ordered
#' lifecycle, writes the count to `state$globals$density_n_alive`, and emits a
#' `density_snapshot` event. Moving the process changes which population state
#' is measured; the engine gives it no privileged execution semantics.
#'
#' @param name Process name.
#'
#' @return A validated lifecycle process.
#' @export
density_snapshot_process <- function(name = "density_snapshot") {
  pva_process(
    name = name,
    run = function(state, context, params) {
      n_alive <- as.integer(sum(vapply(
        state$population,
        function(individual) isTRUE(individual$alive),
        logical(1)
      )))
      state$globals$density_n_alive <- n_alive
      pva_result(
        state,
        list(list(event_type = "density_snapshot", n_alive = n_alive))
      )
    },
    requires = c("population.id", "population.alive"),
    writes = "globals.density_n_alive",
    description = "Record global living abundance at this lifecycle position."
  )
}

#' Calculate a ceiling-style density multiplier
#'
#' This pure function is neutral at or below `capacity` and returns
#' `capacity / n_alive` above it. It represents phenomenological feedback on a
#' modeller-selected vital rate. It does not cap or remove individuals, estimate
#' carrying capacity, or guarantee an equilibrium.
#'
#' @param n_alive Non-negative whole-number living abundance, normally read
#'   from `state$globals$density_n_alive` by a process callback.
#' @param capacity Positive finite modeller-supplied capacity.
#'
#' @return A numeric multiplier in `(0, 1]`.
#' @export
ceiling_density_multiplier <- function(n_alive, capacity) {
  if (!is.numeric(n_alive) || length(n_alive) != 1L || is.na(n_alive) ||
      !is.finite(n_alive) || n_alive < 0 || n_alive != floor(n_alive)) {
    stop("n_alive must be one finite non-negative whole number", call. = FALSE)
  }
  if (!is.numeric(capacity) || length(capacity) != 1L || is.na(capacity) ||
      !is.finite(capacity) || capacity <= 0) {
    stop("capacity must be one finite positive numeric value", call. = FALSE)
  }
  if (n_alive <= capacity) 1 else as.numeric(capacity / n_alive)
}
