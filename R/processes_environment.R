environment_process <- function(
    variables,
    name = "environment",
    requires = character(),
    params = list()) {
  if (!is.list(variables) || !length(variables) || is.null(names(variables)) ||
      any(!nzchar(names(variables))) || anyDuplicated(names(variables)) ||
      !all(vapply(variables, is.function, logical(1)))) {
    .stop("variables must be a uniquely named list of functions of (state, context, params)")
  }
  pva_process(
    name = name,
    run = function(state, context, params) {
      for (variable in names(params$variables)) {
        state$globals[[variable]] <-
          params$variables[[variable]](state, context, params$user)
      }
      pva_result(state)
    },
    params = list(variables = variables, user = params),
    requires = requires,
    writes = paste0("globals.", names(variables)),
    description = "Draw shared environmental conditions for the interval."
  )
}

catastrophe_process <- function(
    probability,
    mortality = NULL,
    eligible = NULL,
    name = "catastrophe",
    global = name,
    requires = character(),
    params = list()) {
  probability <- .count_function(probability, "probability")
  if (!is.null(mortality)) {
    mortality <- .rate_function(mortality, "mortality")
  }
  .check_optional_function(eligible, "eligible")
  if (!.is_name(global)) {
    .stop("global must be one non-empty name")
  }
  pva_process(
    name = name,
    run = function(state, context, params) {
      user <- params$user
      chance <- params$probability(state, context, user)
      if (!is.numeric(chance) || length(chance) != 1L || is.na(chance) ||
          chance < 0 || chance > 1) {
        .stop("catastrophe probability must evaluate to one number in [0, 1]")
      }
      occurs <- stats::runif(1L) < chance
      state$globals[[params$global]] <- occurs
      n_died <- 0L
      if (occurs && !is.null(params$mortality)) {
        pop <- state$population
        rows <- .eligible_rows(params$eligible, pop, state, context, user)
        risk <- .per_individual(
          params$mortality(pop, state, context, user),
          length(pop$id), "catastrophe mortality", 0, 1
        )
        died <- rows[stats::runif(length(rows)) < risk[rows]]
        n_died <- length(died)
        if (n_died) {
          state$population$alive[died] <- FALSE
        }
      }
      pva_result(
        state,
        pva_events(c("catastrophe", "death"), c(as.numeric(occurs), n_died), params$global)
      )
    },
    params = list(
      probability = probability,
      mortality = mortality,
      eligible = eligible,
      global = global,
      user = params
    ),
    requires = unique(c("population.alive", requires)),
    writes = c(paste0("globals.", global), "population.alive"),
    description = "Bernoulli catastrophe flag with optional direct mortality."
  )
}

beta_shapes <- function(mean, sd) {
  if (!is.numeric(mean) || !is.numeric(sd) || anyNA(mean) || anyNA(sd) ||
      any(mean <= 0 | mean >= 1) || any(sd <= 0)) {
    .stop("mean must lie in (0, 1) and sd must be positive")
  }
  scale <- mean * (1 - mean) / sd^2 - 1
  if (any(scale <= 0)) {
    .stop("sd is too large for a beta distribution with this mean")
  }
  list(shape1 = mean * scale, shape2 = (1 - mean) * scale)
}

shift_logit <- function(probability, deviation) {
  if (!is.numeric(probability) || anyNA(probability) ||
      any(probability < 0 | probability > 1)) {
    .stop("probability must be non-missing values in [0, 1]")
  }
  if (!is.numeric(deviation) || anyNA(deviation)) .stop("deviation must be non-missing numeric")
  result <- stats::plogis(stats::qlogis(probability) + deviation)
  p <- rep_len(probability, length(result))
  result[p == 0 | p == 1] <- p[p == 0 | p == 1]
  result
}

ceiling_density_multiplier <- function(n, capacity) {
  .check_density_inputs(n, capacity)
  ifelse(n > capacity, capacity / pmax(n, 1), 1)
}

beverton_holt_multiplier <- function(n, capacity, growth) {
  .check_density_inputs(n, capacity, growth)
  1 / (1 + (growth - 1) * n / capacity)
}

ricker_multiplier <- function(n, capacity, growth) {
  .check_density_inputs(n, capacity, growth)
  exp(-log(growth) * n / capacity)
}

.check_density_inputs <- function(n, capacity, growth = NULL) {
  if (!is.numeric(n) || anyNA(n) || any(n < 0)) {
    .stop("n must be non-negative numbers")
  }
  if (!is.numeric(capacity) || anyNA(capacity) || any(capacity <= 0)) {
    .stop("capacity must be positive")
  }
  if (!is.null(growth) &&
      (!is.numeric(growth) || anyNA(growth) || any(growth < 1))) {
    .stop("growth must be a low-density multiplier of at least 1")
  }
  invisible(TRUE)
}
