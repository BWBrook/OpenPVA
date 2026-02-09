expect_required_columns <- function(tbl, required) {
  testthat::expect_true(all(required %in% names(tbl)))
}

test_that("run_basic_simulation output schema contract is stable", {
  set.seed(1)
  out <- run_basic_simulation(
    initial_population = initialize_population(20),
    n_years = 4
  )

  expect_true(is.list(out))
  expect_true(all(c("population", "summary") %in% names(out)))
  expect_true(is.list(out$population))
  expect_s3_class(out$summary, "tbl_df")

  required_cols <- c(
    "year", "n_alive", "n_female_alive", "n_male_alive", "n_births",
    "n_harvested", "n_supplemented", "survival_scale", "env_surv_mult",
    "cat_surv_mult", "catastrophe", "env_repro_p_mult",
    "env_repro_lambda_mult", "cat_repro_mult", "repro_catastrophe"
  )
  expect_required_columns(out$summary, required_cols)

  expect_true(is.integer(out$summary$year))
  expect_true(is.integer(out$summary$n_alive))
  expect_true(is.double(out$summary$survival_scale))
  expect_true(is.logical(out$summary$catastrophe))
  expect_true(is.double(out$summary$env_repro_p_mult))
  expect_true(is.logical(out$summary$repro_catastrophe))
})

test_that("replicate and scenario output schema contracts are stable", {
  set.seed(2)
  reps <- run_basic_simulation_replicates(
    n_runs = 3,
    n_years = 5,
    init_fun = function() initialize_population(20)
  )

  expect_true(is.list(reps))
  expect_true(all(c("runs", "summary", "extinction") %in% names(reps)))
  expect_true(length(reps$runs) == 3L)
  expect_s3_class(reps$summary, "tbl_df")
  expect_s3_class(reps$extinction, "tbl_df")

  required_summary <- c(
    "run", "year", "n_alive", "n_female_alive", "n_male_alive", "n_births",
    "n_harvested", "n_supplemented", "survival_scale", "env_surv_mult",
    "cat_surv_mult", "catastrophe", "env_repro_p_mult",
    "env_repro_lambda_mult", "cat_repro_mult", "repro_catastrophe"
  )
  required_extinction <- c("run", "went_extinct", "time_to_extinction")
  expect_required_columns(reps$summary, required_summary)
  expect_required_columns(reps$extinction, required_extinction)

  expect_true(is.integer(reps$summary$run))
  expect_true(is.logical(reps$extinction$went_extinct))
  expect_true(is.integer(reps$extinction$time_to_extinction))

  sc <- scenario_spec(
    name = "schema_contract_demo",
    n_runs = 2,
    n_years = 4,
    init_fun = function() initialize_population(20)
  )
  out_sc <- run_scenario(sc)
  expect_true(is.list(out_sc))
  expect_true(all(c("scenario", "sim_output") %in% names(out_sc)))
  expect_s3_class(out_sc$scenario, "openpva_scenario")
  expect_true(is.list(out_sc$sim_output))
  expect_true(all(c("runs", "summary", "extinction") %in% names(out_sc$sim_output)))
})

