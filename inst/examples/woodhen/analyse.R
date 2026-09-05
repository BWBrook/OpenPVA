woodhen_event_total <- function(events, run, event_types) {
  selected <- events$run == run & events$event_type %in% event_types
  sum(events$value[selected], na.rm = TRUE)
}

woodhen_accounting <- function(result, scenario_id) {
  events <- result$sim_output$events
  census <- result$sim_output$census
  run_ids <- seq_len(result$scenario$n_runs)
  rows <- lapply(run_ids, function(run) {
    initial_rows <- census[
      census$run == run & census$phase == "initial",
      ,
      drop = FALSE
    ]
    interval_rows <- census[
      census$run == run & census$phase == "interval",
      ,
      drop = FALSE
    ]
    initial_n <- initial_rows$n_alive[[1L]]
    final_n <- interval_rows$n_alive[[nrow(interval_rows)]]
    births <- woodhen_event_total(events, run, "birth")
    introductions <- woodhen_event_total(events, run, "introduction")
    deaths <- woodhen_event_total(events, run, "death")
    removals <- woodhen_event_total(events, run, "removal")
    expected_final <- initial_n + births + introductions - deaths - removals
    data.frame(
      scenario_id = scenario_id,
      run = as.integer(run),
      initial_n = as.integer(initial_n),
      births = as.integer(births),
      introductions = as.integer(introductions),
      deaths = as.integer(deaths),
      removals = as.integer(removals),
      expected_final_n = as.integer(expected_final),
      final_n = as.integer(final_n),
      reconciled = identical(as.integer(expected_final), as.integer(final_n))
    )
  })
  accounting <- do.call(rbind, rows)
  rownames(accounting) <- NULL
  if (!all(accounting$reconciled)) {
    stop("Woodhen accounting did not reconcile", call. = FALSE)
  }
  accounting
}

woodhen_run_metrics <- function(result, scenario_id, threshold_pairs) {
  census <- result$sim_output$census
  accounting <- woodhen_accounting(result, scenario_id)
  rows <- lapply(seq_len(result$scenario$n_runs), function(run) {
    run_census <- census[census$run == run, , drop = FALSE]
    interval <- run_census[run_census$phase == "interval", , drop = FALSE]
    final <- interval[nrow(interval), , drop = FALSE]
    data.frame(
      scenario_id = scenario_id,
      run = as.integer(run),
      final_n = as.integer(final$n_alive[[1L]]),
      final_pairs = as.integer(final$n_potential_pairs[[1L]]),
      extinct_at_horizon = final$n_alive[[1L]] == 0L,
      ever_below_pair_threshold = any(
        run_census$n_potential_pairs < threshold_pairs
      )
    )
  })
  metrics <- do.call(rbind, rows)
  metrics <- merge(
    metrics,
    accounting[c("scenario_id", "run", "introductions", "removals")],
    by = c("scenario_id", "run"),
    sort = FALSE
  )
  metrics[order(metrics$run), , drop = FALSE]
}

woodhen_probability_summary <- function(indicator) {
  probability <- mean(indicator)
  c(
    probability = probability,
    mcse = sqrt(probability * (1 - probability) / length(indicator))
  )
}

woodhen_scenario_summary <- function(metrics, threshold_pairs) {
  extinction <- woodhen_probability_summary(metrics$extinct_at_horizon)
  quasi <- woodhen_probability_summary(metrics$ever_below_pair_threshold)
  data.frame(
    scenario_id = metrics$scenario_id[[1L]],
    n_runs = as.integer(nrow(metrics)),
    extinction_probability = extinction[["probability"]],
    extinction_mcse = extinction[["mcse"]],
    quasi_extinction_pairs = as.integer(threshold_pairs),
    quasi_extinction_probability = quasi[["probability"]],
    quasi_extinction_mcse = quasi[["mcse"]],
    median_final_n = as.numeric(stats::median(metrics$final_n)),
    lower_final_n = as.numeric(stats::quantile(metrics$final_n, 0.025)),
    upper_final_n = as.numeric(stats::quantile(metrics$final_n, 0.975)),
    median_final_pairs = as.numeric(stats::median(metrics$final_pairs)),
    median_introductions = as.numeric(stats::median(metrics$introductions)),
    median_removals = as.numeric(stats::median(metrics$removals))
  )
}

woodhen_reconstruct_pedigree <- function(population) {
  population <- lapply(population, function(individual) {
    individual$pedigree_status <- if (
      is.na(individual$mother_id) && is.na(individual$father_id)
    ) {
      "base_founder"
    } else {
      "known_parentage"
    }
    individual$pedigree_F <- NULL
    individual
  })
  OpenPVA::initialize_pedigree(population)
}

