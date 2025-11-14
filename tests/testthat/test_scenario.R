test_that("scenario_spec creates validated objects", {
  init_fun <- function() {
    list(
      create_individual(1L, "F", 2L),
      create_individual(2L, "M", 3L)
    )
  }
  survival_fun <- function(ind) 1
  breeding_fun <- function(ind) TRUE
  fecundity_fun <- function(ind) 0L

  sc <- scenario_spec(
    name = "test_scenario",
    n_runs = 3,
    n_years = 2,
    init_fun = init_fun,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun
  )

  expect_true(inherits(sc, "openpva_scenario"))
  expect_equal(sc$name, "test_scenario")
  expect_equal(sc$n_runs, 3L)
  expect_equal(sc$n_years, 2L)
  expect_equal(sc$lifecycle_steps, default_lifecycle_steps())

  res <- run_scenario(sc)
  expect_named(res, c("scenario", "sim_output"))
  expect_equal(res$scenario, sc)
  expect_equal(nrow(res$sim_output$summary), 6L)
  expect_true(all(res$sim_output$summary$n_alive == 2L))
})

test_that("read_scenario_yaml loads YAML configs", {
  yaml_text <- "name: 'yaml_demo'
n_runs: 2
n_years: 3
initializer:
  fun: 'initialize_population'
  args:
    'n': 4
survival_fun: 'default_survival_fun'
breeding_fun: 'default_breeding_fun'
fecundity_fun: 'default_fecundity_fun'
K: 10
harvest_quota: 0
lifecycle_steps:
  - age
  - survival
  - breeding_births
  - harvest
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp))

  sc <- read_scenario_yaml(tmp)
  expect_true(inherits(sc, "openpva_scenario"))
  expect_equal(sc$name, "yaml_demo")
  expect_equal(sc$n_runs, 2L)
  expect_equal(sc$n_years, 3L)
  expect_equal(sc$K, 10)
  expect_equal(sc$harvest_quota, 0)
  expect_equal(sc$lifecycle_steps, default_lifecycle_steps())

  res <- run_scenario(sc)
  expect_equal(nrow(res$sim_output$summary), 6L)
})
