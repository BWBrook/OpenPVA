.accounting_columns <- c(
  "time", "process_index", "n_before",
  "births", "introductions",
  "deaths_resident", "deaths_born", "deaths_introduced",
  "removals_resident", "removals_born", "removals_introduced",
  "n_after"
)

pva_process <- function(
    name,
    run,
    params = list(),
    requires = character(),
    writes = character(),
    creates = NULL,
    description = NULL) {
  process <- list(
    name = name,
    run = run,
    params = params,
    requires = requires,
    writes = writes,
    creates = creates,
    description = description
  )
  .validate_process(process)
}

.validate_process <- function(process) {
  if (!is.list(process)) {
    .stop("a process must be a list created by pva_process()")
  }
  if (!.is_name(process$name)) {
    .stop("process name must be one non-empty character value")
  }
  label <- paste0("process '", process$name, "'")
  if (!is.function(process$run) || length(formals(process$run)) != 3L) {
    .stop(label, " run must be a function of (state, context, params)")
  }
  if (!is.list(process$params)) {
    .stop(label, " params must be a list")
  }
  process$requires <- .field_names(process$requires, paste(label, "requires"))
  process$writes <- .field_names(process$writes, paste(label, "writes"))
  paths <- c(process$requires, process$writes)
  if (any(!grepl("^(population|globals)\\.[^.]+", paths))) {
    .stop(label, " field paths must look like population.<field> or globals.<name>")
  }
  engine_paths <- paste0("population.", .engine_owned_fields)
  if (any(process$writes %in% engine_paths)) {
    .stop(
      label, " cannot write engine-owned field(s): ",
      paste(intersect(process$writes, engine_paths), collapse = ", ")
    )
  }
  if (!is.null(process$creates)) {
    process$creates <- .field_names(process$creates, paste(label, "creates"))
    if (any(process$creates %in% c(.engine_owned_fields, "alive"))) {
      .stop(label, " creates cannot list engine-owned fields or alive")
    }
    if (!all(c("sex", "age") %in% process$creates)) {
      .stop(label, " creates must include sex and age")
    }
  }
  if (!is.null(process$description) && !.is_name(process$description)) {
    .stop(label, " description must be NULL or one character value")
  }
  class(process) <- "pva_process"
  process
}

print.pva_process <- function(x, ...) {
  cat(sprintf(
    "<pva_process '%s' | requires: %s | writes: %s%s>\n",
    x$name,
    if (length(x$requires)) paste(x$requires, collapse = ", ") else "-",
    if (length(x$writes)) paste(x$writes, collapse = ", ") else "-",
    if (is.null(x$creates)) "" else paste0(" | creates: ", paste(x$creates, collapse = ", "))
  ))
  invisible(x)
}

pva_events <- function(event_type, value = 1, label = NA_character_,
                       origin_patch_id = NULL, destination_patch_id = NULL) {
  n <- length(event_type)
  if (!is.character(event_type) || anyNA(event_type) || any(!nzchar(event_type))) {
    .stop("event_type must be non-empty character values")
  }
  if (!is.numeric(value) || anyNA(value) || !(length(value) %in% c(1L, n))) {
    .stop("event value must be non-missing numeric with length 1 or one per event")
  }
  if (!(length(label) %in% c(1L, n))) {
    .stop("event label must have length 1 or one per event")
  }
  events <- list(
    event_type = event_type,
    value = rep_len(as.numeric(value), n),
    label = rep_len(as.character(label), n)
  )
  if (!is.null(origin_patch_id) || !is.null(destination_patch_id)) {
    if (length(origin_patch_id) != n || length(destination_patch_id) != n) {
      .stop("supply an origin_patch_id and destination_patch_id for each event")
    }
    events$origin_patch_id <- as.character(origin_patch_id)
    events$destination_patch_id <- as.character(destination_patch_id)
  }
  events
}

pva_result <- function(state, events = NULL, census = NULL) {
  fields <- c("event_type", "value", "label")
  if (!is.null(events) && !(is.list(events) && (identical(names(events), fields) ||
      identical(names(events), c(fields, "origin_patch_id", "destination_patch_id"))))) {
    .stop("events must be NULL or created by pva_events()")
  }
  if (!is.null(census) &&
      !(is.numeric(census) && length(census) && !is.null(names(census)) &&
        all(nzchar(names(census))) && !anyDuplicated(names(census)))) {
    .stop("census must be NULL or a uniquely named numeric vector")
  }
  result <- list(state = state, events = events, census = census)
  class(result) <- "pva_result"
  result
}

