test_that("summarise_extinction computes expected stats", {
  ext <- tibble::tibble(
    run = 1:4,
    went_extinct = c(TRUE, FALSE, TRUE, FALSE),
    time_to_extinction = c(5L, NA_integer_, 3L, NA_integer_)
  )
  sim_output <- list(extinction = ext)
  summary <- summarise_extinction(sim_output)
  expect_s3_class(summary, "tbl_df")
  expect_equal(summary$n_runs, 4L)
  expect_equal(summary$p_extinct, 0.5)
  expect_equal(summary$mean_time_to_extinction, 4)
  expect_equal(summary$median_time_to_extinction, 4)
})

test_that("compute_mean_trajectory summarises per year means", {
  summary_tbl <- tibble::tibble(
    run = c(1, 1, 2, 2),
    year = c(1, 2, 1, 2),
    n_alive = c(10, 8, 6, 4),
    n_births = c(2, 1, 1, 0),
    n_harvested = c(0, 0, 0, 0),
    survival_scale = c(1, 1, 1, 1)
  )
  sim_output <- list(summary = summary_tbl)
  traj <- compute_mean_trajectory(sim_output)
  expect_equal(nrow(traj), 2L)
  expect_equal(traj$year, c(1, 2))
  expect_equal(traj$mean_n_alive, c(8, 6))
  expect_equal(traj$p_extant, c(1, 1))
  expect_equal(traj$sd_n_alive[1], stats::sd(c(10, 6)))
  expect_equal(traj$sd_n_alive[2], stats::sd(c(8, 4)))
})

test_that("compute_mean_trajectory returns empty tibble for empty summary", {
  sim_output <- list(summary = tibble::tibble(
    run = integer(),
    year = integer(),
    n_alive = integer(),
    n_births = integer(),
    n_harvested = integer(),
    survival_scale = numeric()
  ))
  traj <- compute_mean_trajectory(sim_output)
  expect_equal(nrow(traj), 0L)
  expect_true(all(c("year", "mean_n_alive", "sd_n_alive", "p_extant") %in% names(traj)))
})

test_that("summarise_extinction returns NA stats when no extinctions", {
  ext <- tibble::tibble(
    run = 1:2,
    went_extinct = c(FALSE, FALSE),
    time_to_extinction = c(NA_integer_, NA_integer_)
  )
  summary <- summarise_extinction(list(extinction = ext))
  expect_equal(summary$p_extinct, 0)
  expect_true(is.na(summary$mean_time_to_extinction))
  expect_true(is.na(summary$median_time_to_extinction))
})
