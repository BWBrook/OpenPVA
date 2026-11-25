test_that("multi-year stochastic means match the independent matrix expectation", {
  rates <- oracle_rates()
  n_steps <- 8L
  n_runs <- 1500L
  result <- run_scenario(
    oracle_scenario(rates, n_runs = n_runs, n_steps = n_steps, seed = 20261124L),
    validation = "fast", keep = "census"
  )
  projection <- oracle_matrix(rates)
  expected <- matrix(NA_real_, n_steps, 3L, dimnames = list(NULL, c("n_alive", "n_female", "n_male")))
  vector <- c(rates$initial$F, rates$initial$M)
  for (step in seq_len(n_steps)) {
    vector <- as.vector(projection %*% vector)
    expected[step, ] <- c(sum(vector), sum(vector[1:3]), sum(vector[4:6]))
  }
  # The projection is not trivial: the population more than doubles.
  expect_gt(expected[n_steps, "n_alive"], 2 * sum(unlist(rates$initial)))

  z <- matrix(NA_real_, n_steps, 3L)
  for (column in 1:3) {
    metric <- colnames(expected)[[column]]
    trajectory <- summarise_trajectory(result, metric = metric, include_initial = FALSE)
    expect_identical(trajectory$year, seq_len(n_steps))
    z[, column] <- (trajectory$mean - expected[, column]) / trajectory$mcse
  }
  expect_lt(max(abs(z)), 3)
})

test_that("the matrix oracle detects a wrong census position", {
  rates <- oracle_rates()
  scenario <- oracle_scenario(rates, n_runs = 600L, n_steps = 4L, seed = 3L)
  # Moving the census before reproduction changes what is counted; the oracle
  # for the declared order must reject it.
  scenario$processes <- scenario$processes[c(1L, 2L, 4L, 3L)]
  result <- run_scenario(scenario, validation = "fast", keep = "census")
  vector <- c(rates$initial$F, rates$initial$M)
  for (step in 1:4) {
    vector <- as.vector(oracle_matrix(rates) %*% vector)
  }
  trajectory <- summarise_trajectory(result, include_initial = FALSE)
  expect_gt(abs(trajectory$mean[[4L]] - sum(vector)) / trajectory$mcse[[4L]], 10)
})
