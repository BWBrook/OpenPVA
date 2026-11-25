.keep_choices <- c("census", "events", "accounting", "state", "ledger")

scenario_spec <- function(
    name,
    n_runs,
    n_steps,
    init_fun,
    processes,
    seed = NULL,
    dt = 1,
    initial_census = NULL) {
  if (!.is_name(name)) {
    .stop("scenario name must be one non-empty character value")
  }
  if (!is.function(init_fun) || length(formals(init_fun))) {
    .stop("init_fun must be a function with no arguments")
  }
  if (!is.numeric(dt) || length(dt) != 1L || !is.finite(dt) || dt <= 0) {
    .stop("dt must be one positive number")
  }
  if (!is.null(seed)) {
    seed <- .as_count(seed, "seed")
  }
  if (!is.null(initial_census)) {
    initial_census <- .validate_process(initial_census)
    if (length(initial_census$writes) || !is.null(initial_census$creates)) {
      .stop("initial_census must be a non-mutating observer process")
    }
  }
  structure(
    list(
      name = name,
      n_runs = .as_count(n_runs, "n_runs", minimum = 1),
      n_steps = .as_count(n_steps, "n_steps", minimum = 1),
      init_fun = init_fun,
      processes = validate_processes(processes),
      seed = seed,
      dt = as.numeric(dt),
      initial_census = initial_census
    ),
    class = "pva_scenario"
  )
}

print.pva_scenario <- function(x, ...) {
  cat(sprintf(
    "<pva_scenario '%s' | runs: %d | steps: %d | processes: %s>\n",
    x$name, x$n_runs, x$n_steps,
    paste(vapply(x$processes, `[[`, character(1), "name"), collapse = " -> ")
  ))
  invisible(x)
}

run_scenario <- function(
    scenario,
    parallel = FALSE,
    workers = 2L,
    backend = c("auto", "fork", "psock"),
    cluster = NULL,
    validation = c("strict", "fast"),
    keep = c("census", "events", "accounting")) {
  if (!inherits(scenario, "pva_scenario")) {
    .stop("scenario must be created by scenario_spec()")
  }
  if (!.is_flag(parallel)) {
    .stop("parallel must be TRUE or FALSE")
  }
  backend <- match.arg(backend)
  validation <- match.arg(validation)
  if (!is.character(keep) || !all(keep %in% .keep_choices)) {
    .stop("keep must be a subset of: ", paste(.keep_choices, collapse = ", "))
  }
  workers <- .as_count(workers, "workers", minimum = 1)
  if (!is.null(cluster) && !inherits(cluster, "cluster")) {
    .stop("cluster must be NULL or a parallel cluster object")
  }

  root_seed <- scenario$seed
  if (is.null(root_seed)) {
    root_seed <- sample.int(.Machine$integer.max, 1L)
  }
  .with_rng_restored({
    RNGkind("L'Ecuyer-CMRG", "Inversion", "Rejection")
    set.seed(root_seed)
    streams <- .make_replicate_streams(scenario$n_runs)
    payload <- list(
      scenario = scenario,
      execution = .prepare_execution(scenario$processes),
      initial_execution = if (is.null(scenario$initial_census)) {
        NULL
      } else {
        .prepare_execution(list(scenario$initial_census))
      },
      streams = streams,
      strict = validation == "strict",
      keep = keep
    )
    runs <- .dispatch(
      seq_len(scenario$n_runs),
      .replicate_worker,
      payload,
      parallel = parallel,
      workers = min(workers, scenario$n_runs),
      backend = backend,
      cluster = cluster,
      preschedule = TRUE
    )
  })

  result <- list(
    scenario = scenario,
    census = .rbind_frames(lapply(runs, `[[`, "census")),
    events = .rbind_frames(lapply(runs, `[[`, "events")),
    accounting = .rbind_frames(lapply(runs, `[[`, "accounting")),
    states = if ("state" %in% keep) lapply(runs, `[[`, "state") else NULL,
    ledgers = if ("ledger" %in% keep) lapply(runs, `[[`, "ledger") else NULL,
    provenance = list(
      root_seed = as.integer(root_seed),
      rng_kind = c("L'Ecuyer-CMRG", "Inversion", "Rejection"),
      streams = streams,
      validation = validation,
      process_plan = payload$execution$plan,
      package_version = as.character(utils::packageVersion("OpenPVA")),
      r_version = R.version.string
    )
  )
  class(result) <- "pva_run"
  result
}