validate_processes <- function(processes, state = NULL) {
  if (!is.list(processes) || !length(processes) || inherits(processes, "pva_process")) {
    .stop("processes must be a non-empty ordered list of pva_process objects")
  }
  processes <- lapply(processes, .validate_process)
  if (!is.null(state)) {
    .validate_field_plan(processes, .validate_state(state))
  }
  invisible(processes)
}

.prepare_execution <- function(processes) {
  processes <- lapply(processes, .validate_process)
  names_in_order <- vapply(processes, `[[`, character(1), "name")
  occurrence <- stats::ave(seq_along(names_in_order), names_in_order, FUN = seq_along)
  strip <- function(paths, prefix) {
    sub(prefix, "", paths[startsWith(paths, prefix)], fixed = TRUE)
  }
  list(
    processes = processes,
    names = names_in_order,
    occurrence = as.integer(occurrence),
    closed_proxy = any(vapply(processes, function(p) {
      identical(p$run, .update_inbreeding_proxy) && is.null(p$params$migration)
    }, logical(1))),
    population_writes = lapply(processes, function(process) {
      strip(process$writes, "population.")
    }),
    checked_writes = lapply(processes, function(process) {
      intersect(strip(process$writes, "population."), c("sex", "age", "alive"))
    }),
    global_writes = lapply(processes, function(process) {
      strip(process$writes, "globals.")
    }),
    plan = data.frame(
      process_index = seq_along(processes),
      process_name = names_in_order,
      occurrence = as.integer(occurrence),
      requires = vapply(processes, function(process) {
        paste(process$requires, collapse = ";")
      }, character(1)),
      writes = vapply(processes, function(process) {
        paste(process$writes, collapse = ";")
      }, character(1)),
      creates = vapply(processes, function(process) {
        paste(process$creates, collapse = ";")
      }, character(1)),
      stringsAsFactors = FALSE
    )
  )
}

.validate_field_plan <- function(processes, state) {
  available <- c(
    paste0("population.", names(state$population)),
    if (length(state$globals)) paste0("globals.", names(state$globals))
  )
  population_fields <- names(state$population)
  creator_fields <- setdiff(
    population_fields,
    c(.engine_owned_fields, "alive", "mother_id", "father_id")
  )
  for (process in processes) {
    label <- paste0("process '", process$name, "'")
    missing <- setdiff(process$requires, available)
    if (length(missing)) {
      .stop(
        label, " requires field(s) that are neither in the initial state nor ",
        "written upstream: ", paste(missing, collapse = ", ")
      )
    }
    written <- process$writes[startsWith(process$writes, "population.")]
    unknown <- setdiff(sub("population.", "", written, fixed = TRUE), population_fields)
    if (length(unknown)) {
      .stop(
        label, " writes population field(s) absent from the initial state: ",
        paste(unknown, collapse = ", ")
      )
    }
    if (!is.null(process$creates)) {
      uninitialised <- setdiff(creator_fields, process$creates)
      if (length(uninitialised)) {
        .stop(
          label, " creates individuals without initialising: ",
          paste(uninitialised, collapse = ", ")
        )
      }
      unknown <- setdiff(process$creates, population_fields)
      if (length(unknown)) {
        .stop(
          label, " creates field(s) absent from the initial state: ",
          paste(unknown, collapse = ", ")
        )
      }
    }
    available <- union(available, process$writes)
  }
  invisible(TRUE)
}

.accounting_events <- c("death", "removal", "birth", "introduction")

.event_totals <- function(events) {
  totals <- c(death = 0, removal = 0, birth = 0, introduction = 0)
  if (is.null(events)) {
    return(totals)
  }
  kind <- match(events$event_type, .accounting_events, 0L)
  indices <- which(kind > 0L)
  counts <- events$value[indices]
  if (any(!is.finite(counts) | counts < 0 | counts != floor(counts))) {
    .stop("non-finite, negative or fractional accounting event value")
  }
  for (index in indices) {
    totals[[kind[[index]]]] <- totals[[kind[[index]]]] + events$value[[index]]
  }
  totals
}