woodhen_parentage_summary <- function(result, scenario_id) {
  rows <- lapply(seq_along(result$sim_output$runs), function(run) {
    population <- result$sim_output$runs[[run]]$state$population
    mother_id <- vapply(population, `[[`, integer(1), "mother_id")
    father_id <- vapply(population, `[[`, integer(1), "father_id")
    alive <- vapply(population, `[[`, logical(1), "alive")
    if (any(xor(is.na(mother_id), is.na(father_id)))) {
      stop("Woodhen ledger contains unsupported partial parentage", call. = FALSE)
    }
    data.frame(
      scenario_id = scenario_id,
      run = as.integer(run),
      n_records = as.integer(length(population)),
      n_alive = as.integer(sum(alive)),
      n_base_founders = as.integer(sum(is.na(mother_id) & is.na(father_id))),
      n_known_parentage = as.integer(sum(!is.na(mother_id) & !is.na(father_id)))
    )
  })
  do.call(rbind, rows)
}

woodhen_bind_rows <- function(rows) {
  fields <- unique(unlist(lapply(rows, names), use.names = FALSE))
  normalized <- lapply(rows, function(row) {
    missing <- setdiff(fields, names(row))
    for (field in missing) {
      row[[field]] <- NA
    }
    as.data.frame(row[fields], stringsAsFactors = FALSE)
  })
  output <- do.call(rbind, normalized)
  rownames(output) <- NULL
  output
}

woodhen_bind_output <- function(results, member) {
  rows <- lapply(names(results), function(scenario_id) {
    value <- results[[scenario_id]]$sim_output[[member]]
    cbind(data.frame(scenario_id = scenario_id), value)
  })
  woodhen_bind_rows(rows)
}

woodhen_manifest <- function(results, parameters) {
  scenarios <- names(results)
  data.frame(
    key = c(
      "model_id",
      "model_version",
      "source_repo",
      "source_commit",
      "openpva_version",
      "r_version",
      "scenario_ids",
      "n_runs_per_scenario",
      "root_seeds",
      "rng_relationship",
      "lifecycle",
      "pedigree_evidence",
      "inference_scope"
    ),
    value = c(
      parameters$model_id,
      parameters$model_version,
      parameters$source_repo,
      parameters$source_commit,
      as.character(utils::packageVersion("OpenPVA")),
      as.character(getRversion()),
      paste(scenarios, collapse = ";"),
      paste(vapply(results, function(x) x$scenario$n_runs, integer(1)), collapse = ";"),
      paste(vapply(results, function(x) x$sim_output$provenance$root_seed, integer(1)), collapse = ";"),
      "distinct declared root seeds; scenario contrasts are not paired inference",
      "annual conditions -> survival -> age -> territory allocation -> reproduction -> management -> census",
      "parent IDs retained for every run; exact coefficients checked in a short matched audit",
      "historically grounded illustrative reconstruction; not a calibrated assessment"
    ),
    stringsAsFactors = FALSE
  )
}

woodhen_prepare_bundle <- function(results, parameters) {
  threshold <- parameters$quasi_extinction_pairs
  metrics <- lapply(names(results), function(scenario_id) {
    woodhen_run_metrics(results[[scenario_id]], scenario_id, threshold)
  })
  names(metrics) <- names(results)
  accounting <- lapply(names(results), function(scenario_id) {
    woodhen_accounting(results[[scenario_id]], scenario_id)
  })
  parentage <- lapply(names(results), function(scenario_id) {
    woodhen_parentage_summary(results[[scenario_id]], scenario_id)
  })
  summaries <- lapply(metrics, woodhen_scenario_summary, threshold_pairs = threshold)

  list(
    manifest = woodhen_manifest(results, parameters),
    scenario_summary = do.call(rbind, summaries),
    run_metrics = do.call(rbind, metrics),
    accounting = do.call(rbind, accounting),
    parentage_summary = do.call(rbind, parentage),
    census = woodhen_bind_output(results, "census"),
    events = woodhen_bind_output(results, "events"),
    final_states = lapply(results, function(result) {
      lapply(result$sim_output$runs, `[[`, "state")
    }),
    provenance = lapply(results, function(result) result$sim_output$provenance)
  )
}

woodhen_write_bundle <- function(bundle, output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(bundle, file.path(output_dir, "result.rds"), version = 3)
  tables <- c(
    "manifest", "scenario_summary", "run_metrics", "accounting",
    "parentage_summary", "census", "events"
  )
  for (table in tables) {
    utils::write.csv(
      bundle[[table]],
      file.path(output_dir, paste0(table, ".csv")),
      row.names = FALSE,
      na = ""
    )
  }
  invisible(normalizePath(output_dir, mustWork = TRUE))
}

woodhen_run_all <- function(
    n_runs = NULL,
    parameters = woodhen_parameters(),
    workers = 1L) {
  woodhen_validate_parameters(parameters)
  if (!is.numeric(workers) || length(workers) != 1L || !is.finite(workers) ||
      workers < 1 || workers != floor(workers)) {
    stop("workers must be one positive integer", call. = FALSE)
  }
  workers <- as.integer(workers)
  scenario_ids <- woodhen_scenario_ids(parameters)
  results <- lapply(scenario_ids, function(scenario_id) {
    OpenPVA::run_scenario(woodhen_build_scenario(
      scenario_id,
      n_runs = n_runs,
      parameters = parameters
    ), parallel = workers > 1L, workers = workers)
  })
  names(results) <- scenario_ids
  results
}