test_that("summary helper output schemas are stable", {
  set.seed(3)
  reps <- run_basic_simulation_replicates(
    n_runs = 4,
    n_years = 6,
    init_fun = function() initialize_population(20)
  )

  ext <- summarise_extinction(reps)
  expect_s3_class(ext, "tbl_df")
  expect_required_columns(
    ext,
    c("n_runs", "p_extinct", "mean_time_to_extinction", "median_time_to_extinction")
  )
  expect_true(is.integer(ext$n_runs))
  expect_true(is.double(ext$p_extinct))

  traj <- compute_mean_trajectory(reps)
  expect_s3_class(traj, "tbl_df")
  expect_required_columns(traj, c("year", "mean_n_alive", "sd_n_alive", "p_extant"))
  expect_true(is.integer(traj$year))
  expect_true(is.double(traj$mean_n_alive))

  harvest <- summarise_harvest_yield(reps)
  expect_true(is.list(harvest))
  expect_true(all(c("per_run", "overall") %in% names(harvest)))
  expect_s3_class(harvest$per_run, "tbl_df")
  expect_s3_class(harvest$overall, "tbl_df")
  expect_required_columns(harvest$per_run, c("run", "total_harvest", "mean_annual_harvest"))
  expect_required_columns(
    harvest$overall,
    c("mean_total_harvest", "sd_total_harvest", "mean_mean_annual_harvest", "n_runs")
  )

  final_abundance <- summarise_final_abundance(reps, floor = 5)
  expect_true(is.list(final_abundance))
  expect_true(all(c("per_run", "overall") %in% names(final_abundance)))
  expect_s3_class(final_abundance$per_run, "tbl_df")
  expect_s3_class(final_abundance$overall, "tbl_df")
  expect_required_columns(
    final_abundance$per_run,
    c("run", "final_year", "final_n_alive", "min_n_alive")
  )
  expect_required_columns(
    final_abundance$overall,
    c(
      "n_runs",
      "floor_threshold",
      "mean_final_n_alive",
      "median_final_n_alive",
      "q05_final_n_alive",
      "q95_final_n_alive",
      "p_final_below_floor",
      "p_any_below_floor"
    )
  )

  reps_hist <- run_basic_simulation_replicates(
    n_runs = 3,
    n_years = 4,
    init_fun = function() {
      pop <- initialize_population(12)
      initialize_patches(pop, patch_ids = rep(c(1L, 2L), each = 6))
    },
    survival_fun = function(ind) 1,
    breeding_fun = function(ind) FALSE,
    fecundity_fun = function(ind) 0L,
    lifecycle_steps = c("age", "survival", "dispersal"),
    dispersal_fun = make_markov_dispersal_fun(
      matrix(c(0.9, 0.1, 0.2, 0.8), nrow = 2, byrow = TRUE)
    ),
    record_population_history = TRUE
  )

  occ_ts <- summarise_patch_occupancy_timeseries(reps_hist, n_patches = 2)
  expect_true(is.list(occ_ts))
  expect_required_columns(
    occ_ts$per_run,
    c("run", "year", "patch_id", "n_alive", "occupied", "alive_only")
  )
  expect_required_columns(
    occ_ts$overall,
    c("year", "patch_id", "n_runs", "mean_n_alive", "p_occupied", "n_extinct", "alive_only")
  )

  gen_ts <- summarise_patch_genetic_diversity_timeseries(reps_hist, n_patches = 2)
  expect_true(is.list(gen_ts))
  expect_required_columns(
    gen_ts$per_run,
    c("run", "year", "patch_id", "n_genotyped", "mean_heterozygosity", "mean_Fhat", "alive_only")
  )
  expect_required_columns(
    gen_ts$overall,
    c(
      "year", "patch_id", "n_runs", "mean_n_genotyped", "p_patch_genotyped",
      "mean_heterozygosity", "mean_Fhat", "alive_only"
    )
  )

  conn_ts <- summarise_patch_connectivity_timeseries(reps_hist, n_patches = 2)
  expect_true(is.list(conn_ts))
  expect_required_columns(
    conn_ts$transitions,
    c("run", "year_from", "year_to", "origin_patch", "destination_patch", "n_individuals", "alive_only")
  )
  expect_required_columns(
    conn_ts$transitions_overall,
    c(
      "origin_patch", "destination_patch", "mean_n_individuals",
      "total_n_individuals", "p_transition_given_origin", "alive_only"
    )
  )
  expect_required_columns(
    conn_ts$net_patch_change,
    c("run", "year", "patch_id", "n_alive", "alive_only", "delta_n_alive")
  )
  expect_required_columns(
    conn_ts$turnover,
    c("run", "year", "patch_id", "colonized", "extirpated", "alive_only")
  )
})

