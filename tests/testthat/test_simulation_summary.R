test_that("summarise_extinction computes expected stats from summary", {
  summary_tbl <- tibble::tibble(
    run = c(rep(1, 5), rep(2, 5), rep(3, 4), rep(4, 4)),
    year = c(1:5, 1:5, 1:4, 1:4),
    n_alive = c(10, 9, 8, 7, 0,
                10, 9, 8, 7, 6,
                6, 3, 0, 0,
                5, 5, 5, 5),
    n_births = 0L,
    n_harvested = 0L,
    survival_scale = 1
  )
  sim_output <- list(summary = summary_tbl)
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
  summary_tbl <- tibble::tibble(
    run = rep(1:2, each = 3),
    year = rep(1:3, times = 2),
    n_alive = c(5, 5, 5, 6, 6, 6),
    n_births = 0L,
    n_harvested = 0L,
    survival_scale = 1
  )
  summary <- summarise_extinction(list(summary = summary_tbl))
  expect_equal(summary$p_extinct, 0)
  expect_true(is.na(summary$mean_time_to_extinction))
  expect_true(is.na(summary$median_time_to_extinction))
})

test_that("summarise_extinction falls back to extinction table when needed", {
  ext <- tibble::tibble(
    run = 1:2,
    went_extinct = c(TRUE, FALSE),
    time_to_extinction = c(2L, NA_integer_)
  )
  summary <- summarise_extinction(list(extinction = ext))
  expect_equal(summary$p_extinct, 0.5)
  expect_equal(summary$mean_time_to_extinction, 2)
})

test_that("summarise_extinction obeys quasi-extinction threshold", {
  summary_tbl <- tibble::tibble(
    run = rep(1:2, each = 4),
    year = rep(1:4, times = 2),
    n_alive = c(10, 6, 4, 3, 10, 9, 8, 7),
    n_births = 0L,
    n_harvested = 0L,
    survival_scale = 1
  )
  sim_output <- list(summary = summary_tbl)
  res_true <- summarise_extinction(sim_output, threshold = 0)
  res_quasi <- summarise_extinction(sim_output, threshold = 5)
  expect_true(res_quasi$p_extinct >= res_true$p_extinct)
  expect_equal(res_true$n_runs, res_quasi$n_runs)
})

test_that("summarise_harvest_yield aggregates per-run yields", {
  summary_tbl <- tibble::tibble(
    run = c(1, 1, 2, 2),
    year = c(1, 2, 1, 2),
    n_alive = c(10, 9, 8, 7),
    n_births = 0L,
    n_harvested = c(1L, 2L, 0L, 1L),
    survival_scale = 1
  )
  sim_output <- list(summary = summary_tbl)
  harvest <- summarise_harvest_yield(sim_output)
  expect_equal(nrow(harvest$per_run), 2L)
  expect_equal(harvest$per_run$total_harvest, c(3, 1))
  expect_equal(harvest$overall$n_runs, 2L)
  expect_equal(harvest$overall$mean_total_harvest, mean(c(3, 1)))
})

test_that("summarise_final_abundance aggregates per-run and overall metrics", {
  summary_tbl <- tibble::tibble(
    run = c(rep(1, 3), rep(2, 3)),
    year = rep(1:3, times = 2),
    n_alive = c(10L, 6L, 4L, 8L, 7L, 9L)
  )
  sim_output <- list(summary = summary_tbl)

  out <- summarise_final_abundance(sim_output, floor = 5)
  expect_true(is.list(out))
  expect_true(all(c("per_run", "overall") %in% names(out)))
  expect_equal(nrow(out$per_run), 2L)
  expect_equal(out$per_run$final_n_alive, c(4L, 9L))
  expect_equal(out$per_run$min_n_alive, c(4L, 7L))

  expect_equal(out$overall$n_runs, 2L)
  expect_equal(out$overall$floor_threshold, 5)
  expect_equal(out$overall$mean_final_n_alive, 6.5)
  expect_equal(out$overall$median_final_n_alive, 6.5)
  expect_equal(out$overall$p_final_below_floor, 0.5)
  expect_equal(out$overall$p_any_below_floor, 0.5)
  expect_equal(out$overall$q05_final_n_alive, 4.25, tolerance = 1e-8)
  expect_equal(out$overall$q95_final_n_alive, 8.75, tolerance = 1e-8)
})

test_that("summarise_final_abundance validates inputs", {
  expect_error(
    summarise_final_abundance(list(), floor = 0),
    "sim_output\\$summary is missing"
  )
  expect_error(
    summarise_final_abundance(list(summary = tibble::tibble(run = 1L, year = 1L)), floor = 0),
    "must contain columns run, year, n_alive"
  )
  expect_error(
    summarise_final_abundance(
      list(summary = tibble::tibble(run = 1L, year = 1L, n_alive = 1L)),
      floor = -1
    ),
    "floor must be a single non-negative numeric value"
  )
})