.validate_transition <- function(
    before,
    after,
    process,
    population_writes,
    checked_writes,
    global_writes,
    totals,
    n_lost) {
  label <- paste0("process '", process$name, "'")
  if (!inherits(after, "pva_state") || !identical(names(after), names(before))) {
    .stop(label, " must return a pva_state inside pva_result()")
  }
  old <- before$population
  new <- after$population
  n_before <- length(old$id)
  n_after <- length(new$id)
  if (!identical(names(new), names(old))) {
    .stop(label, " changed the set or order of population fields")
  }
  if (n_after < n_before) {
    .stop(label, " deleted population records; mortality must set alive = FALSE")
  }
  n_new <- n_after - n_before
  existing <- seq_len(n_before)
  fields <- names(old)
  writable <- fields %in% population_writes
  for (i in seq_along(old)) {
    column <- new[[i]]
    previous <- old[[i]]
    if (length(column) != n_after || typeof(column) != typeof(previous) ||
        !is.null(attributes(column))) {
      .stop(label, " returned population field ", fields[[i]], " with the wrong type or length")
    }
    if (!writable[[i]]) {
      if (n_new) column <- column[existing]
      if (!identical(column, previous)) {
        .stop(label, " changed undeclared field population.", fields[[i]])
      }
    }
  }
  for (field in checked_writes) {
    if (anyNA(new[[field]])) {
      .stop(label, " wrote missing values to population.", field)
    }
  }
  if (match("sex", checked_writes, 0L) && !all(new$sex == "F" | new$sex == "M")) {
    .stop(label, " wrote a sex other than 'F' or 'M'")
  }
  if (match("age", checked_writes, 0L) && any(new$age < 0L)) {
    .stop(label, " wrote a negative age")
  }

  if (!identical(after$next_id, before$next_id + n_new)) {
    .stop(label, " changed next_id without adding matching records through add_individuals()")
  }
  if (!identical(after$kinship, before$kinship)) {
    .stop(label, " changed the engine-owned kinship store")
  }
  if (!identical(after$max_dense_kinship, before$max_dense_kinship)) {
    .stop(label, " changed the engine-owned max_dense_kinship limit")
  }
  if (n_new) {
    if (is.null(process$creates)) {
      .stop(label, " created individuals without a creates declaration")
    }
    created <- seq.int(n_before + 1L, n_after)
    if (!identical(new$id[created], seq.int(before$next_id, length.out = n_new))) {
      .stop(label, " created records whose ids were not allocated by the engine")
    }
    if (!all(new$alive[created])) {
      .stop(label, " created individuals that were not alive when it returned")
    }
    sex <- new$sex[created]
    if (anyNA(sex) || !all(sex == "F" | sex == "M") ||
        anyNA(new$age[created]) || any(new$age[created] < 0L)) {
      .stop(label, " created individuals with an invalid sex or age")
    }
    if (!all(is.na(new$origin[created])) || !all(is.na(new$entry_time[created]))) {
      .stop(label, " set engine-owned origin or entry_time on created individuals")
    }
  }

  old_globals <- before$globals
  new_globals <- after$globals
  if (!is.list(new_globals) || anyDuplicated(names(new_globals))) {
    .stop(label, " returned invalid globals")
  }
  if (length(global_writes) || !identical(old_globals, new_globals)) {
    global_names <- names(new_globals)
    if (!identical(global_names, names(old_globals))) {
      global_names <- union(names(old_globals), global_names)
    }
    for (name in global_names) {
      if (!match(name, global_writes, 0L) &&
          !identical(old_globals[[name]], new_globals[[name]])) {
        .stop(label, " changed undeclared field globals.", name)
      }
    }
  }

  if (n_lost != totals[["death"]] + totals[["removal"]]) {
    .stop(
      label, " accounting mismatch: ", n_lost,
      " existing individual(s) stopped living but death + removal events total ",
      totals[["death"]] + totals[["removal"]]
    )
  }
  if (totals[["death"]] > 0 && totals[["removal"]] > 0) {
    .stop(label, " reported both deaths and removals; use one loss type per process")
  }
  if (n_new != totals[["birth"]] + totals[["introduction"]]) {
    .stop(
      label, " accounting mismatch: ", n_new,
      " individual(s) were created but birth + introduction events total ",
      totals[["birth"]] + totals[["introduction"]]
    )
  }
  if (totals[["birth"]] > 0 && totals[["introduction"]] > 0) {
    .stop(label, " reported both births and introductions; use one entry type per process")
  }
  invisible(TRUE)
}

