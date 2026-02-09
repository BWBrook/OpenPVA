test_that("sample_uncertainty_parameters is deterministic with seed", {
  spec <- list(
    cat_surv_prob = list(
      dist = "uniform",
      min = 0,
      max = 0.3
    ),
    harvest_quota = list(
      dist = "normal",
      mean = 4,
      sd = 1,
      lower = 0,
      integer = TRUE
    )
  )

  a <- sample_uncertainty_parameters(spec, n_draws = 6, seed = 101L)
  b <- sample_uncertainty_parameters(spec, n_draws = 6, seed = 101L)

  expect_equal(a, b)
  expect_true(all(a$cat_surv_prob >= 0 & a$cat_surv_prob <= 0.3))
  expect_true(all(a$harvest_quota == as.integer(a$harvest_quota)))
})

test_that("run_scenario_ensemble applies sampled parameters and is reproducible", {
  sc <- scenario_spec(
    name = "ensemble_repro",
    n_runs = 4,
    n_years = 8,
    init_fun = function() initialize_population(30),
    harvest_quota = 0
  )

  spec <- list(
    harvest_quota = list(
      dist = "uniform",
      min = 0,
      max = 6,
      integer = TRUE
    ),
    cat_surv_prob = list(
      dist = "uniform",
      min = 0,
      max = 0.25
    )
  )

  out1 <- run_scenario_ensemble(
    scenario = sc,
    uncertainty_spec = spec,
    n_draws = 4,
    seed = 20260210L
  )
  out2 <- run_scenario_ensemble(
    scenario = sc,
    uncertainty_spec = spec,
    n_draws = 4,
    seed = 20260210L
  )

  expect_s3_class(out1, "openpva_ensemble_output")
  expect_equal(out1$sampled_parameters, out2$sampled_parameters)

  for (i in seq_len(4)) {
    expect_equal(
      out1$draw_results[[i]]$scenario$harvest_quota,
      out1$sampled_parameters$harvest_quota[[i]]
    )
    expect_equal(
      out1$draw_results[[i]]$scenario$cat_surv_prob,
      out1$sampled_parameters$cat_surv_prob[[i]]
    )
    expect_equal(
      out1$draw_results[[i]]$sim_output$summary,
      out2$draw_results[[i]]$sim_output$summary
    )
  }
})

test_that("run_scenario_ensemble restores caller RNG state when seeded", {
  sc <- scenario_spec(
    name = "ensemble_rng",
    n_runs = 2,
    n_years = 5,
    init_fun = function() initialize_population(20)
  )
  spec <- list(
    cat_surv_prob = list(dist = "uniform", min = 0, max = 0.1)
  )

  set.seed(424242)
  rng_before <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)

  invisible(run_scenario_ensemble(
    scenario = sc,
    uncertainty_spec = spec,
    n_draws = 3,
    seed = 77L
  ))

  rng_after <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  expect_equal(rng_before, rng_after)
})

test_that("summarise_ensemble_outputs returns expected schema", {
  sc <- scenario_spec(
    name = "ensemble_summary",
    n_runs = 3,
    n_years = 6,
    init_fun = function() initialize_population(25)
  )
  spec <- list(
    harvest_quota = list(
      dist = "uniform",
      min = 0,
      max = 4,
      integer = TRUE
    )
  )

  out <- run_scenario_ensemble(
    scenario = sc,
    uncertainty_spec = spec,
    n_draws = 3,
    seed = 909L
  )
  summary <- summarise_ensemble_outputs(
    out,
    extinction_threshold = 0,
    final_n_floor = 5
  )

  expect_named(summary, c("per_draw", "overall"))
  expect_s3_class(summary$per_draw, "tbl_df")
  expect_s3_class(summary$overall, "tbl_df")
  expect_equal(nrow(summary$per_draw), 3L)
  expect_equal(nrow(summary$overall), 1L)
  expect_true(all(c(
    "draw_id",
    "p_extinction",
    "mean_final_n_alive",
    "p_final_below_floor",
    "harvest_quota"
  ) %in% names(summary$per_draw)))
  expect_true(all(c(
    "n_draws",
    "extinction_threshold",
    "final_n_floor",
    "mean_p_extinction",
    "sd_p_extinction"
  ) %in% names(summary$overall)))
})

test_that("run_scenario_ensemble validates uncertainty parameter names", {
  sc <- scenario_spec(
    name = "ensemble_bad_param",
    n_runs = 2,
    n_years = 4,
    init_fun = function() initialize_population(15)
  )
  bad_spec <- list(
    does_not_exist = list(dist = "fixed", value = 1)
  )

  expect_error(
    run_scenario_ensemble(sc, bad_spec, n_draws = 2),
    "Unknown uncertainty parameter"
  )
})

test_that("run_scenario_ensemble requires uncertainty from argument or scenario", {
  sc <- scenario_spec(
    name = "ensemble_missing_uncertainty",
    n_runs = 2,
    n_years = 4,
    init_fun = function() initialize_population(15)
  )

  expect_error(
    run_scenario_ensemble(sc, n_draws = 2),
    "uncertainty_spec must be supplied either as a function argument or scenario field"
  )

  sc$uncertainty_spec <- list(
    cat_surv_prob = list(dist = "fixed", value = 0.1)
  )
  out <- run_scenario_ensemble(
    scenario = sc,
    n_draws = 2,
    seed = 808L
  )
  expect_s3_class(out, "openpva_ensemble_output")
  expect_equal(nrow(out$sampled_parameters), 2L)
})

test_that("run_scenario_ensemble parallel execution matches serial under seed", {
  testthat::skip_on_os("windows")

  sc <- scenario_spec(
    name = "ensemble_parallel_match",
    n_runs = 4,
    n_years = 7,
    init_fun = function() initialize_population(25)
  )
  spec <- list(
    harvest_quota = list(dist = "uniform", min = 0, max = 5, integer = TRUE),
    cat_surv_prob = list(dist = "uniform", min = 0, max = 0.15)
  )

  serial <- run_scenario_ensemble(
    scenario = sc,
    uncertainty_spec = spec,
    n_draws = 4,
    seed = 707L,
    parallel = FALSE
  )
  parallel <- run_scenario_ensemble(
    scenario = sc,
    uncertainty_spec = spec,
    n_draws = 4,
    seed = 707L,
    parallel = TRUE,
    n_cores = 2L
  )

  expect_equal(serial$sampled_parameters, parallel$sampled_parameters)
  for (i in seq_len(4)) {
    expect_equal(
      serial$draw_results[[i]]$sim_output$summary,
      parallel$draw_results[[i]]$sim_output$summary
    )
  }
})
