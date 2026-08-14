#' Construct an ageing process
#'
#' @param name Process name.
#'
#' @return A validated lifecycle process.
#' @export
age_process <- function(name = "age") {
  pva_process(
    name = name,
    run = function(state, context, params) {
      state$population <- lapply(state$population, function(ind) {
        if (isTRUE(ind$alive)) {
          ind$age <- as.integer(ind$age + 1L)
        }
        ind
      })
      pva_result(state)
    },
    requires = c("population.id", "population.age", "population.alive"),
    writes = "population.age",
    description = "Increment the age of living individuals."
  )
}

#' Construct an individual survival process
#'
#' @param probability Function called as
#'   `probability(individual, state, context, params)` that returns a survival
#'   probability in `[0, 1]`.
#' @param name Process name.
#' @param eligible Optional function with the same arguments that returns one
#'   logical value. It can partition dependent and independent survival into
#'   separate ordered processes.
#' @param requires Additional state paths required by `probability` or
#'   `eligible`.
#' @param params Explicit parameters passed to the functions.
#' @param cause Cause label attached to aggregate death events.
#'
#' @return A validated lifecycle process.
#' @details Every eligibility and probability callback in one execution sees
#'   the same pre-process state. Deaths are applied together after all decisions.
#' @export
survival_process <- function(
    probability,
    name = "survival",
    eligible = NULL,
    requires = character(),
    params = list(),
    cause = "natural") {
  if (!is.function(probability)) {
    stop("probability must be a function", call. = FALSE)
  }
  if (!is.null(eligible) && !is.function(eligible)) {
    stop("eligible must be NULL or a function", call. = FALSE)
  }
  if (!is.character(cause) || length(cause) != 1L || is.na(cause) || !nzchar(cause)) {
    stop("cause must be a non-empty character scalar", call. = FALSE)
  }

  pva_process(
    name = name,
    run = function(state, context, process_params) {
      pre_state <- state
      deaths <- logical(length(pre_state$population))
      n_deaths <- 0L
      for (index in seq_along(pre_state$population)) {
        ind <- pre_state$population[[index]]
        if (!isTRUE(ind$alive)) {
          next
        }
        is_eligible <- if (is.null(process_params$eligible)) {
          TRUE
        } else {
          process_params$eligible(ind, pre_state, context, process_params$model)
        }
        if (!is.logical(is_eligible) || length(is_eligible) != 1L || is.na(is_eligible)) {
          stop("eligible must return one non-missing logical value", call. = FALSE)
        }
        if (!is_eligible) {
          next
        }
        probability_value <- process_params$probability(
          ind,
          pre_state,
          context,
          process_params$model
        )
        if (!is.numeric(probability_value) || length(probability_value) != 1L ||
            !is.finite(probability_value) || probability_value < 0 ||
            probability_value > 1) {
          stop("probability must return one finite value in [0, 1]", call. = FALSE)
        }
        if (stats::runif(1L) >= probability_value) {
          deaths[[index]] <- TRUE
          n_deaths <- n_deaths + 1L
        }
      }
      for (index in which(deaths)) {
        state$population[[index]]$alive <- FALSE
      }
      events <- if (n_deaths) {
        list(list(event_type = "death", value = n_deaths, cause = process_params$cause))
      } else {
        list()
      }
      pva_result(state, events)
    },
    params = list(
      probability = probability,
      eligible = eligible,
      model = params,
      cause = cause
    ),
    requires = unique(c("population.id", "population.alive", requires)),
    writes = "population.alive",
    description = "Apply Bernoulli survival to eligible living individuals."
  )
}

