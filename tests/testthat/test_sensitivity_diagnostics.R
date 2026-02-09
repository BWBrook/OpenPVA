test_that("summarise_sensitivity_prcc captures directional toy signals", {
  draw_tbl <- tibble::tibble(
    draw_id = seq_len(30),
    param_a = rep(seq(0.05, 0.95, length.out = 10), 3),
    param_b = rep(c(0.1, 0.5, 0.9), each = 10)
  )
  draw_tbl$response <- 1.5 * draw_tbl$param_a - 0.8 * draw_tbl$param_b

  out <- summarise_sensitivity_prcc(
    ensemble_data = draw_tbl,
    response_col = "response",
    parameter_cols = c("param_a", "param_b")
  )

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2L)
  expect_true(out$prcc[out$parameter == "param_a"] > 0)
  expect_true(out$prcc[out$parameter == "param_b"] < 0)
  expect_true(all(out$abs_prcc >= 0))
})

test_that("summarise_sensitivity_prcc accepts summary-list input", {
  per_draw <- tibble::tibble(
    draw_id = seq_len(8),
    p_extinction = c(0.1, 0.2, 0.1, 0.35, 0.4, 0.5, 0.3, 0.45),
    harvest_quota = c(0, 1, 1, 2, 3, 4, 2, 3),
    cat_surv_prob = c(0.01, 0.03, 0.02, 0.06, 0.08, 0.1, 0.05, 0.09)
  )

  out <- summarise_sensitivity_prcc(
    ensemble_data = list(per_draw = per_draw),
    response_col = "p_extinction"
  )
  expect_equal(nrow(out), 2L)
  expect_true(all(c("parameter", "prcc", "p_value") %in% names(out)))
})

test_that("summarise_sensitivity_prcc infers uncertainty parameters from ensemble output", {
  sc <- scenario_spec(
    name = "prcc_infer_params",
    n_runs = 5,
    n_years = 6,
    init_fun = function() initialize_population(24)
  )
  uncertainty_spec <- list(
    harvest_quota = list(dist = "uniform", min = 0, max = 4, integer = TRUE),
    cat_surv_prob = list(dist = "uniform", min = 0, max = 0.2)
  )
  ens <- run_scenario_ensemble(
    scenario = sc,
    uncertainty_spec = uncertainty_spec,
    n_draws = 12,
    seed = 606L
  )

  out <- summarise_sensitivity_prcc(ens, response_col = "p_extinction")
  expect_equal(sort(out$parameter), sort(names(uncertainty_spec)))
})

test_that("summarise_sensitivity_oat returns expected harvest direction", {
  sc <- scenario_spec(
    name = "oat_harvest_direction",
    n_runs = 10,
    n_years = 8,
    init_fun = function() initialize_population(30),
    seed = 5150L
  )

  out <- summarise_sensitivity_oat(
    scenario = sc,
    oat_spec = list(
      harvest_quota = list(
        baseline = 2,
        delta = 1,
        lower = 0,
        upper = 6
      )
    ),
    metric_fun = function(sim_output) {
      summarise_final_abundance(sim_output)$overall$mean_final_n_alive
    },
    metric_name = "mean_final_n_alive",
    seed = 909L
  )

  expect_equal(nrow(out), 1L)
  expect_equal(out$low_value, 1)
  expect_equal(out$high_value, 3)
  expect_true(out$high_metric <= out$low_metric)
  expect_true(out$local_slope < 0)
})

test_that("summarise_sensitivity_oat validates oat_spec parameter names", {
  sc <- scenario_spec(
    name = "oat_validation",
    n_runs = 2,
    n_years = 3,
    init_fun = function() initialize_population(12)
  )

  expect_error(
    summarise_sensitivity_oat(
      scenario = sc,
      oat_spec = list(
        not_a_param = list(baseline = 1, delta = 0.2)
      )
    ),
    "unknown scenario parameter"
  )
})
