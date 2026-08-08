#' Construct OpenPVA simulation state
#'
#' @param population List of named individual records.
#' @param globals Named list of deliberately shared dynamic values.
#' @param next_id Next unused positive integer identifier. When `NULL`, it is
#'   derived from `population`.
#'
#' @return A validated simulation-state list.
#' @details Population records form an append-only ledger. Existing records
#'   retain their position and identifier; mortality changes `alive`, and new
#'   records append with consecutive engine-allocated identifiers.
#' @export
pva_state <- function(population, globals = list(), next_id = NULL) {
  if (!is.list(population)) {
    stop("population must be a list", call. = FALSE)
  }
  population <- .normalize_population_integer_fields(population)
  if (is.null(next_id)) {
    ids <- if (length(population)) {
      vapply(population, function(ind) {
        if (!is.list(ind) || !"id" %in% names(ind) || is.null(ind$id)) {
          stop("every individual must contain an id", call. = FALSE)
        }
        ind$id
      }, integer(1))
    } else {
      integer()
    }
    if (length(ids) && max(ids) >= .Machine$integer.max) {
      stop("population ids have exhausted R's integer range", call. = FALSE)
    }
    next_id <- if (length(ids)) max(ids) + 1L else 1L
  } else {
    next_id <- .normalize_integer_scalar(next_id, "next_id", minimum = 1L)
  }
  state <- list(
    population = population,
    globals = globals,
    next_id = next_id
  )
  .validate_state(state)
}

#' Allocate stable individual identifiers
#'
#' Process functions use this helper when creating births or introductions.
#' The returned state carries the advanced engine-owned allocator.
#'
#' @param state OpenPVA simulation state.
#' @param n Number of identifiers to allocate.
#'
#' @return A list with updated `state` and integer vector `ids`.
#' @export
allocate_ids <- function(state, n) {
  state <- .validate_state(state)
  n <- .normalize_non_negative_count(n, "n")
  if (n == 0L) {
    return(list(state = state, ids = integer()))
  }
  last_id <- as.double(state$next_id) + n - 1
  if (last_id >= .Machine$integer.max) {
    stop("identifier allocation exceeds R's integer range", call. = FALSE)
  }
  ids <- seq.int(from = state$next_id, length.out = n)
  state$next_id <- as.integer(last_id + 1)
  list(state = state, ids = as.integer(ids))
}

#' Construct an OpenPVA lifecycle process
#'
#' A process is a small metadata list around an ordinary R function. The
#' function is called as `run(state, context, params)` and must return a
#' [pva_result()].
#'
#' @param name Stable non-empty process name.
#' @param run Function with arguments `state`, `context`, and `params`.
#' @param params Explicit parameter list.
#' @param requires Character vector of required state paths such as
#'   `population.age` or `globals.environment`.
#' @param writes Character vector of state paths the process may write.
#' @param creates Optional character vector of `population.*` fields that the
#'   process promises to initialise on every newly created individual. `NULL`
#'   declares that the process never creates individuals.
#' @param validate_params Optional function that validates `params` and returns
#'   invisibly or stops with a useful error.
#' @param description Optional short description.
#'
#' @return A validated `pva_process` object.
#' @export
pva_process <- function(
    name,
    run,
    params = list(),
    requires = character(),
    writes = character(),
    creates = NULL,
    validate_params = NULL,
    description = NULL) {
  process <- structure(
    list(
      name = name,
      run = run,
      params = params,
      requires = requires,
      writes = writes,
      creates = creates,
      validate_params = validate_params,
      description = description
    ),
    class = c("pva_process", "list")
  )
  .validate_process(process)
}

#' Construct a process result
#'
#' @param state Replacement simulation state.
#' @param events Zero or more named event records. Each record must contain an
#'   `event_type`; accounting events also carry `value` or an `individual_id`.
#'
#' @return A `pva_result` object.
#' @export
pva_result <- function(state, events = list()) {
  structure(
    list(state = state, events = events),
    class = c("pva_result", "list")
  )
}