#' Construct a reproduction process
#'
#' The constructor deliberately has no grizzly parameter defaults. Biological
#' functions and newborn-field rules belong to the model fixture.
#'
#' @param breeding_probability Function called as
#'   `breeding_probability(mother, state, context, params)`.
#' @param fecundity_mean Function with the same signature returning the mean of
#'   a Poisson litter-size draw.
#' @param name Process name.
#' @param mating Optional function called as
#'   `mating(population, mother, context, params)` and returning a father record
#'   or `NULL`.
#' @param require_mate Whether a missing father prevents reproduction.
#' @param offspring_sex Function called as
#'   `offspring_sex(mother, father, state, context, params)` and returning
#'   `"F"` or `"M"`. This modeller-owned callback is required; OpenPVA supplies
#'   no offspring-sex distribution.
#' @param newborn_initializer Function called with the same arguments as
#'   `offspring_sex` and returning a named list of additional newborn fields.
#' @param initializer_fields Character vector naming fields promised by
#'   `newborn_initializer`.
#' @param inherit_fields Character vector of fields copied from each mother.
#' @param requires Additional state paths used by the model functions.
#' @param params Explicit model parameters.
#'
#' @return A validated lifecycle process.
#' @details All callbacks in one execution see the same pre-process state and
#'   population. Newborns are staged in ledger order and appended together.
#' @export
reproduction_process <- function(
    breeding_probability,
    fecundity_mean,
    offspring_sex,
    name = "reproduction",
    mating = NULL,
    require_mate = FALSE,
    newborn_initializer = NULL,
    initializer_fields = character(),
    inherit_fields = character(),
    requires = character(),
    params = list()) {
  for (argument in c("breeding_probability", "fecundity_mean")) {
    if (!is.function(get(argument))) {
      stop(argument, " must be a function", call. = FALSE)
    }
  }
  if (!is.null(mating) && !is.function(mating)) {
    stop("mating must be NULL or a function", call. = FALSE)
  }
  if (!is.logical(require_mate) || length(require_mate) != 1L || is.na(require_mate)) {
    stop("require_mate must be one non-missing logical value", call. = FALSE)
  }
  if (!is.function(offspring_sex)) {
    stop("offspring_sex must be a function", call. = FALSE)
  }
  if (is.null(newborn_initializer)) {
    newborn_initializer <- function(mother, father, state, context, params) list()
  }
  if (!is.function(newborn_initializer)) {
    stop("newborn_initializer must be a function", call. = FALSE)
  }
  for (argument in c("initializer_fields", "inherit_fields")) {
    value <- get(argument)
    if (!is.character(value) || anyNA(value) || any(!nzchar(value))) {
      stop(argument, " must be a character vector of field names", call. = FALSE)
    }
  }

  base_fields <- c("id", "sex", "age", "alive", "mother_id", "father_id")
  reserved_newborn_fields <- intersect(c(initializer_fields, inherit_fields), base_fields)
  if (length(reserved_newborn_fields)) {
    stop(
      "initializer_fields and inherit_fields cannot override engine birth fields: ",
      paste(unique(reserved_newborn_fields), collapse = ", "),
      call. = FALSE
    )
  }
  created_fields <- unique(c(base_fields, initializer_fields, inherit_fields))

  pva_process(
    name = name,
    run = function(state, context, process_params) {
      pre_state <- state
      newborns <- list()
      initial_population <- pre_state$population
      mothers <- Filter(
        function(ind) isTRUE(ind$alive) && identical(ind$sex, "F"),
        initial_population
      )
      for (mother in mothers) {
        breeding_p <- process_params$breeding_probability(
          mother,
          pre_state,
          context,
          process_params$model
        )
        if (!is.numeric(breeding_p) || length(breeding_p) != 1L ||
            !is.finite(breeding_p) || breeding_p < 0 || breeding_p > 1) {
          stop("breeding_probability must return one finite value in [0, 1]", call. = FALSE)
        }
        if (stats::runif(1L) >= breeding_p) {
          next
        }
        father <- if (is.null(process_params$mating)) {
          NULL
        } else {
          process_params$mating(
            initial_population,
            mother,
            context,
            process_params$model
          )
        }
        if (process_params$require_mate && is.null(father)) {
          next
        }
        lambda <- process_params$fecundity_mean(
          mother,
          pre_state,
          context,
          process_params$model
        )
        if (!is.numeric(lambda) || length(lambda) != 1L || !is.finite(lambda) || lambda < 0) {
          stop("fecundity_mean must return one finite non-negative value", call. = FALSE)
        }
        litter_size <- stats::rpois(1L, lambda)
        if (!litter_size) {
          next
        }
        for (offspring_index in seq_len(litter_size)) {
          allocation <- .allocate_ids_trusted(state, 1L)
          state <- allocation$state
          sex <- process_params$offspring_sex(
            mother,
            father,
            pre_state,
            context,
            process_params$model
          )
          if (!is.character(sex) || length(sex) != 1L || is.na(sex) ||
              !sex %in% c("F", "M")) {
            stop("offspring_sex must return 'F' or 'M'", call. = FALSE)
          }
          newborn <- list(
            id = allocation$ids[[1L]],
            sex = sex,
            age = 0L,
            alive = TRUE,
            mother_id = mother$id,
            father_id = if (is.null(father)) NA_integer_ else father$id
          )
          for (field in process_params$inherit_fields) {
            if (!field %in% names(mother)) {
              stop("mother is missing inherited newborn field '", field, "'", call. = FALSE)
            }
            newborn[[field]] <- mother[[field]]
          }
          extras <- process_params$newborn_initializer(
            mother,
            father,
            pre_state,
            context,
            process_params$model
          )
          if (!is.list(extras) || (length(extras) &&
              (is.null(names(extras)) || any(!nzchar(names(extras)))))) {
            stop("newborn_initializer must return a named list", call. = FALSE)
          }
          unexpected <- setdiff(names(extras), process_params$initializer_fields)
          missing <- setdiff(process_params$initializer_fields, names(extras))
          if (length(unexpected) || length(missing)) {
            stop(
              "newborn_initializer fields must exactly match initializer_fields",
              call. = FALSE
            )
          }
          newborn[names(extras)] <- extras
          newborns[[length(newborns) + 1L]] <- newborn
        }
      }
      if (length(newborns)) {
        state$population <- c(state$population, newborns)
      }
      events <- if (length(newborns)) {
        list(list(event_type = "birth", value = as.integer(length(newborns))))
      } else {
        list()
      }
      pva_result(state, events)
    },
    params = list(
      breeding_probability = breeding_probability,
      fecundity_mean = fecundity_mean,
      mating = mating,
      require_mate = require_mate,
      offspring_sex = offspring_sex,
      newborn_initializer = newborn_initializer,
      initializer_fields = initializer_fields,
      inherit_fields = inherit_fields,
      model = params
    ),
    requires = unique(c(
      "population.id",
      "population.sex",
      "population.alive",
      "next_id",
      if (length(inherit_fields)) paste0("population.", inherit_fields) else character(),
      requires
    )),
    writes = unique(c("population", "next_id", paste0("population.", created_fields))),
    creates = paste0("population.", created_fields),
    description = "Draw breeding and Poisson litter events and initialise newborn state."
  )
}