test_that("sensitivity diagnostic output schemas are stable", {
  sc <- scenario_spec(
    name = "sensitivity_schema_contract",
    n_runs = 8,
    n_years = 8,
    init_fun = function() initialize_population(30)
  )
  uncertainty_spec <- list(
    harvest_quota = list(dist = "uniform", min = 0, max = 5, integer = TRUE),
    cat_surv_prob = list(dist = "uniform", min = 0, max = 0.2)
  )

  ens <- run_scenario_ensemble(
    scenario = sc,
    uncertainty_spec = uncertainty_spec,
    n_draws = 10,
    seed = 404L
  )
  ens_summary <- summarise_ensemble_outputs(ens, final_n_floor = 8)

  prcc <- summarise_sensitivity_prcc(
    ensemble_data = ens_summary,
    response_col = "p_extinction"
  )
  expect_s3_class(prcc, "tbl_df")
  expect_required_columns(
    prcc,
    c("parameter", "prcc", "p_value", "n_obs", "n_controls", "abs_prcc")
  )

  oat <- summarise_sensitivity_oat(
    scenario = sc,
    oat_spec = list(
      harvest_quota = list(baseline = 2, delta = 1, lower = 0, upper = 6)
    ),
    metric_fun = function(sim_output) {
      summarise_final_abundance(sim_output)$overall$mean_final_n_alive
    },
    metric_name = "mean_final_n_alive",
    seed = 505L
  )
  expect_s3_class(oat, "tbl_df")
  expect_required_columns(
    oat,
    c(
      "parameter", "metric_name", "baseline_value", "low_value", "high_value",
      "baseline_metric", "low_metric", "high_metric", "local_slope",
      "elasticity", "pct_change_low", "pct_change_high"
    )
  )
})

test_that("calibration scaffold output schemas are stable", {
  observed <- c(mean_final_n_alive = 20, p_extinction = 0.1)
  simulated <- c(mean_final_n_alive = 18, p_extinction = 0.2)
  fit <- score_hindcast_fit(observed, simulated)
  expect_s3_class(fit, "tbl_df")
  expect_required_columns(fit, c("n_targets", "rmse", "mae", "bias", "mape"))

  parameter_space <- list(
    harvest_quota = list(lower = 0, upper = 4, integer = TRUE, n_grid = 3),
    cat_surv_prob = list(lower = 0, upper = 0.2, n_grid = 2)
  )
  candidates <- generate_calibration_candidates(parameter_space, method = "grid")
  expect_s3_class(candidates, "tbl_df")
  expect_required_columns(candidates, c("candidate_id", "harvest_quota", "cat_surv_prob"))

  sc <- scenario_spec(
    name = "calibration_schema_contract",
    n_runs = 4,
    n_years = 5,
    init_fun = function() initialize_population(22),
    seed = 909L
  )
  target_fun <- function(sim_output) {
    c(
      p_extinction = summarise_extinction(sim_output, threshold = 0)$p_extinct,
      mean_final_n_alive = summarise_final_abundance(sim_output)$overall$mean_final_n_alive
    )
  }
  observed_targets <- target_fun(run_scenario(sc)$sim_output)

  cal <- run_calibration_search(
    scenario = sc,
    candidates = dplyr::slice(candidates, 1:3),
    observed_targets = observed_targets,
    simulate_targets_fun = target_fun,
    seed = 909L
  )
  expect_true(is.list(cal))
  expect_true(all(c("scores", "best_fit", "observed_targets") %in% names(cal)))
  expect_s3_class(cal$scores, "tbl_df")
  expect_s3_class(cal$best_fit, "tbl_df")
  expect_s3_class(cal$observed_targets, "tbl_df")
  expect_required_columns(
    cal$scores,
    c(
      "candidate_id", "objective_score", "rmse", "mae", "bias", "mape",
      "sim_p_extinction", "sim_mean_final_n_alive",
      "error_p_extinction", "error_mean_final_n_alive"
    )
  )
})
