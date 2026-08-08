test_that("one-interval stochastic mean agrees with an independent expectation oracle", {
  n_initial <- 20L
  n_runs <- 2000L
  survival_probability <- 0.8
  fecundity_lambda <- 0.5

  processes <- list(
    survival_process(
      probability = function(individual, state, context, params) params$survival,
      params = list(survival = survival_probability)
    ),
    reproduction_process(
      breeding_probability = function(mother, state, context, params) 1,
      fecundity_mean = function(mother, state, context, params) params$lambda,
      offspring_sex = function(mother, father, state, context, params) "F",
      params = list(lambda = fecundity_lambda)
    )
  )
  scenario <- scenario_spec(
    "synthetic-expectation",
    n_runs,
    1L,
    function() lapply(seq_len(n_initial), function(id) create_individual(id, "F", 4L)),
    processes,
    seed = 901L
  )
  output <- run_scenario(scenario)$sim_output
  final_counts <- vapply(output$runs, function(run) {
    sum(vapply(run$population, function(ind) isTRUE(ind$alive), logical(1)))
  }, integer(1))

  # Literal matched DGP: each initial female survives with probability s and,
  # conditional on survival, contributes herself plus Poisson(lambda) births.
  expected_per_individual <- survival_probability * (1 + fecundity_lambda)
  second_moment_per_individual <- survival_probability *
    (1 + 3 * fecundity_lambda + fecundity_lambda^2)
  variance_per_individual <- second_moment_per_individual - expected_per_individual^2
  expected_total <- n_initial * expected_per_individual
  monte_carlo_se <- sqrt(n_initial * variance_per_individual / n_runs)

  expect_lt(abs(mean(final_counts) - expected_total), 6 * monte_carlo_se)
})
