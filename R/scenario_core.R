#' Construct a process-based simulation scenario
#'
#' @param name Scenario name.
#' @param n_runs Number of independent replicate streams.
#' @param n_steps Number of lifecycle intervals per replicate.
#' @param init_fun Function with no arguments returning either a population list
#'   or a [pva_state()]. It runs inside the replicate RNG stream.
#' @param processes Direct ordered list of [pva_process()] objects.
#' @param seed Optional root integer seed. When `NULL`, a root seed is drawn
#'   inside a caller-restoring RNG scope.
#' @param dt Positive interval duration supplied in process context.
#' @param initial_census Optional census/observer process run once in the
#'   distinct `initial` phase at `time = 0`.
#' @param record_population_history Whether to retain state snapshots after each
#'   interval.
#'
#' @return An `openpva_scenario`.
#' @export
scenario_spec <- function(
    name,
    n_runs,
    n_steps,
    init_fun,
    processes,
    seed = NULL,
    dt = 1,
    initial_census = NULL,
    record_population_history = FALSE) {
  scenario <- list(
    name = name,
    n_runs = n_runs,
    n_steps = n_steps,
    init_fun = init_fun,
    processes = processes,
    seed = seed,
    dt = dt,
    initial_census = initial_census,
    record_population_history = record_population_history
  )
  scenario <- .validate_scenario(scenario)
  class(scenario) <- c("openpva_scenario", "list")
  scenario
}

#' Execute a process-based scenario
#'
#' Replicate streams are preassigned with L'Ecuyer-CMRG before work is sent to
#' either serial or parallel execution. Both the caller's RNG kind and
#' `.Random.seed` are restored on success and error.
#'
#' @param scenario Object from [scenario_spec()].
#' @param parallel Whether to use two or more local fork workers.
#' @param workers Number of local workers when `parallel = TRUE`.
#'
#' @return A list containing the scenario and `sim_output`. `sim_output` holds
#'   ordered per-run results, combined events, census rows and stream
#'   provenance.
#' @export
run_scenario <- function(scenario, parallel = FALSE, workers = 2L) {
  if (!inherits(scenario, "openpva_scenario")) {
    stop("scenario must be created by scenario_spec()", call. = FALSE)
  }
  scenario <- .validate_scenario(scenario)
  if (!is.logical(parallel) || length(parallel) != 1L || is.na(parallel)) {
    stop("parallel must be one non-missing logical value", call. = FALSE)
  }
  workers <- .normalize_positive_count(workers, "workers")
  if (parallel && workers < 2L) {
    stop("workers must be at least 2 when parallel = TRUE", call. = FALSE)
  }

  sim_output <- .with_rng_restored({
    root_seed <- scenario$seed
    if (is.null(root_seed)) {
      root_seed <- sample.int(.Machine$integer.max, 1L)
    }
    RNGkind("L'Ecuyer-CMRG")
    set.seed(root_seed)
    streams <- .make_replicate_streams(scenario$n_runs)

    run_one <- function(run_id) {
      .with_replicate_stream(streams[[run_id]], {
        .run_process_replicate(
          scenario = scenario,
          run_id = run_id,
          root_seed = root_seed,
          stream = streams[[run_id]]
        )
      })
    }

    runs <- if (parallel) {
      if (.Platform$OS.type == "windows") {
        stop("parallel process execution requires fork support", call. = FALSE)
      }
      parallel::mclapply(
        seq_len(scenario$n_runs),
        run_one,
        mc.cores = min(workers, scenario$n_runs),
        mc.preschedule = TRUE,
        mc.set.seed = FALSE
      )
    } else {
      lapply(seq_len(scenario$n_runs), run_one)
    }

    list(
      runs = runs,
      events = dplyr::bind_rows(lapply(runs, `[[`, "events")),
      census = dplyr::bind_rows(lapply(runs, `[[`, "census")),
      provenance = list(
        root_seed = as.integer(root_seed),
        rng_kind = "L'Ecuyer-CMRG",
        streams = streams,
        process_plan = .build_process_plan(scenario$processes)
      )
    )
  })

  list(scenario = scenario, sim_output = sim_output)
}

#' @export
print.openpva_scenario <- function(x, ...) {
  cat(sprintf(
    "<OpenPVA scenario '%s' | runs: %d | steps: %d | processes: %s>\n",
    x$name,
    x$n_runs,
    x$n_steps,
    paste(vapply(x$processes, `[[`, character(1), "name"), collapse = " -> ")
  ))
  invisible(x)
}

