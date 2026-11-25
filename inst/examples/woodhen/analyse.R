woodhen_run_all <- function(
    n_runs = NULL,
    parameters = woodhen_parameters(),
    workers = 1L,
    pedigree = FALSE,
    backend = "auto") {
  scenario_ids <- parameters$scenarios$scenario_id
  results <- lapply(scenario_ids, function(scenario_id) {
    OpenPVA::run_scenario(
      woodhen_build_scenario(
        scenario_id, n_runs = n_runs, parameters = parameters, pedigree = pedigree
      ),
      parallel = workers > 1L,
      workers = workers,
      backend = backend,
      keep = c("census", "events", "accounting", "state")
    )
  })
  names(results) <- scenario_ids
  results
}

woodhen_prepare_bundle <- function(results, parameters) {
  tag <- function(scenario_id, table) {
    cbind(scenario_id = scenario_id, table, stringsAsFactors = FALSE)
  }
  bind <- function(tables) {
    out <- do.call(rbind, tables)
    rownames(out) <- NULL
    out
  }
  scenario_summary <- bind(lapply(names(results), function(scenario_id) {
    result <- results[[scenario_id]]
    pairs <- OpenPVA::summarise_pva(
      result,
      metric = "n_potential_pairs",
      threshold = parameters$quasi_extinction_pairs,
      include_initial = FALSE
    )
    abundance <- OpenPVA::summarise_pva(result, metric = "n_alive", threshold = 1)
    data.frame(
      scenario_id = scenario_id,
      n_runs = pairs$n_runs,
      horizon = pairs$horizon,
      p_extinct = abundance$p_below_at_horizon,
      p_extinct_mcse = abundance$p_below_at_horizon_mcse,
      p_ever_below_pairs = pairs$p_ever_below,
      p_ever_below_pairs_mcse = pairs$p_ever_below_mcse,
      final_mean = abundance$final_mean,
      final_mcse = abundance$final_mcse,
      final_q05 = abundance$final_q05,
      final_median = abundance$final_median,
      final_q95 = abundance$final_q95,
      stringsAsFactors = FALSE
    )
  }))
  accounting <- bind(lapply(names(results), function(scenario_id) {
    table <- OpenPVA::summarise_accounting(results[[scenario_id]])
    table$removals <- table$removals_resident + table$removals_born +
      table$removals_introduced
    tag(scenario_id, table)
  }))
  if (!all(accounting$reconciled)) {
    stop("Woodhen accounting did not reconcile", call. = FALSE)
  }
  pedigree <- bind(lapply(names(results), function(scenario_id) {
    states <- results[[scenario_id]]$states
    bind(lapply(seq_along(states), function(run) {
      state <- states[[run]]
      summary <- if (is.null(state$kinship)) {
        data.frame(
          n_living = length(state$population$id),
          n_founders = NA_integer_, mean_inbreeding = NA_real_,
          max_inbreeding = NA_real_, mean_kinship = NA_real_,
          gene_diversity = NA_real_
        )
      } else {
        OpenPVA::summarise_pedigree(state)
      }
      cbind(scenario_id = scenario_id, run = run, summary, stringsAsFactors = FALSE)
    }))
  }))
  manifest <- data.frame(
    field = c(
      "model_id", "model_version", "openpva_version", "r_version",
      "scenarios", "n_runs", "root_seeds", "provenance"
    ),
    value = c(
      parameters$model_id,
      parameters$model_version,
      results[[1L]]$provenance$package_version,
      results[[1L]]$provenance$r_version,
      paste(names(results), collapse = ";"),
      paste(vapply(results, function(x) x$scenario$n_runs, integer(1)), collapse = ";"),
      paste(vapply(results, function(x) x$provenance$root_seed, integer(1)), collapse = ";"),
      "inherited teaching reconstruction; see parameter-evidence.csv"
    ),
    stringsAsFactors = FALSE
  )
  list(
    manifest = manifest,
    scenario_summary = scenario_summary,
    accounting = accounting,
    pedigree = pedigree,
    census = bind(lapply(names(results), function(scenario_id) {
      tag(scenario_id, results[[scenario_id]]$census)
    })),
    events = bind(lapply(names(results), function(scenario_id) {
      tag(scenario_id, results[[scenario_id]]$events)
    })),
    results = results
  )
}

woodhen_write_bundle <- function(bundle, output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  for (table in c(
    "manifest", "scenario_summary", "accounting", "pedigree", "census", "events"
  )) {
    utils::write.csv(
      bundle[[table]],
      file.path(output_dir, paste0(table, ".csv")),
      row.names = FALSE
    )
  }
  saveRDS(bundle$results, file.path(output_dir, "result.rds"))
  invisible(output_dir)
}
