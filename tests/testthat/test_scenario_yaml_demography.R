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
seed: 99
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
  expect_equal(sc$seed, 99L)
})

test_that("unknown or invalid schema_version fails with clear errors", {
  yaml_future <- "
name: 'yaml_future'
schema_version: 3
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

test_that("schema_version 2 YAML supports reproduction tables and reproduction_ev block", {
  yaml_text <- "
name: 'yaml_v2'
schema_version: 2
n_runs: 2
n_years: 3
seed: 202
initializer:
  fun: 'initialize_population'
  args:
    \"n\": 12
survival_fun: 'default_survival_fun'
demography:
  breeding_prob:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 3
        p_breed: 0.0
      - sex: 'F'
        age_min: 4
        age_max: 100
        p_breed: 0.7
      - sex: 'M'
        age_min: 0
        age_max: 100
        p_breed: 0.0
  fecundity_lambda:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 3
        lambda: 0.0
      - sex: 'F'
        age_min: 4
        age_max: 100
        lambda: 1.2
      - sex: 'M'
        age_min: 0
        age_max: 100
        lambda: 0.0
reproduction_ev:
  env_repro_p_sd: 0.1
  env_repro_lambda_sd: 0.2
  cat_repro_prob: 0.3
  cat_repro_mult: 0.5
lifecycle_steps:
  - age
  - survival
  - breeding_births
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc <- read_scenario_yaml(tmp)
  expect_true(inherits(sc, "openpva_scenario"))
  expect_equal(attr(sc, "yaml_schema_version"), 2L)
  expect_equal(sc$env_repro_p_sd, 0.1)
  expect_equal(sc$env_repro_lambda_sd, 0.2)
  expect_equal(sc$cat_repro_prob, 0.3)
  expect_equal(sc$cat_repro_mult, 0.5)

  set.seed(123)
  out <- run_scenario(sc)
  expect_true(all(c(
    "env_repro_p_mult", "env_repro_lambda_mult",
    "cat_repro_mult", "repro_catastrophe"
  ) %in% names(out$sim_output$summary)))
})

test_that("schema_version 2 adapts legacy demography/reproduction fields", {
  yaml_text <- "
name: 'yaml_v2_legacy_adapt'
schema_version: 2
n_runs: 1
n_years: 2
initializer:
  fun: 'initialize_population'
  args:
    \"n\": 8
survival_fun: 'default_survival_fun'
demography:
  breeding:
    table:
      - sex: 'F'
        age_min: 4
        age_max: 100
        can_breed: true
      - sex: 'M'
        age_min: 0
        age_max: 100
        can_breed: false
  fecundity:
    table:
      - sex: 'F'
        age_min: 4
        age_max: 100
        lambda: 1.5
      - sex: 'M'
        age_min: 0
        age_max: 100
        lambda: 0
env_repro_p_sd: 0.1
env_repro_lambda_sd: 0.2
cat_repro_prob: 0.4
cat_repro_mult: 0.6
lifecycle_steps:
  - age
  - survival
  - breeding_births
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc <- read_scenario_yaml(tmp)
  expect_equal(attr(sc, "yaml_schema_version"), 2L)
  expect_true(is.function(sc$breeding_prob_fun))
  expect_true(is.function(sc$fecundity_lambda_fun))
  expect_equal(sc$env_repro_p_sd, 0.1)
  expect_equal(sc$env_repro_lambda_sd, 0.2)
  expect_equal(sc$cat_repro_prob, 0.4)
  expect_equal(sc$cat_repro_mult, 0.6)
})

test_that("v1 to v2 migration helper upgrades demography and reproduction_ev", {
  cfg_v1 <- list(
    schema_version = 1L,
    name = "cfg_v1",
    n_runs = 1L,
    n_years = 1L,
    initializer = list(fun = "initialize_population", args = list(n = 5L)),
    demography = list(
      breeding = list(table = list(
        list(sex = "F", age_min = 4, age_max = 100, can_breed = TRUE),
        list(sex = "M", age_min = 0, age_max = 100, can_breed = FALSE)
      )),
      fecundity = list(table = list(
        list(sex = "F", age_min = 4, age_max = 100, lambda = 1.5),
        list(sex = "M", age_min = 0, age_max = 100, lambda = 0)
      ))
    ),
    env_repro_p_sd = 0.1,
    env_repro_lambda_sd = 0.2,
    cat_repro_prob = 0.3,
    cat_repro_mult = 0.4
  )

  cfg_v2 <- OpenPVA:::.migrate_yaml_v1_to_v2(cfg_v1)
  expect_equal(cfg_v2$schema_version, 2L)
  expect_true(!is.null(cfg_v2$demography$breeding_prob$table))
  expect_true(!is.null(cfg_v2$demography$fecundity_lambda$table))
  expect_equal(cfg_v2$reproduction_ev$env_repro_p_sd, 0.1)
  expect_equal(cfg_v2$reproduction_ev$env_repro_lambda_sd, 0.2)
  expect_equal(cfg_v2$reproduction_ev$cat_repro_prob, 0.3)
  expect_equal(cfg_v2$reproduction_ev$cat_repro_mult, 0.4)
})

test_that("schema_version 2 invalid YAML fails with a clear error", {
  yaml_text <- "
name: 'yaml_v2_invalid'
schema_version: 2
n_runs: 1
n_years: 1
initializer:
  fun: 'initialize_population'
  args:
    \"n\": 5
survival_fun: 'default_survival_fun'
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  expect_error(
    read_scenario_yaml(tmp),
    "requires breeding_prob and fecundity_lambda channels"
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
  expect_equal(sc$seed, 20260305L)
  expect_equal(sc$harvest_quota, 2)

  sc$n_runs <- 5
  sc$n_years <- 10

  set.seed(123)
  out <- run_scenario(sc)
  summary_tbl <- out$sim_output$summary
  expect_true(all(c("env_surv_mult", "cat_surv_mult", "catastrophe") %in% names(summary_tbl)))
})

test_that("demo_reproduction_v2 YAML parses and runs", {
  path <- system.file("extdata", "demo_reproduction_v2.yaml", package = "OpenPVA")
  expect_true(file.exists(path))

  sc <- read_scenario_yaml(path)
  expect_true(inherits(sc, "openpva_scenario"))
  expect_equal(attr(sc, "yaml_schema_version"), 2L)
  expect_true(is.function(sc$breeding_prob_fun))
  expect_true(is.function(sc$fecundity_lambda_fun))
  expect_equal(sc$env_repro_p_sd, 0.15)
  expect_equal(sc$env_repro_lambda_sd, 0.1)
  expect_equal(sc$cat_repro_prob, 0.1)
  expect_equal(sc$cat_repro_mult, 0.5)

  out <- run_scenario(sc)
  summary_tbl <- out$sim_output$summary
  expect_true(all(c(
    "env_repro_p_mult",
    "env_repro_lambda_mult",
    "cat_repro_mult",
    "repro_catastrophe"
  ) %in% names(summary_tbl)))
})

test_that("demo_density_v2 YAML parses and runs with density_spec", {
  path <- system.file("extdata", "demo_density_v2.yaml", package = "OpenPVA")
  expect_true(file.exists(path))

  sc <- read_scenario_yaml(path)
  expect_true(inherits(sc, "openpva_scenario"))
  expect_equal(attr(sc, "yaml_schema_version"), 2L)
  expect_s3_class(sc$density_spec, "openpva_density_spec")
  expect_true(is.null(sc$K))
  expect_true(is.null(sc$K_patches))

  out <- run_scenario(sc)
  expect_true(all(c(
    "env_repro_p_mult",
    "env_repro_lambda_mult",
    "cat_repro_mult",
    "repro_catastrophe"
  ) %in% names(out$sim_output$summary)))
})

test_that("schema_version 2 YAML supports density block channels", {
  yaml_text <- "
name: 'yaml_v2_density_channels'
schema_version: 2
n_runs: 2
n_years: 4
seed: 222
initializer:
  fun: 'initialize_population'
  args:
    \"n\": 20
survival_fun: 'default_survival_fun'
demography:
  breeding_prob:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 100
        p_breed: 0.8
      - sex: 'M'
        age_min: 0
        age_max: 100
        p_breed: 0.0
  fecundity_lambda:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 100
        lambda: 1.5
      - sex: 'M'
        age_min: 0
        age_max: 100
        lambda: 0.0
density:
  survival:
    model: ceiling
    K: 8
  breeding:
    model: constant
    multiplier: 0.6
  fecundity:
    model: constant
    multiplier: 0.5
lifecycle_steps:
  - age
  - survival
  - breeding_births
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc <- read_scenario_yaml(tmp)
  expect_true(inherits(sc, "openpva_scenario"))
  expect_equal(attr(sc, "yaml_schema_version"), 2L)
  expect_s3_class(sc$density_spec, "openpva_density_spec")
  expect_true(is.null(sc$K))
  expect_true(is.null(sc$K_patches))

  out <- run_scenario(sc)
  expect_equal(nrow(out$sim_output$summary), sc$n_runs * sc$n_years)
  expect_true(all(out$sim_output$summary$n_alive >= 0))
})

test_that("density shorthand K in YAML maps to survival ceiling behavior", {
  yaml_text <- "
name: 'yaml_v2_density_shorthand'
schema_version: 2
n_runs: 3
n_years: 3
seed: 909
initializer:
  fun: 'initialize_population'
  args:
    \"n\": 30
survival_fun: 'default_survival_fun'
demography:
  breeding_prob:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 100
        p_breed: 0.7
      - sex: 'M'
        age_min: 0
        age_max: 100
        p_breed: 0.0
  fecundity_lambda:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 100
        lambda: 1.1
      - sex: 'M'
        age_min: 0
        age_max: 100
        lambda: 0.0
density:
  K: 12
lifecycle_steps:
  - age
  - survival
  - breeding_births
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc <- read_scenario_yaml(tmp)
  expect_s3_class(sc$density_spec, "openpva_density_spec")
  expect_true(is.null(sc$K))

  out_yaml <- run_scenario(sc)

  sc_ref <- scenario_spec(
    name = "ref_density_shorthand",
    n_runs = 3,
    n_years = 3,
    init_fun = function() initialize_population(30),
    survival_fun = default_survival_fun,
    breeding_prob_fun = function(ind) if (ind$sex == "F") 0.7 else 0,
    fecundity_lambda_fun = function(ind) if (ind$sex == "F") 1.1 else 0,
    density_spec = density_spec(
      survival_fun = make_ceiling_density_fun(K = 12)
    ),
    lifecycle_steps = c("age", "survival", "breeding_births"),
    seed = 909L
  )
  out_ref <- run_scenario(sc_ref)

  expect_identical(out_yaml$sim_output$summary$n_alive, out_ref$sim_output$summary$n_alive)
})

test_that("invalid density YAML inputs fail clearly", {
  yaml_unknown_field <- "
name: 'yaml_density_bad_field'
schema_version: 2
n_runs: 1
n_years: 1
initializer:
  fun: 'initialize_population'
  args:
    \"n\": 10
survival_fun: 'default_survival_fun'
demography:
  breeding_prob:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 100
        p_breed: 0.6
  fecundity_lambda:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 100
        lambda: 1.0
density:
  foo: 1
"
  tmp_unknown <- tempfile(fileext = ".yaml")
  writeLines(yaml_unknown_field, tmp_unknown)
  on.exit(unlink(tmp_unknown), add = TRUE)
  expect_error(
    read_scenario_yaml(tmp_unknown),
    "density has unknown fields"
  )

  yaml_missing_constant <- "
name: 'yaml_density_missing_constant'
schema_version: 2
n_runs: 1
n_years: 1
initializer:
  fun: 'initialize_population'
  args:
    \"n\": 10
survival_fun: 'default_survival_fun'
demography:
  breeding_prob:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 100
        p_breed: 0.6
  fecundity_lambda:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 100
        lambda: 1.0
density:
  breeding:
    model: constant
"
  tmp_missing <- tempfile(fileext = ".yaml")
  writeLines(yaml_missing_constant, tmp_missing)
  on.exit(unlink(tmp_missing), add = TRUE)
  expect_error(
    read_scenario_yaml(tmp_missing),
    "multiplier is required"
  )

  yaml_density_and_legacy <- "
name: 'yaml_density_and_legacy'
schema_version: 2
n_runs: 1
n_years: 1
initializer:
  fun: 'initialize_population'
  args:
    \"n\": 10
survival_fun: 'default_survival_fun'
demography:
  breeding_prob:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 100
        p_breed: 0.6
  fecundity_lambda:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 100
        lambda: 1.0
K: 20
density:
  survival:
    model: ceiling
    K: 15
"
  tmp_mix <- tempfile(fileext = ".yaml")
  writeLines(yaml_density_and_legacy, tmp_mix)
  on.exit(unlink(tmp_mix), add = TRUE)
  expect_error(
    read_scenario_yaml(tmp_mix),
    "cannot combine density block with top-level K/K_patches"
  )
})

test_that("YAML require_mate toggles unmated female reproduction", {
  yaml_template <- "
name: 'yaml_require_mate_toggle'
schema_version: 1
n_runs: 1
n_years: 1
seed: 123
initializer:
  fun: 'initialize_population'
  args:
    \"n\": 50
demography:
  survival:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 100
        p_surv: 1.0
      - sex: 'M'
        age_min: 0
        age_max: 100
        p_surv: 0.0
  breeding:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 100
        can_breed: true
      - sex: 'M'
        age_min: 0
        age_max: 100
        can_breed: false
  fecundity:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 100
        lambda: 1.0
      - sex: 'M'
        age_min: 0
        age_max: 100
        lambda: 0.0
lifecycle_steps:
  - age
  - survival
  - breeding_births
require_mate: %s
"

  tmp_true <- tempfile(fileext = ".yaml")
  tmp_false <- tempfile(fileext = ".yaml")
  writeLines(sprintf(yaml_template, "true"), tmp_true)
  writeLines(sprintf(yaml_template, "false"), tmp_false)
  on.exit(unlink(c(tmp_true, tmp_false)), add = TRUE)

  sc_true <- read_scenario_yaml(tmp_true)
  sc_false <- read_scenario_yaml(tmp_false)
  expect_true(sc_true$require_mate)
  expect_false(sc_false$require_mate)

  out_true <- run_scenario(sc_true)
  out_false <- run_scenario(sc_false)

  births_true <- sum(out_true$sim_output$summary$n_births)
  births_false <- sum(out_false$sim_output$summary$n_births)
  expect_equal(births_true, 0L)
  expect_gt(births_false, births_true)
})