print.pva_run <- function(x, ...) {
  cat(sprintf(
    "<pva_run '%s' | runs: %d | steps: %d | root seed: %d | validation: %s>\n",
    x$scenario$name, x$scenario$n_runs, x$scenario$n_steps,
    x$provenance$root_seed, x$provenance$validation
  ))
  invisible(x)
}

.dispatch <- function(
    items,
    worker,
    payload,
    parallel,
    workers,
    backend,
    cluster,
    preschedule) {
  if (!parallel || (workers < 2L && is.null(cluster))) {
    return(lapply(items, worker, payload = payload))
  }
  if (!is.null(cluster)) {
    backend <- "psock"
  } else if (backend == "auto") {
    backend <- if (.Platform$OS.type == "windows") "psock" else "fork"
  }
  if (backend == "fork") {
    if (.Platform$OS.type == "windows") {
      .stop("the fork backend is unavailable on Windows; use backend = 'psock'")
    }
    results <- parallel::mclapply(
      items,
      worker,
      payload = payload,
      mc.cores = workers,
      mc.preschedule = preschedule,
      mc.set.seed = FALSE
    )
    failed <- vapply(results, function(result) {
      inherits(result, "try-error") || is.null(result)
    }, logical(1))
    if (any(failed)) {
      message <- results[[which(failed)[[1L]]]]
      .stop(
        "a fork worker failed",
        if (is.null(message)) " (worker killed or out of memory)" else paste0(": ", message)
      )
    }
    return(results)
  }
  if (is.null(cluster)) {
    cluster <- parallel::makePSOCKcluster(workers, rscript_args = "--vanilla")
    on.exit(parallel::stopCluster(cluster), add = TRUE)
  }
  paths <- unique(c(dirname(getNamespaceInfo(asNamespace("OpenPVA"), "path")), .libPaths()))
  parallel::clusterCall(cluster, ".libPaths", paths, include.site = FALSE)
  parallel::clusterCall(cluster, base::library, "OpenPVA", character.only = TRUE)
  callbacks <- if (is.null(payload$scenario)) {
    payload[c("build", "summarise")]
  } else {
    payload$scenario[c("init_fun", "processes", "initial_census")]
  }
  bindings <- .callback_bindings(callbacks)
  if (length(bindings)) {
    parallel::clusterExport(cluster, names(bindings), envir = list2env(bindings))
  }
  if (preschedule) {
    parallel::parLapply(cluster, items, worker, payload = payload)
  } else {
    parallel::clusterApplyLB(cluster, items, worker, payload = payload)
  }
}

.callback_bindings <- function(callbacks, fingerprint = FALSE) {
  globals <- new.env(parent = emptyenv())
  visited <- list()
  definitions <- list()
  visit <- function(x) {
    if (is.list(x)) {
      parts <- lapply(x, visit)
      if (fingerprint) return(list(attributes = attributes(x), values = parts))
      return(NULL)
    }
    if (!is.function(x)) return(if (fingerprint) x)
    scope <- environment(x)
    if (fingerprint) {
      clean <- utils::removeSource(x)
      code <- if (is.primitive(x)) deparse(x) else list(formals(clean), body(clean))
    }
    if (is.null(scope) || isNamespace(scope) || identical(scope, baseenv())) {
      return(if (fingerprint) list(code = code, namespace = environmentName(scope)))
    }
    seen <- which(vapply(visited, identical, logical(1), y = x))
    if (length(seen)) return(list(callback = seen[[1L]]))
    id <- length(visited) + 1L
    visited[[id]] <<- x
    captures <- list()
    for (name in codetools::findGlobals(x)) {
      env <- scope
      while (!identical(env, emptyenv())) {
        if (exists(name, envir = env, inherits = FALSE)) {
          if (identical(env, baseenv()) || isNamespace(env) || startsWith(environmentName(env), "imports:")) break
          value <- get(name, envir = env, inherits = FALSE)
          if (identical(env, .GlobalEnv) || startsWith(environmentName(env), "package:")) {
            assign(name, value, envir = globals)
          }
          captures[name] <- list(visit(value))
          break
        }
        env <- parent.env(env)
      }
    }
    if (fingerprint) definitions[[id]] <<- list(code = code, captures = captures)
    list(callback = id)
  }
  roots <- visit(callbacks)
  if (!fingerprint) return(as.list(globals, all.names = TRUE))
  file <- tempfile()
  on.exit(unlink(file))
  saveRDS(list(roots, definitions), file, compress = FALSE, version = 2L)
  unname(tools::md5sum(file))
}

