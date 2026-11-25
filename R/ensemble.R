.census_matrix <- function(result, metric, process_name, include_initial, occurrence) {
  complete_run <- inherits(result, "pva_run")
  census <- if (complete_run) result$census else result
  if (!is.data.frame(census) ||
      !all(c("run", "time", "phase", "process_name") %in% names(census))) {
    .stop("result must be a pva_run with census rows, or its census data frame")
  }
  if (!.is_name(metric) || !is.numeric(census[[metric]])) {
    .stop("metric must name one numeric census column")
  }
  interval <- census[census$phase == "interval", , drop = FALSE]
  if (!nrow(interval)) {
    .stop("the census has no interval rows; add a census_process() to the lifecycle")
  }
  runs <- if (complete_run) seq_len(result$scenario$n_runs) else sort(unique(census$run))
  times <- if (complete_run) seq_len(result$scenario$n_steps) - 1L else sort(unique(interval$time))
  if (is.null(process_name)) {
    process_name <- unique(interval$process_name)
    if (length(process_name) != 1L) {
      .stop("multiple interval census processes; select one with process_name")
    }
  }
  if (!.is_name(process_name) || !(process_name %in% interval$process_name)) {
    .stop("process_name must identify an interval census process")
  }
  interval <- interval[interval$process_name == process_name, , drop = FALSE]
  if (is.null(interval$occurrence)) interval$occurrence <- 1L
  if (is.null(occurrence)) {
    occurrence <- unique(interval$occurrence)
    if (length(occurrence) != 1L) {
      .stop("census process '", process_name, "' is repeated; select an occurrence")
    }
  }
  occurrence <- .as_count(occurrence, "occurrence", minimum = 1L)
  interval <- interval[interval$occurrence == occurrence, , drop = FALSE]
  index <- match(interval$run, runs) + (match(interval$time, times) - 1) * length(runs)
  if (length(index) != length(runs) * length(times) || anyNA(index) || anyDuplicated(index)) {
    .stop("census process '", process_name, "' must report exactly once per interval and run")
  }
  values <- matrix(NA_real_, length(runs), length(times))
  values[index] <- interval[[metric]]
  years <- times + 1L
  if (is.null(include_initial)) {
    include_initial <- if (complete_run) !is.null(result$scenario$initial_census) else any(census$phase == "initial")
  }
  if (!.is_flag(include_initial)) .stop("include_initial must be TRUE, FALSE or NULL")
  if (include_initial) {
    initial <- census[census$phase == "initial", , drop = FALSE]
    index <- match(runs, initial$run)
    if (nrow(initial) != length(runs) || anyNA(index) || !isTRUE(all(initial$time == 0))) {
      .stop("include_initial = TRUE needs exactly one initial census row per run")
    }
    values <- cbind(initial[[metric]][index], values)
    years <- c(0L, years)
  }
  if (any(!is.finite(values))) .stop("selected census metric must be finite for every observation")
  list(values = values, years = years, process_name = process_name, occurrence = occurrence)
}

.proportion_summary <- function(indicator, prefix) {
  n <- length(indicator)
  p <- mean(indicator)
  z <- stats::qnorm(0.975)
  centre <- (p + z^2 / (2 * n)) / (1 + z^2 / n)
  half <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / (1 + z^2 / n)
  out <- list(p, sqrt(p * (1 - p) / n), max(0, centre - half), min(1, centre + half))
  names(out) <- paste0(prefix, c("", "_mcse", "_lower", "_upper"))
  out
}

summarise_pva <- function(
    result,
    metric = "n_alive",
    threshold = 1,
    process_name = NULL,
    include_initial = NULL,
    occurrence = NULL) {
  if (!is.numeric(threshold) || length(threshold) != 1L || is.na(threshold)) {
    .stop("threshold must be one number")
  }
  census <- .census_matrix(result, metric, process_name, include_initial, occurrence)
  values <- census$values
  n_runs <- nrow(values)
  horizon <- census$years[[length(census$years)]]
  below <- values < threshold
  final <- values[, ncol(values)]
  ever <- rowSums(below) > 0
  first <- ifelse(ever, census$years[max.col(below, ties.method = "first")], NA_integer_)
  restricted <- ifelse(ever, first, horizon)
  quantiles <- stats::quantile(final, c(0.05, 0.25, 0.5, 0.75, 0.95), names = FALSE)
  mcse <- function(x) if (length(x) > 1L) stats::sd(x) / sqrt(length(x)) else NA_real_
  as.data.frame(c(
    list(
      metric = metric,
      census_process = census$process_name,
      census_occurrence = census$occurrence,
      threshold = threshold,
      n_runs = n_runs,
      horizon = horizon
    ),
    .proportion_summary(final < threshold, "p_below_at_horizon"),
    .proportion_summary(ever, "p_ever_below"),
    list(
      time_to_threshold_mean = if (any(ever)) mean(first[ever]) else NA_real_,
      time_to_threshold_median = if (any(ever)) stats::median(first[ever]) else NA_real_,
      time_to_threshold_restricted_mean = mean(restricted),
      time_to_threshold_restricted_mcse = mcse(restricted),
      final_mean = mean(final),
      final_mcse = mcse(final),
      final_q05 = quantiles[[1L]],
      final_q25 = quantiles[[2L]],
      final_median = quantiles[[3L]],
      final_q75 = quantiles[[4L]],
      final_q95 = quantiles[[5L]]
    )
  ), stringsAsFactors = FALSE)
}