#' Validate an ordered process list
#'
#' @param processes Non-empty list of process objects.
#' @param state Optional initial state for field-dependency preflight.
#'
#' @return The validated process list, invisibly.
#' @export
validate_processes <- function(processes, state = NULL) {
  if (!is.list(processes) || !length(processes)) {
    stop("processes must be a non-empty list", call. = FALSE)
  }
  processes <- lapply(processes, .validate_process)
  if (!is.null(state)) {
    state <- .validate_state(state)
    .validate_process_field_plan(processes, state)
  }
  invisible(processes)
}

#' Execute one ordered lifecycle interval
#'
#' This is the single generic execution seam. It contains no biological
#' process names or categories.
#'
#' @param state OpenPVA simulation state.
#' @param processes Ordered list of [pva_process()] objects.
#' @param run Positive integer replicate identifier.
#' @param time Non-negative integer interval label.
#' @param dt Positive numeric interval duration.
#' @param stream_provenance Optional replicate-stream record placed in context.
#' @param execution_id Optional provenance identifier.
#' @param phase Execution phase, either `"interval"` or `"initial"`.
#'
#' @return A list with replacement `state`, structured `events`, and the
#'   `process_plan`.
#' @export
execute_processes <- function(
    state,
    processes,
    run = 1L,
    time = 0L,
    dt = 1,
    stream_provenance = NULL,
    execution_id = NULL,
    phase = c("interval", "initial")) {
  state <- .validate_state(state)
  processes <- validate_processes(processes, state)
  run <- .normalize_positive_count(run, "run")
  time <- .normalize_non_negative_count(time, "time")
  dt <- as.numeric(dt)
  if (length(dt) != 1L || !is.finite(dt) || dt <= 0) {
    stop("dt must be a single positive numeric value", call. = FALSE)
  }
  phase <- match.arg(phase)

  plan <- .build_process_plan(processes)
  all_events <- list()
  all_required_fields <- .required_population_fields(processes)

  for (index in seq_along(processes)) {
    process <- processes[[index]]
    .validate_process_requirements(state, process)
    before <- state
    context <- list(
      run = run,
      time = time,
      dt = dt,
      process_index = as.integer(index),
      process_name = process$name,
      process_occurrence = plan$occurrence[[index]],
      phase = phase,
      stream_provenance = stream_provenance,
      execution_id = execution_id
    )

    result <- tryCatch(
      process$run(state, context, process$params),
      error = function(error) {
        stop(
          sprintf(
            "process '%s' failed at run %d, time %d, position %d: %s",
            process$name,
            run,
            time,
            index,
            conditionMessage(error)
          ),
          call. = FALSE
        )
      }
    )
    result <- .validate_process_result(result, process)
    .validate_declared_writes(before, result$state, process)
    event_records <- .normalize_event_records(result$events, process$name)
    .validate_accounting_transition(before, result$state, event_records, process$name)
    .validate_new_individuals(
      before,
      result$state,
      all_required_fields,
      processes,
      process
    )
    state <- result$state
    if (length(event_records)) {
      all_events <- c(
        all_events,
        lapply(event_records, function(event) {
          c(
            list(
              run = run,
              time = time,
              process_index = as.integer(index),
              process_name = process$name,
              process_occurrence = plan$occurrence[[index]],
              phase = phase
            ),
            event
          )
        })
      )
    }
  }

  list(
    state = state,
    events = .bind_event_records(all_events),
    process_plan = plan
  )
}

#' @export
print.pva_process <- function(x, ...) {
  cat(sprintf("<OpenPVA process '%s' | requires: %d | writes: %d>\n",
              x$name, length(x$requires), length(x$writes)))
  invisible(x)
}

