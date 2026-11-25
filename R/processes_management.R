.count_function <- function(value, label) {
  if (is.function(value)) {
    return(value)
  }
  if (!is.numeric(value) || length(value) != 1L || is.na(value) || value < 0) {
    .stop(label, " must be one non-negative number or a function of (state, context, params)")
  }
  force(value)
  function(state, context, params) value
}

.pick_rows <- function(rows, n, order) {
  if (n >= length(rows)) {
    return(rows)
  }
  if (n <= 0) {
    return(integer())
  }
  if (order == "id") rows[seq_len(n)] else rows[sample.int(length(rows), n)]
}

.loss_process <- function(
    name,
    loss,
    cause,
    count,
    probability,
    select,
    eligible,
    order,
    requires,
    params,
    description) {
  supplied <- c(!is.null(count), !is.null(probability), !is.null(select))
  if (sum(supplied) != 1L) {
    .stop("supply exactly one of count, probability or select")
  }
  if (!is.null(count)) {
    count <- .count_function(count, "count")
  }
  if (!is.null(probability)) {
    probability <- .rate_function(probability, "probability")
  }
  .check_optional_function(select, "select")
  .check_optional_function(eligible, "eligible")
  if (!.is_name(cause)) {
    .stop("cause must be one non-empty character value")
  }
  pva_process(
    name = name,
    run = function(state, context, params) {
      pop <- state$population
      user <- params$user
      rows <- .eligible_rows(params$eligible, pop, state, context, user)
      shortfall <- 0
      if (!is.null(params$count)) {
        requested <- params$count(state, context, user)
        if (!.is_count(requested)) {
          .stop("count must evaluate to one non-negative whole number")
        }
        taken <- .pick_rows(rows, requested, params$order)
        shortfall <- requested - length(taken)
      } else if (!is.null(params$probability)) {
        chance <- .per_individual(
          params$probability(pop, state, context, user),
          length(pop$id), paste(params$loss, "probability"), 0, 1
        )
        taken <- rows[stats::runif(length(rows)) < chance[rows]]
      } else {
        taken <- params$select(pop, state, context, user)
        if (is.logical(taken)) {
          if (length(taken) != length(pop$id) || anyNA(taken)) {
            .stop("logical select must return one non-missing value per living individual")
          }
          taken <- which(taken)
        }
        if (anyNA(taken) || anyDuplicated(taken) || !all(taken %in% rows)) {
          .stop("select must return distinct eligible rows")
        }
      }
      if (length(taken)) {
        state$population$alive[taken] <- FALSE
      }
      events <- if (is.null(params$count)) {
        pva_events(params$loss, length(taken), params$cause)
      } else {
        pva_events(
          c(params$loss, paste0(params$loss, "_shortfall")),
          c(length(taken), shortfall),
          params$cause
        )
      }
      pva_result(state, events)
    },
    params = list(
      loss = loss,
      cause = cause,
      count = count,
      probability = probability,
      select = select,
      eligible = eligible,
      order = order,
      user = params
    ),
    requires = unique(c("population.alive", requires)),
    writes = "population.alive",
    description = description
  )
}

removal_process <- function(
    count = NULL,
    probability = NULL,
    select = NULL,
    eligible = NULL,
    order = c("random", "id"),
    cause = "removal",
    name = "removal",
    requires = character(),
    params = list()) {
  .loss_process(
    name = name,
    loss = "removal",
    cause = cause,
    count = count,
    probability = probability,
    select = select,
    eligible = eligible,
    order = match.arg(order),
    requires = requires,
    params = params,
    description = "Harvest, cull or capture living individuals as accounted removals."
  )
}