#' Construct a census observer process
#'
#' @param summarise Function called as `summarise(state, context, params)` and
#'   returning a named list of scalar metrics including `n_alive`.
#' @param name Process name.
#' @param requires Additional state paths used by `summarise`.
#' @param params Explicit model parameters.
#'
#' @return A non-mutating lifecycle process.
#' @export
census_process <- function(
    summarise = NULL,
    name = "census",
    requires = c("population.id", "population.sex", "population.alive"),
    params = list()) {
  if (is.null(summarise)) {
    summarise <- function(state, context, params) {
      alive <- vapply(state$population, function(ind) isTRUE(ind$alive), logical(1))
      sexes <- vapply(state$population, function(ind) ind$sex, character(1))
      list(
        n_alive = as.integer(sum(alive)),
        n_female_alive = as.integer(sum(alive & sexes == "F")),
        n_male_alive = as.integer(sum(alive & sexes == "M"))
      )
    }
  }
  if (!is.function(summarise)) {
    stop("summarise must be a function", call. = FALSE)
  }

  pva_process(
    name = name,
    run = function(state, context, process_params) {
      metrics <- process_params$summarise(state, context, process_params$model)
      if (!is.list(metrics) || !length(metrics) || is.null(names(metrics)) ||
          any(!nzchar(names(metrics)))) {
        stop("census summarise must return a non-empty named list", call. = FALSE)
      }
      valid <- vapply(metrics, function(value) {
        (is.numeric(value) || is.logical(value) || is.character(value)) &&
          length(value) == 1L && !is.na(value)
      }, logical(1))
      if (!all(valid) || !"n_alive" %in% names(metrics)) {
        stop("census metrics must be non-missing scalars including n_alive", call. = FALSE)
      }
      if (length(intersect(names(metrics), c("event_type", "value")))) {
        stop("census metric names cannot use event_type or value", call. = FALSE)
      }
      event <- c(list(event_type = "census", value = as.integer(metrics$n_alive)), metrics)
      pva_result(state, list(event))
    },
    params = list(summarise = summarise, model = params),
    requires = unique(requires),
    writes = character(),
    description = "Observe state without changing it."
  )
}
