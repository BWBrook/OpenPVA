test_that("schema_version 3 YAML is accepted and tracked", {
  yaml_text <- "
name: 'yaml_v3'
schema_version: 3
n_runs: 1
n_years: 2
seed: 99
initializer:
  fun: 'initialize_population'
  args:
    'n': 8
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc <- read_scenario_yaml(tmp)
  expect_true(inherits(sc, "openpva_scenario"))
  expect_equal(attr(sc, "yaml_schema_version"), 3L)
  expect_equal(sc$seed, 99L)
})

test_that("missing or unsupported schema_version fails clearly", {
  yaml_missing <- "
name: 'yaml_missing'
n_runs: 1
n_years: 1
initializer:
  fun: 'initialize_population'
  args:
    'n': 5
"
  tmp_missing <- tempfile(fileext = ".yaml")
  writeLines(yaml_missing, tmp_missing)
  on.exit(unlink(tmp_missing), add = TRUE)

  expect_error(read_scenario_yaml(tmp_missing), "schema_version: 3")

  yaml_future <- "
name: 'yaml_future'
schema_version: 4
n_runs: 1
n_years: 1
initializer:
  fun: 'initialize_population'
  args:
    'n': 5
"
  tmp_future <- tempfile(fileext = ".yaml")
  writeLines(yaml_future, tmp_future)
  on.exit(unlink(tmp_future), add = TRUE)

  expect_error(read_scenario_yaml(tmp_future), "schema_version: 3")
})

test_that("schema_version 3 YAML accepts uncertainty block and stores uncertainty_spec", {
  yaml_text <- "
name: 'yaml_v3_uncertainty'
schema_version: 3
n_runs: 2
n_years: 3
initializer:
  fun: 'initialize_population'
  args:
    'n': 12
uncertainty:
  params:
    harvest_quota:
      dist: 'uniform'
      min: 0
      max: 4
      integer: true
    cat_surv_prob:
      dist: 'uniform'
      min: 0
      max: 0.2
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc <- read_scenario_yaml(tmp)
  expect_equal(attr(sc, "yaml_schema_version"), 3L)
  expect_true(is.list(sc$uncertainty_spec))
  expect_true(all(c("harvest_quota", "cat_surv_prob") %in% names(sc$uncertainty_spec)))

  out <- run_scenario_ensemble(
    scenario = sc,
    n_draws = 3,
    seed = 303L
  )
  expect_s3_class(out, "openpva_ensemble_output")
  expect_equal(nrow(out$sampled_parameters), 3L)
})

test_that("invalid uncertainty config fails clearly", {
  yaml_text <- "
name: 'yaml_v3_invalid_uncertainty'
schema_version: 3
n_runs: 1
n_years: 1
initializer:
  fun: 'initialize_population'
  args:
    'n': 8
uncertainty:
  params:
    harvest_quota:
      dist: 'unknown_dist'
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  expect_error(read_scenario_yaml(tmp), "Unsupported dist")
})

test_that("canonical demography tables override function references", {
  yaml_text <- "
name: 'yaml_demography'
schema_version: 3
n_runs: 1
n_years: 2
initializer:
  fun: 'initialize_population'
  args:
    'n': 12
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
        p_surv: 1.0
  breeding_prob:
    table:
      - sex: 'F'
        age_min: 0
        age_max: 3
        p_breed: 0.0
      - sex: 'F'
        age_min: 4
        age_max: 100
        p_breed: 1.0
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
        lambda: 1.5
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
  expect_true(is.function(sc$survival_fun))
  expect_true(is.function(sc$breeding_prob_fun))
  expect_true(is.function(sc$fecundity_lambda_fun))
  expect_equal(sc$env_repro_p_sd, 0.1)
  expect_equal(sc$env_repro_lambda_sd, 0.2)

  set.seed(123)
  out <- run_scenario(sc)
  expect_true(all(c(
    "env_repro_p_mult", "env_repro_lambda_mult",
    "cat_repro_mult", "repro_catastrophe"
  ) %in% names(out$sim_output$summary)))
})

test_that("density block supports explicit channel configuration", {
  yaml_text <- "
name: 'yaml_density'
schema_version: 3
n_runs: 1
n_years: 1
initializer:
  fun: 'initialize_population'
  args:
    'n': 12
density:
  survival:
    model: ceiling
    K: 6
  breeding:
    model: constant
    multiplier: 0
  fecundity:
    model: constant
    multiplier: 1
lifecycle_steps:
  - age
  - survival
  - breeding_births
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc <- read_scenario_yaml(tmp)
  expect_true(inherits(sc$density_spec, "openpva_density_spec"))
  expect_true(is.null(sc$harvest_quota))

  set.seed(123)
  out <- run_scenario(sc)
  expect_equal(out$sim_output$summary$n_births[1], 0L)
})

test_that("density shorthand and legacy top-level K fields are rejected", {
  yaml_text <- "
name: 'yaml_bad_density'
schema_version: 3
n_runs: 1
n_years: 1
initializer:
  fun: 'initialize_population'
  args:
    'n': 8
density:
  K: 10
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  expect_error(read_scenario_yaml(tmp), "unknown field")
})

test_that("function resolution accepts package functions and explicit pkg::fun refs", {
  yaml_text <- "
name: 'yaml_namespaced'
schema_version: 3
n_runs: 1
n_years: 1
initializer:
  fun: 'OpenPVA::initialize_population'
  args:
    'n': 6
survival_fun: 'OpenPVA::default_survival_fun'
breeding_prob_fun: 'OpenPVA::default_breeding_prob_fun'
fecundity_lambda_fun: 'OpenPVA::default_fecundity_lambda_fun'
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc <- read_scenario_yaml(tmp)
  expect_true(inherits(sc, "openpva_scenario"))

  yaml_bad <- "
name: 'yaml_bad_ref'
schema_version: 3
n_runs: 1
n_years: 1
initializer:
  fun: 'does_not_exist'
"
  tmp_bad <- tempfile(fileext = ".yaml")
  writeLines(yaml_bad, tmp_bad)
  on.exit(unlink(tmp_bad), add = TRUE)

  expect_error(
    run_scenario(read_scenario_yaml(tmp_bad)),
    "Unknown unnamespaced function reference"
  )
})

test_that("canonical YAML supports spatial/genetic hooks", {
  yaml_text <- "
name: 'yaml_spatial_genetic'
schema_version: 3
n_runs: 1
n_years: 2
initializer:
  fun: 'initialize_spatial_genetic_population'
  args:
    n_per_patch: [3, 3]
    n_loci: 4
    n_alleles: 2
survival_fun: 'default_survival_fun'
breeding_prob_fun: 'default_breeding_prob_fun'
fecundity_lambda_fun: 'default_fecundity_lambda_fun'
dispersal_fun: 'dispersal_asymmetric_flow_fun'
inherit_fun: 'inherit_genotype_simple'
record_population_history: true
lifecycle_steps:
  - age
  - survival
  - dispersal
  - breeding_births
"

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc <- read_scenario_yaml(tmp)
  out <- run_scenario(sc)

  expect_true(isTRUE(sc$record_population_history))
  expect_true("population_history" %in% names(out$sim_output$runs[[1]]))
})
