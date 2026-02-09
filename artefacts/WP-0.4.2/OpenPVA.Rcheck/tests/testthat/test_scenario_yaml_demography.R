test_that("legacy YAML with function names still works", {
  yaml_text <- "
name: 'yaml_legacy'
n_runs: 2
n_years: 3
initializer:
  fun: 'initialize_population'
  args:
    \"n\": 10
survival_fun: 'default_survival_fun'
breeding_fun: 'default_breeding_fun'
fecundity_fun: 'default_fecundity_fun'
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc <- read_scenario_yaml(tmp)
  expect_true(inherits(sc, "openpva_scenario"))
  expect_equal(attr(sc, "yaml_schema_version"), 1L)

  set.seed(123)
  out <- run_scenario(sc)
  expect_true(is.list(out$sim_output))
  expect_true(nrow(out$sim_output$summary) > 0)
})

test_that("schema_version 1 YAML is accepted and tracked", {
  yaml_text <- "
name: 'yaml_v1'
schema_version: 1
n_runs: 1
n_years: 2
initializer:
  fun: 'initialize_population'
  args:
    \"n\": 8
survival_fun: 'default_survival_fun'
breeding_fun: 'default_breeding_fun'
fecundity_fun: 'default_fecundity_fun'
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc <- read_scenario_yaml(tmp)
  expect_true(inherits(sc, "openpva_scenario"))
  expect_equal(attr(sc, "yaml_schema_version"), 1L)
})

test_that("unknown or invalid schema_version fails with clear errors", {
  yaml_future <- "
name: 'yaml_future'
schema_version: 2
n_runs: 1
n_years: 1
initializer:
  fun: 'initialize_population'
  args:
    \"n\": 5
survival_fun: 'default_survival_fun'
breeding_fun: 'default_breeding_fun'
fecundity_fun: 'default_fecundity_fun'
"

  tmp_future <- tempfile(fileext = ".yaml")
  writeLines(yaml_future, tmp_future)
  on.exit(unlink(tmp_future), add = TRUE)

  expect_error(
    read_scenario_yaml(tmp_future),
    "Unsupported schema_version"
  )

  yaml_bad_type <- "
name: 'yaml_bad_version'
schema_version: 'one'
n_runs: 1
n_years: 1
initializer:
  fun: 'initialize_population'
  args:
    \"n\": 5
survival_fun: 'default_survival_fun'
breeding_fun: 'default_breeding_fun'
fecundity_fun: 'default_fecundity_fun'
"

  tmp_bad <- tempfile(fileext = ".yaml")
  writeLines(yaml_bad_type, tmp_bad)
  on.exit(unlink(tmp_bad), add = TRUE)

  expect_error(
    read_scenario_yaml(tmp_bad),
    "schema_version must be a non-negative integer"
  )
})

test_that("demography block overrides survival function", {
  yaml_text <- "
name: 'yaml_demo_demography_override'
schema_version: 1
n_runs: 1
n_years: 1
initializer:
  fun: 'initialize_population'
  args:
    \"n\": 5
survival_fun: 'default_survival_fun'
breeding_fun: 'default_breeding_fun'
fecundity_fun: 'default_fecundity_fun'
demography:
  survival:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 0
        p_surv: 0.1
      - sex: 'F'
        age_min: 1
        age_max: 100
        p_surv: 0.1
      - sex: 'M'
        age_min: 0
        age_max: 100
        p_surv: 0.1
K: 100
lifecycle_steps:
  - age
  - survival
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc <- read_scenario_yaml(tmp)
  expect_true(inherits(sc, "openpva_scenario"))
  expect_equal(attr(sc, "yaml_schema_version"), 1L)

  ind <- create_individual(1L, "F", age = 0L)
  expect_equal(sc$survival_fun(ind), 0.1)
  expect_equal(default_survival_fun(ind), 0.85)

  set.seed(42)
  out <- run_scenario(sc)
  expect_equal(out$scenario$K, 100)
})

test_that("demo_demography YAML parses tables and EV/cat parameters", {
  path <- system.file("extdata", "demo_demography.yaml", package = "OpenPVA")
  expect_true(file.exists(path))

  sc <- read_scenario_yaml(path)
  expect_true(inherits(sc, "openpva_scenario"))
  expect_equal(attr(sc, "yaml_schema_version"), 1L)
  expect_equal(sc$env_surv_sd, 0.2)
  expect_equal(sc$cat_surv_prob, 0.05)
  expect_equal(sc$cat_surv_mult, 0.3)
  expect_equal(sc$harvest_quota, 2)

  sc$n_runs <- 5
  sc$n_years <- 10

  set.seed(123)
  out <- run_scenario(sc)
  summary_tbl <- out$sim_output$summary
  expect_true(all(c("env_surv_mult", "cat_surv_mult", "catastrophe") %in% names(summary_tbl)))
})