.validate_process <- function(process) {
  if (!is.list(process)) {
    stop("each process must be a named list", call. = FALSE)
  }
  required_names <- c("name", "run", "params", "requires", "writes")
  missing_names <- setdiff(required_names, names(process))
  if (length(missing_names)) {
    stop(
      "process is missing required member(s): ",
      paste(missing_names, collapse = ", "),
      call. = FALSE
    )
  }
  if (!is.character(process$name) || length(process$name) != 1L ||
      is.na(process$name) || !nzchar(trimws(process$name))) {
    stop("process name must be a non-empty character scalar", call. = FALSE)
  }
  if (!is.function(process$run)) {
    stop("process 'run' must be a function", call. = FALSE)
  }
  if (!is.list(process$params)) {
    stop("process 'params' must be a list", call. = FALSE)
  }
  for (member in c("requires", "writes")) {
    value <- process[[member]]
    if (!is.character(value) || anyNA(value) || any(!nzchar(value))) {
      stop("process '", member, "' must be a character vector of state paths", call. = FALSE)
    }
    if (any(grepl("^context\\.", value))) {
      stop("processes cannot require or write engine-owned context fields", call. = FALSE)
    }
    valid_path <- value %in% c("population", "globals", "next_id") |
      grepl("^(population|globals)\\.[^.]+$", value)
    if (any(!valid_path)) {
      stop("process '", member, "' contains an invalid state path", call. = FALSE)
    }
    process[[member]] <- unique(value)
  }
  creates <- process$creates %||% NULL
  if ("population" %in% process$writes && is.null(creates)) {
    stop(
      "structural population writes are reserved for declared creation processes",
      call. = FALSE
    )
  }
  if (!is.null(creates)) {
    if (!is.character(creates) || anyNA(creates) || any(!nzchar(creates)) ||
        any(!grepl("^population\\.", creates))) {
      stop("process 'creates' must be NULL or population.* field paths", call. = FALSE)
    }
    process$creates <- unique(creates)
    if (!"population" %in% process$writes || !"next_id" %in% process$writes) {
      stop("creation processes must declare writes to population and next_id", call. = FALSE)
    }
  }
  validator <- process$validate_params %||% NULL
  if (!is.null(validator)) {
    if (!is.function(validator)) {
      stop("validate_params must be NULL or a function", call. = FALSE)
    }
    validator(process$params)
  }
  if (!inherits(process, "pva_process")) {
    class(process) <- c("pva_process", "list")
  }
  process
}

.validate_state <- function(state) {
  if (!is.list(state) || !all(c("population", "globals", "next_id") %in% names(state))) {
    stop("state must contain population, globals, and next_id", call. = FALSE)
  }
  if (!is.list(state$population)) {
    stop("state$population must be a list", call. = FALSE)
  }
  if (!is.list(state$globals) || (length(state$globals) &&
      (is.null(names(state$globals)) || any(!nzchar(names(state$globals)))))) {
    stop("state$globals must be a named list", call. = FALSE)
  }
  if (!is.integer(state$next_id) || length(state$next_id) != 1L ||
      is.na(state$next_id) || state$next_id <= 0L) {
    stop("state$next_id must be a single positive integer", call. = FALSE)
  }

  if (length(state$population)) {
    valid_records <- vapply(
      state$population,
      function(ind) is.list(ind) && !is.null(names(ind)) && all(nzchar(names(ind))),
      logical(1)
    )
    if (!all(valid_records)) {
      stop("every individual must be a named list", call. = FALSE)
    }
    .validate_population_field(state$population, "id", allow_missing = FALSE)
    ids <- vapply(state$population, function(ind) ind$id, integer(1))
    if (anyDuplicated(ids)) {
      stop("population id values must be unique", call. = FALSE)
    }
    max_id <- max(ids)
    if (max_id >= .Machine$integer.max) {
      stop("population ids have exhausted R's integer range", call. = FALSE)
    }
    if (state$next_id != max_id + 1L) {
      stop("state$next_id must equal max(population id) + 1", call. = FALSE)
    }
    for (field in intersect(names(.core_field_specs()), unique(unlist(lapply(state$population, names))))) {
      .validate_population_field(state$population, field, allow_missing = TRUE)
    }
  } else if (state$next_id != 1L) {
    stop("state$next_id must be 1 for an empty population", call. = FALSE)
  }
  state
}

.core_field_specs <- function() {
  list(
    id = list(type = "integer", allow_na = FALSE, predicate = function(x) x > 0L),
    age = list(type = "integer", allow_na = FALSE, predicate = function(x) x >= 0L),
    alive = list(type = "logical", allow_na = FALSE, predicate = NULL),
    sex = list(type = "character", allow_na = FALSE, predicate = function(x) x %in% c("F", "M")),
    mother_id = list(type = "integer", allow_na = TRUE, predicate = function(x) x > 0L),
    father_id = list(type = "integer", allow_na = TRUE, predicate = function(x) x > 0L),
    patch_id = list(type = "integer", allow_na = TRUE, predicate = function(x) x > 0L),
    F = list(type = "numeric", allow_na = TRUE, predicate = function(x) x >= 0 && x <= 1),
    dependency = list(type = "character", allow_na = FALSE, predicate = NULL),
    reproductive_status = list(type = "character", allow_na = FALSE, predicate = NULL)
  )
}