.run_processes <- function(
    state,
    execution,
    run,
    time,
    dt,
    phase,
    n_steps,
    strict = TRUE,
    keep_events = TRUE,
    keep_ledger = FALSE) {
  processes <- execution$processes
  n_processes <- length(processes)
  time <- as.integer(time)
  accounting <- matrix(
    0L,
    nrow = n_processes,
    ncol = length(.accounting_columns),
    dimnames = list(NULL, .accounting_columns)
  )
  events <- vector("list", n_processes)
  census <- vector("list", n_processes)
  ledger <- if (keep_ledger) vector("list", n_processes) else NULL
  pedigree <- !is.null(state$kinship)
  dead_males <- dead_females <- integer()

  for (index in seq_len(n_processes)) {
    process <- processes[[index]]
    context <- list(
      run = run,
      time = time,
      dt = dt,
      phase = phase,
      n_steps = n_steps,
      process_index = index,
      process_name = process$name,
      occurrence = execution$occurrence[[index]],
      departed_males = dead_males
    )
    result <- process$run(state, context, process$params)
    if (!inherits(result, "pva_result")) {
      .stop("process '", process$name, "' must return pva_result()")
    }
    after <- result$state
    population <- after$population
    n_before <- length(state$population$id)
    n_after <- length(population$id)
    n_new <- n_after - n_before
    lost <- which(!population$alive[seq_len(n_before)])
    n_lost <- length(lost)
    totals <- .event_totals(result$events)
    if (strict) {
      .validate_transition(
        before = state,
        after = after,
        process = process,
        population_writes = execution$population_writes[[index]],
        checked_writes = execution$checked_writes[[index]],
        global_writes = execution$global_writes[[index]],
        totals = totals,
        n_lost = n_lost
      )
    }

    accounting[index, 1L] <- time
    accounting[index, 2L] <- index
    accounting[index, 3L] <- n_before
    if (n_new > 0L) {
      created <- seq.int(n_before + 1L, n_after)
      introduced <- totals[[4L]] > 0
      population$origin[created] <- if (introduced) "introduction" else "birth"
      population$entry_time[created] <- time
      accounting[index, if (introduced) 5L else 4L] <- n_new
      if (pedigree) {
        births <- .kinship_births(
          after$kinship, population, n_before, context, dead_females, state$max_dense_kinship
        )
        after$kinship <- births$store
        population$pedigree_F[created] <- births$F
      }
    }
    if (n_lost > 0L) {
      entered <- population$entry_time[lost] == time
      born <- sum(entered & population$origin[lost] == "birth")
      introduced <- sum(entered & population$origin[lost] == "introduction")
      loss <- if (totals[[2L]] > 0) "removal" else "death"
      first <- if (loss == "removal") 9L else 6L
      accounting[index, first] <- n_lost - born - introduced
      accounting[index, first + 1L] <- born
      accounting[index, first + 2L] <- introduced
      if (keep_ledger) {
        chunk <- lapply(population, `[`, lost)
        chunk$exit_time <- rep(as.integer(time), n_lost)
        chunk$exit_process <- rep(process$name, n_lost)
        chunk$exit_type <- rep(loss, n_lost)
        ledger[[index]] <- chunk
      }
      male <- population$sex[lost] == "M"
      dead_males <- c(dead_males, population$id[lost[male]])
      if (pedigree) dead_females <- c(dead_females, population$id[lost[!male]])
      keep <- population$alive
      population <- lapply(population, `[`, keep)
    }
    accounting[index, 12L] <- length(population$id)
    after$population <- population
    state <- after
    if (keep_events && !is.null(result$events)) {
      events[[index]] <- result$events
    }
    if (!is.null(result$census)) {
      census[[index]] <- result$census
    }
  }
  if (pedigree) {
    state$kinship <- .kinship_release(state$kinship, c(dead_males, dead_females))
  }
  if (execution$closed_proxy && any(accounting[, 5L] > 0L)) {
    msg <- "introductions with an inbreeding proxy require an explicit migration function"
    if (strict) .stop(msg) else warning(msg, call. = FALSE)
  }
  list(
    state = state,
    events = events,
    census = census,
    accounting = accounting,
    ledger = ledger
  )
}

