test_that("score_hindcast_fit computes expected metrics", {
  observed <- c(mean_final_n_alive = 10, p_extinction = 5)
  simulated <- c(mean_final_n_alive = 8, p_extinction = 7)

  out <- score_hindcast_fit(observed, simulated)

  expect_s3_class(out, "tbl_df")
  expect_equal(out$n_targets, 2L)
  expect_equal(out$rmse, 2)
  expect_equal(out$mae, 2)
  expect_equal(out$bias, 0)
  expect_equal(out$mape, 0.3)
})

test_that("generate_calibration_candidates supports grid and seeded random methods", {
  parameter_space <- list(
    harvest_quota = list(lower = 0, upper = 4, integer = TRUE, n_grid = 3),
    cat_surv_prob = list(lower = 0, upper = 0.2, n_grid = 2)
  )

  grid <- generate_calibration_candidates(parameter_space, method = "grid")
  expect_equal(nrow(grid), 6L)
  expect_equal(grid$candidate_id, seq_len(6))
  expect_true(all(grid$harvest_quota %in% c(0, 2, 4)))
  expect_true(all(grid$cat_surv_prob %in% c(0, 0.2)))

  rand_a <- generate_calibration_candidates(
    parameter_space,
    method = "random",
    n_candidates = 7,
    seed = 2026L
  )
  rand_b <- generate_calibration_candidates(
    parameter_space,
    method = "random",
    n_candidates = 7,
    seed = 2026L
  )
  expect_equal(rand_a, rand_b)
})

test_that("run_calibration_search is reproducible and finds known best candidate", {
  sc <- scenario_spec(
    name = "calibration_search",
    n_runs = 6,
    n_years = 6,
    init_fun = function() initialize_population(25),
    seed = 808L
  )
  target_fun <- function(sim_output) {
    c(
      p_extinction = summarise_extinction(sim_output, threshold = 0)$p_extinct,
      mean_final_n_alive = summarise_final_abundance(sim_output)$overall$mean_final_n_alive
    )
  }

  sc_true <- sc
  sc_true$harvest_quota <- 2
  sc_true <- OpenPVA:::.validate_scenario(sc_true)
  class(sc_true) <- c("openpva_scenario", "list")
  observed_targets <- target_fun(run_scenario(sc_true)$sim_output)

  candidates <- tibble::tibble(
    candidate_id = 1:3,
    harvest_quota = c(1, 2, 3)
  )

  out_a <- run_calibration_search(
    scenario = sc,
    candidates = candidates,
    observed_targets = observed_targets,
    simulate_targets_fun = target_fun,
    seed = 808L
  )
  out_b <- run_calibration_search(
    scenario = sc,
    candidates = candidates,
    observed_targets = observed_targets,
    simulate_targets_fun = target_fun,
    seed = 808L
  )

  expect_s3_class(out_a, "openpva_calibration_result")
  expect_equal(out_a$scores, out_b$scores)
  expect_equal(out_a$best_fit$harvest_quota, 2)
  expect_lt(abs(out_a$best_fit$objective_score), 1e-12)
})