summarise_trajectory <- function(
    result,
    metric = "n_alive",
    threshold = 1,
    process_name = NULL,
    include_initial = NULL,
    occurrence = NULL) {
  if (!is.numeric(threshold) || length(threshold) != 1L || is.na(threshold)) {
    .stop("threshold must be one number")
  }
  census <- .census_matrix(result, metric, process_name, include_initial, occurrence)
  values <- census$values
  n_runs <- nrow(values)
  quantiles <- apply(values, 2L, stats::quantile, probs = c(0.05, 0.5, 0.95), names = FALSE)
  below <- values < threshold
  ever <- t(apply(below, 1L, cummax))
  if (ncol(values) == 1L) {
    ever <- matrix(ever, ncol = 1L)
  }
  data.frame(
    year = census$years,
    metric = metric,
    census_process = census$process_name,
    census_occurrence = census$occurrence,
    n_runs = n_runs,
    mean = colMeans(values),
    mcse = apply(values, 2L, stats::sd) / sqrt(n_runs),
    q05 = quantiles[1L, ],
    median = quantiles[2L, ],
    q95 = quantiles[3L, ],
    p_below = colMeans(below),
    p_ever_below = colMeans(ever),
    stringsAsFactors = FALSE
  )
}

summarise_accounting <- function(result) {
  accounting <- if (is.list(result) && !is.data.frame(result)) result$accounting else result
  if (!is.data.frame(accounting) || !all(.accounting_columns %in% names(accounting))) {
    .stop("result must carry accounting rows; run with keep = 'accounting'")
  }
  if (is.null(accounting$run)) {
    accounting$run <- 1L
  }
  key <- interaction(accounting$run, accounting$time, drop = TRUE, lex.order = TRUE)
  first <- !duplicated(key)
  last <- !duplicated(key, fromLast = TRUE)
  total <- function(field) as.integer(rowsum(accounting[[field]], key, reorder = FALSE)[, 1L])
  out <- data.frame(
    run = accounting$run[first],
    time = accounting$time[first],
    n_start = accounting$n_before[first],
    births = total("births"),
    introductions = total("introductions"),
    deaths_resident = total("deaths_resident"),
    deaths_born = total("deaths_born"),
    deaths_introduced = total("deaths_introduced"),
    removals_resident = total("removals_resident"),
    removals_born = total("removals_born"),
    removals_introduced = total("removals_introduced"),
    n_end = accounting$n_after[last]
  )
  losses <- with(out, deaths_resident + deaths_born + deaths_introduced +
    removals_resident + removals_born + removals_introduced)
  out$reconciled <- out$n_start + out$births + out$introductions - losses == out$n_end
  rownames(out) <- NULL
  out
}

.default_ensemble_summary <- function(result, row) summarise_pva(result)