.validate_population_field <- function(population, field, allow_missing = FALSE) {
  spec <- .core_field_specs()[[field]] %||% NULL
  for (index in seq_along(population)) {
    ind <- population[[index]]
    missing <- !field %in% names(ind) || is.null(ind[[field]])
    if (missing) {
      if (allow_missing) {
        next
      }
      stop(
        sprintf("individual %d is missing required field population.%s", index, field),
        call. = FALSE
      )
    }
    value <- ind[[field]]
    if (!is.null(spec)) {
      if (length(value) != 1L) {
        stop("population.", field, " must be a scalar field", call. = FALSE)
      }
      type_ok <- switch(
        spec$type,
        integer = is.integer(value),
        numeric = is.numeric(value),
        logical = is.logical(value),
        character = is.character(value),
        FALSE
      )
      if (!type_ok) {
        stop(
          sprintf("population.%s must have type %s", field, spec$type),
          call. = FALSE
        )
      }
      if (is.na(value)) {
        if (!isTRUE(spec$allow_na)) {
          stop("population.", field, " cannot be missing", call. = FALSE)
        }
        next
      }
      if (!is.null(spec$predicate) && !isTRUE(spec$predicate(value))) {
        stop("population.", field, " contains an invalid value", call. = FALSE)
      }
    }
  }
  invisible(population)
}

.validate_process_field_plan <- function(processes, state) {
  available <- .available_state_paths(state)
  required_creation_fields <- paste0("population.", .required_population_fields(processes))
  for (process in processes) {
    if (!is.null(process$creates)) {
      missing_created <- setdiff(required_creation_fields, process$creates)
      if (length(missing_created)) {
        consumers <- vapply(missing_created, function(path) {
          index <- which(vapply(processes, function(candidate) {
            path %in% candidate$requires
          }, logical(1)))[[1L]]
          processes[[index]]$name
        }, character(1))
        details <- paste0(missing_created, " (required by ", consumers, ")")
        stop(
          "creation process '", process$name,
          "' does not declare initialisation of: ",
          paste(details, collapse = ", "),
          call. = FALSE
        )
      }
    }
  }
  for (process in processes) {
    missing <- setdiff(process$requires, available)
    if (!length(state$population)) {
      missing <- missing[!grepl("^population\\.", missing)]
    }
    if (length(missing)) {
      stop(
        "process '", process$name, "' requires unavailable field(s): ",
        paste(missing, collapse = ", "),
        call. = FALSE
      )
    }
    available <- union(available, process$writes)
  }
  invisible(processes)
}

.available_state_paths <- function(state) {
  paths <- c("population", "globals", "next_id")
  if (length(state$population)) {
    common_fields <- Reduce(intersect, lapply(state$population, names))
    paths <- c(paths, paste0("population.", common_fields))
  }
  if (length(state$globals)) {
    paths <- c(paths, paste0("globals.", names(state$globals)))
  }
  unique(paths)
}