.validate_scenario <- function(scenario) {
  if (!is.list(scenario)) {
    stop("scenario must be a list", call. = FALSE)
  }
  if (!is.character(scenario$name) || length(scenario$name) != 1L ||
      is.na(scenario$name) || !nzchar(scenario$name)) {
    stop("scenario name must be a non-empty character scalar", call. = FALSE)
  }
  scenario$n_runs <- .normalize_positive_count(scenario$n_runs, "n_runs")
  scenario$n_steps <- .normalize_positive_count(scenario$n_steps, "n_steps")
  if (!is.function(scenario$init_fun)) {
    stop("init_fun must be a function", call. = FALSE)
  }
  scenario$processes <- validate_processes(scenario$processes)
  scenario$seed <- .normalize_optional_seed(scenario$seed)
  scenario$dt <- as.numeric(scenario$dt)
  if (length(scenario$dt) != 1L || !is.finite(scenario$dt) || scenario$dt <= 0) {
    stop("dt must be one positive numeric value", call. = FALSE)
  }
  if (!is.null(scenario$initial_census)) {
    scenario$initial_census <- .validate_process(scenario$initial_census)
    if (length(scenario$initial_census$writes) || !is.null(scenario$initial_census$creates)) {
      stop("initial_census must be a non-creating observer process", call. = FALSE)
    }
  }
  if (!is.logical(scenario$record_population_history) ||
      length(scenario$record_population_history) != 1L ||
      is.na(scenario$record_population_history)) {
    stop("record_population_history must be one non-missing logical value", call. = FALSE)
  }
  scenario
}

.run_process_replicate <- function(scenario, run_id, root_seed, stream) {
  initial <- scenario$init_fun()
  state <- if (.is_pva_state(initial)) initial else pva_state(initial)
  validate_processes(scenario$processes, state)
  if (!is.null(scenario$initial_census)) {
    validate_processes(list(scenario$initial_census), state)
  }

  execution_id <- paste0(scenario$name, ":run-", run_id)
  stream_record <- list(root_seed = as.integer(root_seed), stream = stream)
  event_batches <- list()
  if (!is.null(scenario$initial_census)) {
    initial_result <- .execute_processes_trusted(
      state = state,
      processes = list(scenario$initial_census),
      run = run_id,
      time = 0L,
      dt = scenario$dt,
      stream_provenance = stream_record,
      execution_id = execution_id,
      phase = "initial"
    )
    state <- initial_result$state
    event_batches[[length(event_batches) + 1L]] <- initial_result$events
  }

  history <- if (scenario$record_population_history) vector("list", scenario$n_steps) else NULL
  for (time in seq.int(0L, scenario$n_steps - 1L)) {
    interval_result <- .execute_processes_trusted(
      state = state,
      processes = scenario$processes,
      run = run_id,
      time = time,
      dt = scenario$dt,
      stream_provenance = stream_record,
      execution_id = execution_id,
      phase = "interval"
    )
    state <- interval_result$state
    event_batches[[length(event_batches) + 1L]] <- interval_result$events
    if (scenario$record_population_history) {
      history[[time + 1L]] <- .clone_state(state)
    }
  }
  events <- dplyr::bind_rows(event_batches)
  list(
    state = state,
    population = state$population,
    events = events,
    census = events[events$event_type == "census", , drop = FALSE],
    population_history = history,
    provenance = list(
      run = as.integer(run_id),
      root_seed = as.integer(root_seed),
      initial_stream = stream,
      final_stream = get(".Random.seed", envir = .GlobalEnv, inherits = FALSE),
      process_plan = .build_process_plan(scenario$processes)
    )
  )
}

.is_pva_state <- function(value) {
  is.list(value) && all(c("population", "globals", "next_id") %in% names(value))
}

.make_replicate_streams <- function(n_runs) {
  streams <- vector("list", n_runs)
  streams[[1L]] <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (n_runs > 1L) {
    for (index in 2:n_runs) {
      streams[[index]] <- parallel::nextRNGStream(streams[[index - 1L]])
    }
  }
  streams
}

.with_replicate_stream <- function(stream, expr) {
  expr <- substitute(expr)
  evaluation_env <- parent.frame()
  .with_rng_restored({
    RNGkind("L'Ecuyer-CMRG")
    assign(".Random.seed", stream, envir = .GlobalEnv)
    eval(expr, envir = evaluation_env)
  })
}

.with_rng_restored <- function(expr) {
  expr <- substitute(expr)
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) {
    old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  }
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  eval(expr, envir = parent.frame())
}

.with_optional_seed <- function(seed, expr) {
  expr <- substitute(expr)
  evaluation_env <- parent.frame()
  if (is.null(seed)) {
    return(eval(expr, envir = evaluation_env))
  }
  .with_rng_restored({
    set.seed(seed)
    eval(expr, envir = evaluation_env)
  })
}

.normalize_optional_seed <- function(seed) {
  if (is.null(seed)) {
    return(NULL)
  }
  if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed) ||
      seed < 0 || seed != floor(seed)) {
    stop("seed must be NULL or a single integer", call. = FALSE)
  }
  seed <- suppressWarnings(as.integer(seed))
  if (is.na(seed)) {
    stop("seed must be representable as an integer", call. = FALSE)
  }
  seed
}

.clone_state <- function(state) {
  list(
    population = lapply(state$population, function(ind) ind),
    globals = lapply(state$globals, function(value) value),
    next_id = state$next_id
  )
}