.bind_events <- function(batches, run, times, phases, execution) {
  rows <- list()
  for (batch_index in seq_along(batches)) {
    batch <- batches[[batch_index]]
    for (index in seq_along(batch)) {
      events <- batch[[index]]
      if (is.null(events) || !length(events$event_type)) {
        next
      }
      n <- length(events$event_type)
      rows[[length(rows) + 1L]] <- list(
        time = rep(times[[batch_index]], n),
        phase = rep(phases[[batch_index]], n),
        process_index = rep(index, n),
        event_type = events$event_type,
        value = events$value,
        label = events$label,
        origin_patch_id = if (is.null(events$origin_patch_id)) rep(NA_character_, n) else events$origin_patch_id,
        destination_patch_id = if (is.null(events$destination_patch_id)) rep(NA_character_, n) else events$destination_patch_id
      )
    }
  }
  column <- function(name, empty) {
    if (length(rows)) unlist(lapply(rows, `[[`, name), use.names = FALSE) else empty
  }
  process_index <- column("process_index", integer())
  data.frame(
    run = rep(as.integer(run), length(process_index)),
    time = as.integer(column("time", integer())),
    phase = column("phase", character()),
    process_index = as.integer(process_index),
    process_name = execution$names[process_index],
    occurrence = execution$occurrence[process_index],
    event_type = column("event_type", character()),
    value = column("value", numeric()),
    label = column("label", character()),
    origin_patch_id = column("origin_patch_id", character()),
    destination_patch_id = column("destination_patch_id", character()),
    stringsAsFactors = FALSE
  )
}

.bind_census <- function(batches, run, times, phases, plans) {
  rows <- list()
  header <- list(time = integer(), phase = character(), process_name = character(),
                 occurrence = integer())
  for (batch_index in seq_along(batches)) {
    batch <- batches[[batch_index]]
    for (index in seq_along(batch)) {
      if (is.null(batch[[index]])) {
        next
      }
      rows[[length(rows) + 1L]] <- batch[[index]]
      header$time <- c(header$time, times[[batch_index]])
      header$phase <- c(header$phase, phases[[batch_index]])
      plan <- plans[[batch_index]]
      header$process_name <- c(header$process_name, plan$process_name[[index]])
      header$occurrence <- c(header$occurrence, plan$occurrence[[index]])
    }
  }
  if (!length(rows)) {
    return(NULL)
  }
  metric_names <- names(rows[[1L]])
  if (any(metric_names %in% c("run", names(header)))) {
    .stop("census metric names must differ from the run, time, phase, process_name and occurrence columns")
  }
  consistent <- vapply(rows, function(row) identical(names(row), metric_names), logical(1))
  if (!all(consistent)) {
    .stop("every census in one run must report the same named metrics in the same order")
  }
  metrics <- matrix(
    as.numeric(unlist(rows, use.names = FALSE)),
    ncol = length(metric_names),
    byrow = TRUE,
    dimnames = list(NULL, metric_names)
  )
  cbind(
    data.frame(
      run = rep(as.integer(run), length(rows)),
      time = as.integer(header$time),
      phase = header$phase,
      process_name = header$process_name,
      occurrence = header$occurrence,
      stringsAsFactors = FALSE
    ),
    as.data.frame(metrics, stringsAsFactors = FALSE)
  )
}

.bind_ledger <- function(chunks, state) {
  chunks <- Filter(Negate(is.null), chunks)
  living <- state$population
  n <- length(living$id)
  living$exit_time <- rep(NA_integer_, n)
  living$exit_process <- rep(NA_character_, n)
  living$exit_type <- rep(NA_character_, n)
  chunks[[length(chunks) + 1L]] <- living
  fields <- names(living)
  ledger <- lapply(fields, function(field) {
    unlist(lapply(chunks, `[[`, field), use.names = FALSE)
  })
  names(ledger) <- fields
  ledger <- as.data.frame(ledger, stringsAsFactors = FALSE)
  ledger <- ledger[order(ledger$id), , drop = FALSE]
  rownames(ledger) <- NULL
  ledger
}

execute_processes <- function(
    state,
    processes,
    time = 0L,
    run = 1L,
    dt = 1,
    validation = c("strict", "fast")) {
  validation <- match.arg(validation)
  state <- .validate_state(state)
  execution <- .prepare_execution(validate_processes(processes))
  .validate_field_plan(execution$processes, state)
  time <- .as_count(time, "time")
  state <- .open_kinship(state)
  result <- .run_processes(
    state = state,
    execution = execution,
    run = .as_count(run, "run", minimum = 1),
    time = time,
    dt = dt,
    phase = "interval",
    n_steps = time + 1L,
    strict = validation == "strict",
    keep_events = TRUE,
    keep_ledger = TRUE
  )
  result$state <- .close_kinship(result$state)
  list(
    state = result$state,
    events = .bind_events(list(result$events), run, time, "interval", execution),
    census = .bind_census(list(result$census), run, time, "interval", list(execution$plan)),
    accounting = as.data.frame(result$accounting),
    ledger = .bind_ledger(result$ledger, result$state)
  )
}
