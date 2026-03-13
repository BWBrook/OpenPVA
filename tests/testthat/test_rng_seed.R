test_that("run_basic_simulation_replicates is deterministic for fixed seed", {
  init_fun <- function() initialize_population(30)

  out1 <- run_basic_simulation_replicates(
    n_runs = 6,
    n_years = 8,
    init_fun = init_fun,
    env_surv_sd = 0.25,
    cat_surv_prob = 0.2,
    cat_surv_mult = 0.4,
    seed = 20260208L
  )
  out2 <- run_basic_simulation_replicates(
    n_runs = 6,
    n_years = 8,
    init_fun = init_fun,
    env_surv_sd = 0.25,
    cat_surv_prob = 0.2,
    cat_surv_mult = 0.4,
    seed = 20260208L
  )

  expect_identical(out1$summary, out2$summary)
  expect_identical(out1$extinction, out2$extinction)
})

test_that("scenario and YAML seeding produce deterministic replicate outputs", {
  sc <- scenario_spec(
    name = "seeded_scenario",
    n_runs = 4,
    n_years = 6,
    init_fun = function() initialize_population(20),
    env_surv_sd = 0.2,
    cat_surv_prob = 0.1,
    cat_surv_mult = 0.5,
    seed = 12345L
  )

  out1 <- run_scenario(sc)
  out2 <- run_scenario(sc)
  expect_identical(out1$sim_output$summary, out2$sim_output$summary)
  expect_identical(out1$sim_output$extinction, out2$sim_output$extinction)

  yaml_text <- "
name: 'seeded_yaml'
schema_version: 3
n_runs: 3
n_years: 5
seed: 777
initializer:
  fun: 'initialize_population'
  args:
    'n': 20
env_surv_sd: 0.2
cat_surv_prob: 0.1
cat_surv_mult: 0.5
"
  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc_yaml <- read_scenario_yaml(tmp)
  expect_equal(sc_yaml$seed, 777L)

  yaml_out1 <- run_scenario(sc_yaml)
  yaml_out2 <- run_scenario(sc_yaml)
  expect_identical(yaml_out1$sim_output$summary, yaml_out2$sim_output$summary)
  expect_identical(yaml_out1$sim_output$extinction, yaml_out2$sim_output$extinction)
})

test_that("seeded replicate runs restore caller RNG state", {
  set.seed(424242)
  rng_before <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)

  invisible(run_basic_simulation_replicates(
    n_runs = 2,
    n_years = 2,
    init_fun = function() initialize_population(10),
    seed = 123L
  ))

  rng_after <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  expect_identical(rng_after, rng_before)
})

test_that("seeded replicate runs do not leave RNG state when absent on entry", {
  had_rng <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_rng) {
    rng_saved <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    rm(".Random.seed", envir = .GlobalEnv)
  }
  on.exit({
    if (had_rng) {
      assign(".Random.seed", rng_saved, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)

  expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))

  invisible(run_basic_simulation_replicates(
    n_runs = 2,
    n_years = 2,
    init_fun = function() initialize_population(10),
    seed = 222L
  ))

  expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
})

test_that("seed validation rejects non-integer values", {
  expect_error(
    run_basic_simulation_replicates(
      n_runs = 2,
      n_years = 2,
      init_fun = function() initialize_population(10),
      seed = 1.5
    ),
    "seed must be NULL or a single integer"
  )

  expect_error(
    scenario_spec(
      name = "bad_seed",
      n_runs = 1,
      n_years = 1,
      init_fun = function() initialize_population(5),
      seed = 3.14
    ),
    "seed must be NULL or a single integer"
  )

  yaml_bad_seed <- "
name: 'bad_yaml_seed'
schema_version: 3
n_runs: 1
n_years: 1
seed: 1.1
initializer:
  fun: 'initialize_population'
  args:
    'n': 5
"
  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_bad_seed, tmp)
  on.exit(unlink(tmp), add = TRUE)

  expect_error(read_scenario_yaml(tmp), "seed must be NULL or a single integer")
})
