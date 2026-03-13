test_that("survival environmental variation and catastrophes affect outcomes", {
  pop <- initialize_population(n = 50, max_age = 2)
  steps <- c("age", "survival")

  res_none <- run_basic_simulation(
    initial_population = pop,
    n_years = 1,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 0,
    fecundity_lambda_fun = function(ind) 0,
    lifecycle_steps = steps,
    env_surv_sd = 0,
    cat_surv_prob = 0,
    cat_surv_mult = 1
  )

  expect_equal(res_none$summary$n_alive[1], length(pop))
  expect_equal(res_none$summary$env_surv_mult[1], 1)
  expect_equal(res_none$summary$cat_surv_mult[1], 1)
  expect_false(res_none$summary$catastrophe[1])

  set.seed(123)
  res_cat <- run_basic_simulation(
    initial_population = pop,
    n_years = 1,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 0,
    fecundity_lambda_fun = function(ind) 0,
    lifecycle_steps = steps,
    env_surv_sd = 0,
    cat_surv_prob = 1,
    cat_surv_mult = 0.1
  )

  expect_true(res_cat$summary$catastrophe[1])
  expect_equal(res_cat$summary$cat_surv_mult[1], 0.1)
  expect_true(res_cat$summary$n_alive[1] < length(pop))

  set.seed(123)
  res_env1 <- run_basic_simulation(
    initial_population = pop,
    n_years = 1,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 0,
    fecundity_lambda_fun = function(ind) 0,
    lifecycle_steps = steps,
    env_surv_sd = 0.5,
    cat_surv_prob = 0,
    cat_surv_mult = 1
  )

  set.seed(456)
  res_env2 <- run_basic_simulation(
    initial_population = pop,
    n_years = 1,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 0,
    fecundity_lambda_fun = function(ind) 0,
    lifecycle_steps = steps,
    env_surv_sd = 0.5,
    cat_surv_prob = 0,
    cat_surv_mult = 1
  )

  diff_mult <- abs(res_env1$summary$env_surv_mult[1] - res_env2$summary$env_surv_mult[1])
  expect_true(diff_mult > 1e-6)
})

test_that("scenario-level catastrophe parameters influence extinction risk", {
  init_fun <- function() initialize_population(50)

  sc_no_cat <- scenario_spec(
    name = "no_cat",
    n_runs = 10,
    n_years = 10,
    init_fun = init_fun,
    lifecycle_steps = c("age", "survival"),
    env_surv_sd = 0,
    cat_surv_prob = 0,
    cat_surv_mult = 1
  )

  sc_cat <- scenario_spec(
    name = "cat",
    n_runs = 10,
    n_years = 10,
    init_fun = init_fun,
    lifecycle_steps = c("age", "survival"),
    env_surv_sd = 0,
    cat_surv_prob = 0.3,
    cat_surv_mult = 0.2
  )

  set.seed(123)
  out_no_cat <- run_scenario(sc_no_cat)
  set.seed(123)
  out_cat <- run_scenario(sc_cat)

  ext_no_cat <- summarise_extinction(out_no_cat$sim_output)
  ext_cat <- summarise_extinction(out_cat$sim_output)

  expect_true(ext_cat$p_extinct >= ext_no_cat$p_extinct)
})
