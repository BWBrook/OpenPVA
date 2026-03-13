test_that("compare_scenarios ranks harvest strategies", {
  make_harvest_scenario <- function(quota) {
    scenario_spec(
      name = paste0("harvest_", quota),
      n_runs = 5,
      n_years = 5,
      init_fun = function() initialize_population(6),
      survival_fun = function(ind) 1,
      breeding_prob_fun = function(ind) 1,
      fecundity_lambda_fun = function(ind) 2,
      harvest_quota = quota,
      lifecycle_steps = default_lifecycle_steps()
    )
  }

  scenarios <- list(
    low = make_harvest_scenario(1),
    high = make_harvest_scenario(3)
  )

  set.seed(42)
  res <- compare_scenarios(scenarios, extinction_threshold = 0)
  expect_equal(nrow(res), 2L)
  expect_equal(res$scenario_name, c("low", "high"))
  expect_true(all(c(
    "final_n_floor",
    "mean_final_n_alive",
    "median_final_n_alive",
    "q05_final_n_alive",
    "q95_final_n_alive",
    "p_final_below_floor",
    "p_any_below_floor"
  ) %in% names(res)))
  expect_true(all(res$final_n_floor == 0))

  harvest_low <- res$mean_total_harvest[res$scenario_name == "low"]
  harvest_high <- res$mean_total_harvest[res$scenario_name == "high"]
  expect_true(harvest_high >= harvest_low)

  p_ext_low <- res$p_extinction[res$scenario_name == "low"]
  p_ext_high <- res$p_extinction[res$scenario_name == "high"]
  expect_true(p_ext_high >= p_ext_low)

  final_low <- res$mean_final_n_alive[res$scenario_name == "low"]
  final_high <- res$mean_final_n_alive[res$scenario_name == "high"]
  expect_true(final_high <= final_low)
})

test_that("compare_scenarios supports explicit final abundance floor", {
  sc <- scenario_spec(
    name = "floor_demo",
    n_runs = 4,
    n_years = 4,
    init_fun = function() initialize_population(5),
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 0,
    fecundity_lambda_fun = function(ind) 0
  )

  set.seed(101)
  res <- compare_scenarios(list(base = sc), extinction_threshold = 0, final_n_floor = 6)
  expect_equal(nrow(res), 1L)
  expect_equal(res$final_n_floor, 6)
  expect_equal(res$p_final_below_floor, 1)
  expect_equal(res$p_any_below_floor, 1)
})

test_that("compare_scenarios validates final_n_floor", {
  sc <- scenario_spec(
    name = "validation_demo",
    n_runs = 1,
    n_years = 1,
    init_fun = function() initialize_population(2)
  )

  expect_error(
    compare_scenarios(list(base = sc), final_n_floor = -1),
    "final_n_floor must be a single non-negative numeric value"
  )
})