ceiling_process <- function(
    capacity,
    eligible = NULL,
    cause = "ceiling",
    name = "ceiling",
    requires = character(),
    params = list()) {
  capacity <- .count_function(capacity, "capacity")
  .check_optional_function(eligible, "eligible")
  excess <- function(state, context, params) {
    limit <- params$capacity(state, context, params$user)
    if (!is.numeric(limit) || length(limit) != 1L || is.na(limit) || limit < 0) {
      .stop("capacity must evaluate to one non-negative number")
    }
    rows <- .eligible_rows(
      params$eligible, state$population, state, context, params$user
    )
    max(0, length(rows) - floor(limit))
  }
  .loss_process(
    name = name,
    loss = "death",
    cause = cause,
    count = excess,
    probability = NULL,
    select = NULL,
    eligible = if (is.null(eligible)) {
      NULL
    } else {
      function(pop, state, context, params) {
        params$eligible(pop, state, context, params$user)
      }
    },
    order = "random",
    requires = requires,
    params = list(capacity = capacity, eligible = eligible, user = params),
    description = "Hard ceiling: random deaths bring eligible abundance down to capacity."
  )
}

introduction_process <- function(
    count,
    fields,
    creates = c("sex", "age"),
    source = "introduction",
    name = "introduction",
    requires = character(),
    params = list()) {
  count <- .count_function(count, "count")
  if (!is.function(fields)) {
    .stop("fields must be a function of (n, state, context, params)")
  }
  if (!.is_name(source)) {
    .stop("source must be one non-empty character value")
  }
  pva_process(
    name = name,
    run = function(state, context, params) {
      n <- params$count(state, context, params$user)
      if (!.is_count(n)) {
        .stop("introduction count must evaluate to one non-negative whole number")
      }
      if (n > 0) {
        new <- params$fields(as.integer(n), state, context, params$user)
        if (!is.list(new) || !all(c("sex", "age") %in% names(new)) ||
            !(length(new$sex) %in% c(1L, n))) {
          .stop("fields must return a named list with sex and age for n individuals")
        }
        new$sex <- rep_len(new$sex, n)
        state <- do.call(add_individuals, c(list(state), new))
      }
      pva_result(state, pva_events("introduction", n, params$source))
    },
    params = list(count = count, fields = fields, source = source, user = params),
    requires = requires,
    creates = unique(c("sex", "age", creates)),
    description = "Scheduled supplementation, release or immigration with engine-allocated ids."
  )
}

pairing_process <- function(
    eligible,
    capacity = Inf,
    priority = c("id", "lottery"),
    field = "mate_id",
    name = "pairing",
    requires = character(),
    params = list()) {
  if (!is.function(eligible)) {
    .stop("eligible must be a function of (pop, state, context, params)")
  }
  capacity <- .count_function(capacity, "capacity")
  priority <- match.arg(priority)
  if (!.is_name(field)) {
    .stop("field must be one non-empty name")
  }
  pva_process(
    name = name,
    run = function(state, context, params) {
      pop <- state$population
      rows <- .eligible_rows(params$eligible, pop, state, context, params$user)
      females <- rows[pop$sex[rows] == "F"]
      males <- rows[pop$sex[rows] == "M"]
      limit <- params$capacity(state, context, params$user)
      if (!is.numeric(limit) || length(limit) != 1L || is.na(limit) || limit < 0) {
        .stop("capacity must evaluate to one non-negative number")
      }
      n_pairs <- as.integer(min(floor(limit), length(females), length(males)))
      order <- if (params$priority == "id") "id" else "random"
      females <- .pick_rows(females, n_pairs, order)
      males <- .pick_rows(males, n_pairs, order)
      if (order == "random" && n_pairs > 1L) {
        males <- males[sample.int(n_pairs)]
      }
      mate <- rep(NA_integer_, length(pop$id))
      mate[females] <- pop$id[males]
      mate[males] <- pop$id[females]
      state$population[[params$field]] <- mate
      pva_result(
        state,
        pva_events(
          c("pairs_formed", "unpaired_eligible"),
          c(n_pairs, length(rows) - 2L * n_pairs)
        )
      )
    },
    params = list(
      eligible = eligible,
      capacity = capacity,
      priority = priority,
      field = field,
      user = params
    ),
    requires = unique(c(
      "population.sex", "population.alive", paste0("population.", field), requires
    )),
    writes = paste0("population.", field),
    description = "Form monogamous pairs up to a capacity; unpaired eligible individuals remain as floaters."
  )
}
