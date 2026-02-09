test_that("compare_scenarios ranks harvest strategies", {
  make_harvest_scenario <- function(quota) {
    scenario_spec(
      name = paste0("harvest_", quota),
      n_runs = 5,
      n_years = 5,
      init_fun = function() initialize_population(6),
      survival_fun = function(ind) 1,
      breeding_fun = function(ind) TRUE,
      fecundity_fun = function(ind) 2L,
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

  harvest_low <- res$mean_total_harvest[res$scenario_name == "low"]
  harvest_high <- res$mean_total_harvest[res$scenario_name == "high"]
  expect_true(harvest_high >= harvest_low)

  p_ext_low <- res$p_extinction[res$scenario_name == "low"]
  p_ext_high <- res$p_extinction[res$scenario_name == "high"]
  expect_true(p_ext_high >= p_ext_low)
})
