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
