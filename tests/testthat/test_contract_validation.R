test_that("scenario counts and quotas require finite integer inputs", {
  scenario_args <- list(
    name = "contract_validation",
    n_runs = 2L,
    n_years = 2L,
    init_fun = function() initialize_population(4)
  )

  expect_error(
    do.call(scenario_spec, modifyList(scenario_args, list(n_runs = 1.5))),
    "n_runs"
  )
  expect_error(
    do.call(scenario_spec, modifyList(scenario_args, list(n_years = Inf))),
    "n_years"
  )
  expect_error(
    do.call(scenario_spec, modifyList(scenario_args, list(harvest_quota = 1.5))),
    "harvest_quota"
  )
  expect_error(
    do.call(
      scenario_spec,
      modifyList(scenario_args, list(supplement_quota = c(0L, NaN)))
    ),
    "supplement_quota"
  )

  valid <- do.call(
    scenario_spec,
    modifyList(
      scenario_args,
      list(harvest_quota = 1L, supplement_quota = c(0L, 1L))
    )
  )
  expect_equal(valid$harvest_quota, 1L)
  expect_equal(valid$supplement_quota, c(0L, 1L))
})

test_that("simulation inputs reject fractional counts and non-finite multipliers", {
  initial_population <- list(
    create_individual(1L, "F", age = 5L),
    create_individual(2L, "M", age = 5L)
  )
  init_fun <- function() initial_population

  expect_error(
    run_basic_simulation(initial_population, n_years = 1.5),
    "n_years"
  )
  expect_error(
    run_basic_simulation_replicates(n_runs = 1.5, n_years = 1L, init_fun = init_fun),
    "n_runs"
  )
  expect_error(
    run_basic_simulation_replicates(n_runs = 1L, n_years = Inf, init_fun = init_fun),
    "n_years"
  )
  expect_error(
    run_basic_simulation(initial_population, n_years = 1L, harvest_quota = 1.5),
    "harvest_quota"
  )
  expect_error(
    run_basic_simulation(initial_population, n_years = 1L, supplement_quota = 1.5),
    "supplement_quota"
  )
  expect_error(
    run_basic_simulation(initial_population, n_years = 1L, cat_repro_mult = Inf),
    "cat_repro_mult"
  )
})

test_that("direct quota helpers reject fractional values", {
  population <- initialize_population(4)

  expect_error(apply_harvest_quota(population, 1.5), "n_remove")
  expect_error(apply_supplementation(population, 1.5), "n_add")
})

test_that("fecundity lambda outputs must be finite", {
  initial_population <- list(
    create_individual(1L, "F", age = 5L),
    create_individual(2L, "M", age = 5L)
  )

  expect_error(
    run_basic_simulation(
      initial_population = initial_population,
      n_years = 1L,
      survival_fun = function(ind) 1,
      breeding_prob_fun = function(ind) 1,
      fecundity_lambda_fun = function(ind) Inf,
      lifecycle_steps = c("age", "survival", "breeding_births")
    ),
    "fecundity_lambda_fun"
  )
})

test_that("fecundity lambda tables reject non-finite values", {
  tbl <- data.frame(
    age_min = 0,
    age_max = Inf,
    sex = "F",
    lambda = Inf
  )

  expect_error(validate_fecundity_lambda_table(tbl), "lambda")
})

test_that("seeded uncertainty and calibration draws restore caller RNG state", {
  uncertainty_spec <- list(
    cat_surv_prob = list(dist = "uniform", min = 0, max = 0.2)
  )
  parameter_space <- list(
    harvest_quota = list(lower = 0, upper = 4, integer = TRUE)
  )

  set.seed(1001L)
  rng_before_uncertainty <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  draws_a <- sample_uncertainty_parameters(uncertainty_spec, n_draws = 4L, seed = 77L)
  expect_identical(
    rng_before_uncertainty,
    get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  )

  set.seed(1002L)
  rng_before_calibration <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  candidates_a <- generate_calibration_candidates(
    parameter_space,
    method = "random",
    n_candidates = 4L,
    seed = 78L
  )
  expect_identical(
    rng_before_calibration,
    get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  )

  expect_identical(
    draws_a,
    sample_uncertainty_parameters(uncertainty_spec, n_draws = 4L, seed = 77L)
  )
  expect_identical(
    candidates_a,
    generate_calibration_candidates(
      parameter_space,
      method = "random",
      n_candidates = 4L,
      seed = 78L
    )
  )
})
