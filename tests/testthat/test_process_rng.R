test_that("replicate streams and caller RNG state are restored on every exit", {
  scenario <- scenario_spec(
    name = "rng-contract",
    n_runs = 3L,
    n_steps = 2L,
    init_fun = function() make_test_population(),
    processes = list(constant_survival_process(), census_process()),
    seed = 4242L
  )

  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(91L)
  kind_before <- RNGkind()
  seed_before <- .Random.seed
  invisible(run_scenario(scenario))
  expect_identical(RNGkind(), kind_before)
  expect_identical(.Random.seed, seed_before)

  failing <- pva_process(
    "failing",
    function(state, context, params) stop("deliberate failure"),
    requires = "population.id"
  )
  scenario$processes <- list(failing)
  class(scenario) <- c("openpva_scenario", "list")
  expect_error(run_scenario(scenario), "deliberate failure")
  expect_identical(RNGkind(), kind_before)
  expect_identical(.Random.seed, seed_before)

  rm(".Random.seed", envir = .GlobalEnv)
  kind_without_seed <- RNGkind()
  scenario$processes <- list(constant_survival_process(), census_process())
  scenario$seed <- NULL
  class(scenario) <- c("openpva_scenario", "list")
  invisible(run_scenario(scenario))
  expect_identical(RNGkind(), kind_without_seed)
  expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
})
test_that("preassigned streams make serial and fork execution byte-identical", {
  skip_on_os("windows")
  processes <- list(
    age_process(),
    constant_survival_process(0.83),
    reproduction_process(
      breeding_probability = function(mother, state, context, params) 0.4,
      fecundity_mean = function(mother, state, context, params) 0.7,
      offspring_sex = function(mother, father, state, context, params) {
        sample(c("F", "M"), 1L)
      }
    ),
    census_process()
  )
  scenario <- scenario_spec(
    "parallel-identity",
    n_runs = 4L,
    n_steps = 3L,
    init_fun = function() make_test_population(10L),
    processes = processes,
    seed = 8801L,
    record_population_history = TRUE
  )

  serial <- run_scenario(scenario, parallel = FALSE)
  forked <- run_scenario(scenario, parallel = TRUE, workers = 2L)
  expect_identical(forked, serial)
})
