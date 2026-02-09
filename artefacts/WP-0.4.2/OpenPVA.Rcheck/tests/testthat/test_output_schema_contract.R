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
    "cat_surv_mult", "catastrophe"
  )
  expect_required_columns(out$summary, required_cols)

  expect_true(is.integer(out$summary$year))
  expect_true(is.integer(out$summary$n_alive))
  expect_true(is.double(out$summary$survival_scale))
  expect_true(is.logical(out$summary$catastrophe))
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
    "cat_surv_mult", "catastrophe"
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
})