.validate_process_requirements <- function(state, process) {
  available <- .available_state_paths(state)
  missing <- setdiff(process$requires, available)
  if (!length(state$population)) {
    missing <- missing[!grepl("^population\\.", missing)]
  }
  if (length(missing)) {
    stop(
      "process '", process$name, "' requires missing field(s): ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  population_fields <- sub("^population\\.", "", process$requires[grepl("^population\\.", process$requires)])
  for (field in population_fields) {
    .validate_population_field(state$population, field, allow_missing = FALSE)
    if (field == "patch_id" && length(state$population) &&
        any(vapply(state$population, function(ind) is.na(ind[[field]]), logical(1)))) {
      stop(
        "process '", process$name,
        "' requires non-missing population.patch_id values",
        call. = FALSE
      )
    }
  }
  invisible(state)
}

.validate_process_result <- function(result, process) {
  if (!is.list(result) || !all(c("state", "events") %in% names(result))) {
    stop(
      "process '", process$name, "' must return pva_result(state, events)",
      call. = FALSE
    )
  }
  result$state <- .validate_state(result$state)
  result
}

.validate_declared_writes <- function(before, after, process) {
  .validate_persistent_population(before, after, process)

  if (!identical(before$next_id, after$next_id) && !"next_id" %in% process$writes) {
    stop("process '", process$name, "' changed undeclared field next_id", call. = FALSE)
  }

  if (!identical(before$globals, after$globals) && !"globals" %in% process$writes) {
    global_names <- union(names(before$globals), names(after$globals))
    changed <- global_names[vapply(global_names, function(name) {
      !identical(before$globals[[name]], after$globals[[name]])
    }, logical(1))]
    undeclared <- setdiff(paste0("globals.", changed), process$writes)
    if (length(undeclared)) {
      stop(
        "process '", process$name, "' changed undeclared field(s): ",
        paste(undeclared, collapse = ", "),
        call. = FALSE
      )
    }
  }

  existing_after <- if (length(before$population)) {
    after$population[seq_along(before$population)]
  } else {
    list()
  }
  if (!identical(before$population, existing_after)) {
    field_names <- union(
      unique(unlist(lapply(before$population, names))),
      unique(unlist(lapply(existing_after, names)))
    )
    changed <- field_names[vapply(field_names, function(field) {
      before_values <- lapply(before$population, function(ind) ind[[field]])
      after_values <- lapply(existing_after, function(ind) ind[[field]])
      !identical(before_values, after_values)
    }, logical(1))]
    undeclared <- setdiff(paste0("population.", changed), process$writes)
    if (length(undeclared)) {
      stop(
        "process '", process$name, "' changed undeclared field(s): ",
        paste(undeclared, collapse = ", "),
        call. = FALSE
      )
    }
  }
  invisible(after)
}

.validate_persistent_population <- function(before, after, process) {
  before_ids <- .population_ids(before$population)
  after_ids <- .population_ids(after$population)
  n_existing <- length(before_ids)

  if (length(after_ids) < n_existing) {
    stop(
      "process '", process$name,
      "' physically removed population records; set population.alive instead",
      call. = FALSE
    )
  }
  if (n_existing && !identical(after_ids[seq_len(n_existing)], before_ids)) {
    stop(
      "process '", process$name,
      "' reordered records or changed an existing population id",
      call. = FALSE
    )
  }

  n_new <- length(after_ids) - n_existing
  if (n_new) {
    expected <- seq.int(from = before$next_id, length.out = n_new)
    appended <- after_ids[n_existing + seq_len(n_new)]
    if (!identical(appended, as.integer(expected))) {
      stop(
        "process '", process$name,
        "' must append new records in consecutive engine-id order",
        call. = FALSE
      )
    }
  }
  invisible(after)
}

.normalize_event_records <- function(events, process_name) {
  if (is.null(events) || !length(events)) {
    return(list())
  }
  if (is.data.frame(events)) {
    events <- lapply(seq_len(nrow(events)), function(index) as.list(events[index, , drop = FALSE]))
  } else if (is.list(events) && "event_type" %in% names(events)) {
    events <- list(events)
  }
  if (!is.list(events) || !all(vapply(events, is.list, logical(1)))) {
    stop("events from process '", process_name, "' must be named records", call. = FALSE)
  }
  reserved <- c(
    "run", "time", "process_index", "process_name", "process_occurrence", "phase"
  )
  for (event in events) {
    if (is.null(names(event)) || any(!nzchar(names(event)))) {
      stop("event records must be named lists", call. = FALSE)
    }
    if (anyDuplicated(names(event))) {
      stop("event records cannot contain duplicate field names", call. = FALSE)
    }
    overlap <- intersect(reserved, names(event))
    if (length(overlap)) {
      stop(
        "process events cannot write engine-owned column(s): ",
        paste(overlap, collapse = ", "),
        call. = FALSE
      )
    }
    if (!is.character(event$event_type) || length(event$event_type) != 1L ||
        is.na(event$event_type) || !nzchar(event$event_type)) {
      stop("every event must contain a non-empty event_type", call. = FALSE)
    }
    scalar <- vapply(event, function(value) {
      is.atomic(value) && length(value) == 1L && !is.na(value)
    }, logical(1))
    if (!all(scalar)) {
      stop("event fields must be non-missing atomic scalars", call. = FALSE)
    }
    if (!is.null(event$value) &&
        (!is.numeric(event$value) || !is.finite(event$value) ||
         event$value < 0 || event$value != floor(event$value))) {
      stop("event value must be a finite non-negative integer", call. = FALSE)
    }
  }
  events
}

.validate_accounting_transition <- function(before, after, events, process_name) {
  before_alive <- .alive_ids(before$population)
  after_alive <- .alive_ids(after$population)
  before_ids <- .population_ids(before$population)
  after_ids <- .population_ids(after$population)
  new_count <- length(setdiff(after_ids, before_ids))
  lost_count <- length(setdiff(before_alive, after_alive))
  revived_count <- length(intersect(setdiff(after_alive, before_alive), before_ids))

  if (new_count) {
    expected_ids <- seq.int(before$next_id, length.out = new_count)
    actual_ids <- sort(setdiff(after_ids, before_ids))
    if (!identical(as.integer(actual_ids), as.integer(expected_ids))) {
      stop(
        "process '", process_name,
        "' must allocate new ids consecutively from state$next_id",
        call. = FALSE
      )
    }
  }
  expected_next_id <- as.integer(before$next_id + new_count)
  if (!identical(after$next_id, expected_next_id)) {
    stop(
      "process '", process_name,
      "' changed state$next_id inconsistently with created individuals",
      call. = FALSE
    )
  }

  added_events <- .sum_event_values(events, c("birth", "introduction"))
  lost_events <- .sum_event_values(events, c("death", "removal"))
  if (new_count != added_events) {
    stop(
      sprintf(
        "process '%s' added %d individual(s) but reported %d birth/introduction event(s)",
        process_name, new_count, added_events
      ),
      call. = FALSE
    )
  }
  if (lost_count != lost_events) {
    stop(
      sprintf(
        "process '%s' lost %d living individual(s) but reported %d death/removal event(s)",
        process_name, lost_count, lost_events
      ),
      call. = FALSE
    )
  }
  if (revived_count > 0L) {
    stop("process '", process_name, "' cannot silently revive dead individuals", call. = FALSE)
  }
  invisible(after)
}

.sum_event_values <- function(events, event_types) {
  matching <- Filter(function(event) event$event_type %in% event_types, events)
  if (!length(matching)) {
    return(0L)
  }
  values <- vapply(matching, function(event) {
    if (!is.null(event$value)) {
      value <- event$value
      if (!is.numeric(value) || length(value) != 1L || !is.finite(value) ||
          value < 0 || value != floor(value)) {
        stop("accounting event value must be a finite non-negative integer", call. = FALSE)
      }
      return(as.integer(value))
    }
    if (!is.null(event$individual_id)) {
      return(1L)
    }
    stop("accounting events require value or individual_id", call. = FALSE)
  }, integer(1))
  sum(values)
}

.required_population_fields <- function(processes) {
  fields <- sub(
    "^population\\.",
    "",
    unlist(lapply(processes, function(process) {
      process$requires[grepl("^population\\.", process$requires)]
    }))
  )
  unique(fields[nzchar(fields)])
}

.validate_new_individuals <- function(before, after, fields, processes, creator) {
  new_ids <- setdiff(.population_ids(after$population), .population_ids(before$population))
  if (!length(new_ids)) {
    return(invisible(after))
  }
  if (is.null(creator$creates)) {
    stop(
      "process '", creator$name,
      "' created individuals without a creates declaration",
      call. = FALSE
    )
  }
  new_population <- Filter(function(ind) ind$id %in% new_ids, after$population)
  declared_fields <- sub("^population\\.", "", creator$creates)
  fields_to_check <- union(fields, declared_fields)
  for (field in fields_to_check) {
    requiring <- vapply(processes, function(process) {
      paste0("population.", field) %in% process$requires
    }, logical(1))
    consumer <- if (any(requiring)) {
      processes[[which(requiring)[[1L]]]]$name
    } else {
      "the creation declaration"
    }
    missing <- vapply(new_population, function(ind) {
      !field %in% names(ind) || is.null(ind[[field]]) ||
        (!is.null(.core_field_specs()[[field]]) && length(ind[[field]]) != 1L) ||
        (field == "patch_id" && is.na(ind[[field]])) ||
        (field %in% declared_fields && !field %in% c("mother_id", "father_id") &&
         is.atomic(ind[[field]]) && length(ind[[field]]) == 1L && is.na(ind[[field]]))
    }, logical(1))
    if (any(missing)) {
      bad_id <- new_population[[which(missing)[[1L]]]]$id
      stop(
        sprintf(
          "new individual %d from process '%s' does not initialise required field population.%s for process '%s'",
          bad_id, creator$name, field, consumer
        ),
        call. = FALSE
      )
    }
    .validate_population_field(new_population, field, allow_missing = FALSE)
  }
  invisible(after)
}

.build_process_plan <- function(processes) {
  counts <- integer()
  occurrences <- integer(length(processes))
  for (index in seq_along(processes)) {
    name <- processes[[index]]$name
    count <- unname(counts[name])
    if (!length(count) || is.na(count)) {
      count <- 0L
    }
    count <- count + 1L
    counts[name] <- count
    occurrences[[index]] <- count
  }
  tibble::tibble(
    process_index = seq_along(processes),
    process_name = vapply(processes, `[[`, character(1), "name"),
    occurrence = occurrences,
    requires = lapply(processes, `[[`, "requires"),
    writes = lapply(processes, `[[`, "writes"),
    creates = lapply(processes, function(process) process$creates %||% character())
  )
}

.bind_event_records <- function(events) {
  if (!length(events)) {
    return(tibble::tibble(
      run = integer(),
      time = integer(),
      process_index = integer(),
      process_name = character(),
      process_occurrence = integer(),
      phase = character(),
      event_type = character()
    ))
  }
  dplyr::bind_rows(events)
}

.population_ids <- function(population) {
  if (!length(population)) integer() else vapply(population, `[[`, integer(1), "id")
}

.alive_ids <- function(population) {
  if (!length(population)) {
    return(integer())
  }
  alive <- vapply(population, function(ind) isTRUE(ind$alive), logical(1))
  .population_ids(population)[alive]
}

.normalize_population_integer_fields <- function(population) {
  integer_fields <- list(
    id = list(allow_na = FALSE, minimum = 1L),
    age = list(allow_na = FALSE, minimum = 0L),
    mother_id = list(allow_na = TRUE, minimum = 1L),
    father_id = list(allow_na = TRUE, minimum = 1L),
    patch_id = list(allow_na = TRUE, minimum = 1L)
  )
  normalized <- lapply(seq_along(population), function(index) {
    individual <- population[[index]]
    if (!is.list(individual)) {
      return(individual)
    }
    for (field in intersect(names(integer_fields), names(individual))) {
      if (!is.null(individual[[field]])) {
        spec <- integer_fields[[field]]
        individual[[field]] <- .normalize_integer_scalar(
          individual[[field]],
          paste0("population[[", index, "]]$", field),
          allow_na = spec$allow_na,
          minimum = spec$minimum
        )
      }
    }
    individual
  })
  names(normalized) <- names(population)
  normalized
}

.normalize_integer_scalar <- function(
    value,
    label,
    allow_na = FALSE,
    minimum = -.Machine$integer.max) {
  if (!is.numeric(value) || length(value) != 1L ||
      (!allow_na && is.na(value))) {
    stop(label, " must be a single integer-like value", call. = FALSE)
  }
  if (is.na(value)) {
    return(NA_integer_)
  }
  if (!is.finite(value) || value != floor(value)) {
    stop(label, " must be a finite integer-like value", call. = FALSE)
  }
  if (value < minimum) {
    stop(label, " contains an invalid value", call. = FALSE)
  }
  if (value > .Machine$integer.max) {
    stop(label, " must be representable as an R integer", call. = FALSE)
  }
  as.integer(value)
}

.normalize_positive_count <- function(value, label) {
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value) ||
      value <= 0 || value != floor(value)) {
    stop(label, " must be a single positive integer", call. = FALSE)
  }
  out <- suppressWarnings(as.integer(value))
  if (is.na(out)) {
    stop(label, " must be representable as an integer", call. = FALSE)
  }
  out
}

.normalize_non_negative_count <- function(value, label) {
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value) ||
      value < 0 || value != floor(value)) {
    stop(label, " must be a single non-negative integer", call. = FALSE)
  }
  out <- suppressWarnings(as.integer(value))
  if (is.na(out)) {
    stop(label, " must be representable as an integer", call. = FALSE)
  }
  out
}
