make_repro_test_population <- function() {
  list(
    create_individual(1L, "F", age = 5L),
    create_individual(2L, "M", age = 5L)
  )
}

test_that("controller reproduction pathway tracks reproduction summary fields", {
  out <- run_basic_simulation(
    initial_population = make_repro_test_population(),
    n_years = 3,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 0,
    lifecycle_steps = c("age", "survival", "breeding_births")
  )

  expect_true(all(out$summary$n_births == 0L))
  expect_true(all(out$summary$env_repro_p_mult == 1))
  expect_true(all(out$summary$env_repro_lambda_mult == 1))
  expect_true(all(out$summary$cat_repro_mult == 1))
  expect_true(all(out$summary$repro_catastrophe == FALSE))
})

test_that("reproduction EV and catastrophes are applied in controller pathway", {
  set.seed(20260504)
  out <- run_basic_simulation(
    initial_population = make_repro_test_population(),
    n_years = 5,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 2,
    lifecycle_steps = c("age", "survival", "breeding_births"),
    env_repro_p_sd = 0.2,
    env_repro_lambda_sd = 0.2,
    cat_repro_prob = 1,
    cat_repro_mult = 0.5
  )

  expect_true(all(out$summary$repro_catastrophe))
  expect_true(all(out$summary$cat_repro_mult == 0.5))
  expect_true(any(out$summary$env_repro_p_mult != 1))
  expect_true(any(out$summary$env_repro_lambda_mult != 1))
})

test_that("replicates with controller reproduction pathway are deterministic with seed", {
  out1 <- run_basic_simulation_replicates(
    n_runs = 4,
    n_years = 6,
    init_fun = make_repro_test_population,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 1.5,
    lifecycle_steps = c("age", "survival", "breeding_births"),
    env_repro_p_sd = 0.2,
    env_repro_lambda_sd = 0.2,
    cat_repro_prob = 0.3,
    cat_repro_mult = 0.5,
    seed = 9042L
  )
  out2 <- run_basic_simulation_replicates(
    n_runs = 4,
    n_years = 6,
    init_fun = make_repro_test_population,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 1.5,
    lifecycle_steps = c("age", "survival", "breeding_births"),
    env_repro_p_sd = 0.2,
    env_repro_lambda_sd = 0.2,
    cat_repro_prob = 0.3,
    cat_repro_mult = 0.5,
    seed = 9042L
  )

  expect_identical(out1$summary, out2$summary)
  expect_identical(out1$extinction, out2$extinction)
})

test_that("invalid controller reproduction rate outputs fail clearly", {
  expect_error(
    run_basic_simulation(
      initial_population = make_repro_test_population(),
      n_years = 1,
      survival_fun = function(ind) 1,
      breeding_prob_fun = function(ind) 2,
      fecundity_lambda_fun = function(ind) 1,
      lifecycle_steps = c("age", "survival", "breeding_births")
    ),
    "breeding_prob_fun"
  )

  expect_error(
    run_basic_simulation(
      initial_population = make_repro_test_population(),
      n_years = 1,
      survival_fun = function(ind) 1,
      breeding_prob_fun = function(ind) 1,
      fecundity_lambda_fun = function(ind) -1,
      lifecycle_steps = c("age", "survival", "breeding_births")
    ),
    "fecundity_lambda_fun"
  )
})

test_that("scenario_spec threads controller reproduction pathway arguments", {
  sc <- scenario_spec(
    name = "repro_controller_scenario",
    n_runs = 3,
    n_years = 4,
    init_fun = make_repro_test_population,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 0,
    lifecycle_steps = c("age", "survival", "breeding_births"),
    env_repro_p_sd = 0.1,
    env_repro_lambda_sd = 0.2,
    cat_repro_prob = 0.5,
    cat_repro_mult = 0.5
  )

  out <- run_scenario(sc)
  expect_true(all(out$sim_output$summary$n_births == 0L))
  expect_true(all(c(
    "env_repro_p_mult", "env_repro_lambda_mult",
    "cat_repro_mult", "repro_catastrophe"
  ) %in% names(out$sim_output$summary)))
})