.replicate_worker <- function(run_id, payload) {
  .with_rng_restored({
    RNGkind("L'Ecuyer-CMRG", "Inversion", "Rejection")
    assign(".Random.seed", payload$streams[[run_id]], envir = .GlobalEnv)
    .run_replicate(
      scenario = payload$scenario,
      execution = payload$execution,
      initial_execution = payload$initial_execution,
      run_id = run_id,
      strict = payload$strict,
      keep = payload$keep
    )
  })
}

.run_replicate <- function(
    scenario,
    execution,
    initial_execution,
    run_id,
    strict,
    keep) {
  initial <- scenario$init_fun()
  state <- if (inherits(initial, "pva_state")) {
    .validate_state(initial)
  } else {
    pva_state(initial)
  }
  .validate_field_plan(execution$processes, state)
  state <- .open_kinship(state)
  keep_events <- "events" %in% keep
  keep_ledger <- "ledger" %in% keep
  n_steps <- scenario$n_steps
  has_initial <- !is.null(initial_execution)
  n_batches <- n_steps + has_initial
  times <- c(if (has_initial) 0L, seq.int(0L, n_steps - 1L))
  phases <- c(if (has_initial) "initial", rep("interval", n_steps))
  event_batches <- vector("list", n_batches)
  census_batches <- vector("list", n_batches)
  accounting <- vector("list", n_steps)
  ledger <- if (keep_ledger) vector("list", n_steps) else NULL
  plans <- c(
    if (has_initial) list(initial_execution$plan),
    rep(list(execution$plan), n_steps)
  )

  if (has_initial) {
    .validate_field_plan(initial_execution$processes, state)
    observed <- .run_processes(
      state, initial_execution, run_id, 0L, scenario$dt, "initial", n_steps,
      strict = strict, keep_events = keep_events, keep_ledger = FALSE
    )
    event_batches[[1L]] <- observed$events
    census_batches[[1L]] <- observed$census
  }
  for (step in seq_len(n_steps)) {
    interval <- .run_processes(
      state, execution, run_id, step - 1L, scenario$dt, "interval", n_steps,
      strict = strict, keep_events = keep_events, keep_ledger = keep_ledger
    )
    state <- interval$state
    event_batches[[step + has_initial]] <- interval$events
    census_batches[[step + has_initial]] <- interval$census
    accounting[[step]] <- interval$accounting
    if (keep_ledger) {
      ledger[[step]] <- interval$ledger
    }
  }

  out <- list()
  if ("census" %in% keep) {
    out$census <- .bind_census(census_batches, run_id, times, phases, plans)
  }
  if (keep_events) {
    out$events <- .bind_events(
      event_batches[seq.int(1L + has_initial, n_batches)],
      run_id,
      times[seq.int(1L + has_initial, n_batches)],
      phases[seq.int(1L + has_initial, n_batches)],
      execution
    )
  }
  if ("accounting" %in% keep) {
    out$accounting <- cbind(
      run = as.integer(run_id),
      as.data.frame(do.call(rbind, accounting))
    )
  }
  state <- if ("state" %in% keep) .close_kinship(state) else state
  if ("state" %in% keep) {
    out$state <- state
  }
  if (keep_ledger) {
    out$ledger <- .bind_ledger(unlist(ledger, recursive = FALSE), state)
  }
  out
}

.rbind_frames <- function(frames) {
  frames <- Filter(Negate(is.null), frames)
  if (!length(frames)) {
    return(NULL)
  }
  fields <- names(frames[[1L]])
  if (!all(vapply(frames, function(frame) identical(names(frame), fields), logical(1)))) {
    .stop("replicates returned tables with different columns")
  }
  columns <- lapply(fields, function(field) {
    unlist(lapply(frames, `[[`, field), use.names = FALSE)
  })
  names(columns) <- fields
  as.data.frame(columns, stringsAsFactors = FALSE, check.names = FALSE)
}

.make_replicate_streams <- function(n_runs) {
  streams <- vector("list", n_runs)
  streams[[1L]] <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  for (index in seq_len(n_runs - 1L)) {
    streams[[index + 1L]] <- parallel::nextRNGStream(streams[[index]])
  }
  streams
}

.with_rng_restored <- function(expr) {
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
  expr
}