run_pva_ensemble <- function(
    design,
    build,
    n_runs,
    summarise = NULL,
    seed = NULL,
    seed_by = NULL,
    workers = 1L,
    backend = c("auto", "fork", "psock"),
    cluster = NULL,
    validation = c("strict", "fast"),
    cache_dir = NULL,
    cache_key = NULL) {
  if (!is.data.frame(design) || !nrow(design)) {
    .stop("design must be a data frame with one row per ensemble member")
  }
  if (!is.function(build)) {
    .stop("build must be a function of one design row returning scenario components")
  }
  if (is.null(summarise)) {
    summarise <- .default_ensemble_summary
  }
  if (!is.function(summarise)) {
    .stop("summarise must be NULL or a function of (result, row)")
  }
  backend <- match.arg(backend)
  validation <- match.arg(validation)
  n_runs <- .as_count(n_runs, "n_runs", minimum = 1)
  workers <- .as_count(workers, "workers", minimum = 1)
  if (!is.null(seed_by) &&
      (!is.character(seed_by) || !all(seed_by %in% names(design)))) {
    .stop("seed_by must name design columns")
  }
  if (!is.null(cache_dir)) {
    if (!.is_name(cache_dir)) {
      .stop("cache_dir must be NULL or one directory path")
    }
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  }
  if (!is.null(cache_key) && !.is_name(cache_key)) {
    .stop("cache_key must be NULL or a non-empty revision string")
  }

  n_members <- nrow(design)
  block <- if (is.null(seed_by)) {
    seq_len(n_members)
  } else {
    keys <- do.call(paste, c(unname(as.list(design[seed_by])), sep = "\r"))
    match(keys, unique(keys))
  }
  if (is.null(seed)) seed <- sample.int(.Machine$integer.max, 1L)
  seed <- .as_count(seed, "seed")
  version <- as.character(utils::packageVersion("OpenPVA"))
  .with_rng_restored({
    RNGkind("L'Ecuyer-CMRG", "Inversion", "Rejection")
    set.seed(seed)
    block_seeds <- sample.int(.Machine$integer.max, max(block))
    member_seeds <- block_seeds[block]
    revision <- if (!is.null(cache_dir)) {
      list(validation = validation, package_version = version, r_version = R.version.string,
           callbacks = .callback_bindings(list(build, summarise), fingerprint = TRUE),
           cache_key = cache_key)
    }
    payload <- list(
      design = design, build = build, summarise = summarise, n_runs = n_runs,
      seeds = member_seeds, validation = validation, cache_dir = cache_dir,
      revision = revision
    )
    summaries <- .dispatch(
      seq_len(n_members), .member_worker, payload,
      parallel = workers > 1L || !is.null(cluster),
      workers = min(workers, n_members), backend = backend, cluster = cluster,
      preschedule = FALSE
    )
  })
  sizes <- vapply(summaries, nrow, integer(1))
  index <- rep(seq_len(n_members), sizes)
  out <- cbind(
    design[index, , drop = FALSE],
    member = index,
    member_seed = member_seeds[index],
    .rbind_frames(summaries)
  )
  rownames(out) <- NULL
  attr(out, "provenance") <- list(
    root_seed = seed,
    n_runs = n_runs,
    seed_by = seed_by,
    validation = validation,
    package_version = version,
    r_version = R.version.string
  )
  out
}

.member_worker <- function(member, payload) {
  row <- payload$design[member, , drop = FALSE]
  seed <- payload$seeds[[member]]
  key <- list(row = as.list(row), seed = seed, n_runs = payload$n_runs, revision = payload$revision)
  path <- if (is.null(payload$cache_dir)) {
    NULL
  } else {
    file.path(payload$cache_dir, sprintf("member-%06d.rds", member))
  }
  if (!is.null(path) && file.exists(path)) {
    cached <- readRDS(path)
    if (identical(cached$key, key)) {
      return(cached$summary)
    }
  }
  summary <- .with_rng_restored({
    set.seed(seed, kind = "L'Ecuyer-CMRG", normal.kind = "Inversion", sample.kind = "Rejection")
    assign(".Random.seed", parallel::nextRNGSubStream(.GlobalEnv$.Random.seed), envir = .GlobalEnv)
    components <- payload$build(as.list(row))
    if (!is.list(components) ||
        !all(c("init_fun", "processes", "n_steps") %in% names(components))) {
      .stop("build must return a list with init_fun, processes and n_steps")
    }
    scenario <- scenario_spec(
      name = paste0("member-", member),
      n_runs = payload$n_runs,
      n_steps = components$n_steps,
      init_fun = components$init_fun,
      processes = components$processes,
      seed = seed,
      dt = if (is.null(components$dt)) 1 else components$dt,
      initial_census = components$initial_census
    )
    result <- run_scenario(
      scenario,
      validation = payload$validation,
      keep = if (is.null(components$keep)) "census" else components$keep
    )
    payload$summarise(result, as.list(row))
  })
  if (!is.data.frame(summary) || !nrow(summary)) {
    .stop("summarise must return a data frame with at least one row")
  }
  if (!is.null(path)) {
    temporary <- paste0(path, ".", Sys.getpid(), ".tmp")
    on.exit(unlink(temporary))
    saveRDS(list(key = key, summary = summary), temporary)
    if (!file.rename(temporary, path)) .stop("could not replace ensemble cache file: ", path)
  }
  summary
}
