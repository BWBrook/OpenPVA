test_that("the exact chain is a proper distribution with sensible limits", {
  design <- cohort_design()
  exact <- exact_cohort_chain(design)
  expect_equal(exact$mass, 1, tolerance = 1e-12)
  expect_gt(exact$p_ever_below, exact$p_below_at_horizon - 1e-12)
  expect_gt(exact$p_below_at_horizon, exact$p_extinct_at_horizon)

  certain <- design
  certain$s_f <- 0
  certain$s_m <- 0
  certain$release_year <- -1L
  expect_equal(exact_cohort_chain(certain)$p_extinct_at_horizon, 1)

  immortal <- design
  immortal$s_f <- 1
  immortal$s_m <- 1
  expect_equal(exact_cohort_chain(immortal)$p_ever_below, 0)
})

test_that("first-crossing and horizon probabilities match exact enumeration across a release", {
  design <- cohort_design()
  exact <- exact_cohort_chain(design)
  n_runs <- 6000L
  result <- run_scenario(
    cohort_scenario(design, n_runs = n_runs, seed = 4126L),
    validation = "fast", keep = "census"
  )
  summary <- summarise_pva(result, threshold = design$threshold)
  extinct <- summarise_pva(result, threshold = 1)
  expect_identical(summary$n_runs, n_runs)
  expect_identical(summary$horizon, design$years)

  # Prespecified tolerance: 3.5 exact binomial standard errors.
  within <- function(estimate, probability) {
    abs(estimate - probability) <= 3.5 * sqrt(probability * (1 - probability) / n_runs)
  }
  expect_true(within(summary$p_ever_below, exact$p_ever_below))
  expect_true(within(summary$p_below_at_horizon, exact$p_below_at_horizon))
  expect_true(within(extinct$p_below_at_horizon, exact$p_extinct_at_horizon))
  # The probabilities are far from 0 and 1, so the comparison has power.
  expect_gt(exact$p_ever_below, 0.2)
  expect_lt(exact$p_ever_below, 0.9)

  trajectory <- summarise_trajectory(result, include_initial = FALSE)
  expect_lt(max(abs(trajectory$mean - exact$expected_n) / trajectory$mcse), 3.5)

  # The release matters: without it the exact risk is clearly higher.
  unsupplemented <- design
  unsupplemented$release_year <- -1L
  expect_gt(
    exact_cohort_chain(unsupplemented)$p_ever_below - exact$p_ever_below,
    10 * sqrt(0.25 / n_runs)
  )
})
