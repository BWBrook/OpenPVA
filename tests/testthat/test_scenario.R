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

test_that("scenario_spec threads require_mate through run_scenario", {
  init_fun <- function() {
    list(
      create_individual(1L, "F", 5L),
      create_individual(2L, "F", 5L),
      create_individual(3L, "M", 5L)
    )
  }

  sc <- scenario_spec(
    name = "require_mate_scenario",
    n_runs = 1,
    n_years = 1,
    init_fun = init_fun,
    survival_fun = function(ind) 1,
    breeding_fun = function(ind) TRUE,
    fecundity_fun = function(ind) 1L,
    mating_fun = make_mate_limited_mating_fun(max_mates_per_male = 1L),
    require_mate = TRUE,
    lifecycle_steps = c("age", "survival", "breeding_births")
  )

  expect_true(sc$require_mate)
  out <- run_scenario(sc)
  expect_equal(out$sim_output$summary$n_births[1], 1L)
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

test_that("make_simple_genetic_scenario builds runnable scenario", {
  sc <- make_simple_genetic_scenario(
    name = "genetic_demo_test",
    n_runs = 3,
    n_years = 2,
    initial_n = 10,
    n_loci = 4,
    n_alleles = 2,
    mutation_rate = 0,
    beta_F = 0.5,
    K = NULL,
    harvest_quota = NULL
  )

  expect_true(inherits(sc, "openpva_scenario"))
  expect_equal(sc$n_runs, 3L)
  expect_equal(sc$n_years, 2L)
  expect_true(is.function(sc$inherit_fun))
  expect_true(is.function(sc$mating_fun))

  ind <- create_individual(99L, "F", age = 3L, inbreeding_coeff = 1)
  expect_lt(sc$survival_fun(ind), default_survival_fun(ind))

  set.seed(123)
  out <- run_scenario(sc)
  expect_equal(out$scenario, sc)
  expect_equal(nrow(out$sim_output$summary), 6L)

  final_pop <- out$sim_output$runs[[1]]$population
  alleles_flag <- vapply(final_pop, function(individual) !is.null(individual$alleles), logical(1))
  expect_true(any(alleles_flag))
})

test_that("scenario_spec carries dispersal_fun through run_scenario", {
  init_fun <- function() {
    pop <- initialize_population(n = 4, max_age = 1)
    initialize_patches(pop, patch_ids = c(1, 1, 2, 2))
  }
  survival_fun <- function(ind) 1
  breeding_fun <- function(ind) FALSE
  fecundity_fun <- function(ind) 0L
  dispersal_fun <- function(ind, population) {
    if (!is.na(ind$patch_id) && ind$patch_id == 1L) return(2L)
    ind$patch_id
  }

  sc <- scenario_spec(
    name = "dispersal_test",
    n_runs = 2,
    n_years = 1,
    init_fun = init_fun,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun,
    lifecycle_steps = c("age", "survival", "dispersal"),
    dispersal_fun = dispersal_fun
  )
  expect_true(inherits(sc, "openpva_scenario"))

  out <- run_scenario(sc)
  expect_equal(out$scenario, sc)
  expect_equal(length(out$sim_output$runs), 2L)

  check_pids <- function(run_output) {
    all(vapply(run_output$population, function(ind) ind$patch_id, integer(1)) == 2L)
  }
  expect_true(all(vapply(out$sim_output$runs, check_pids, logical(1))))
})

test_that("make_two_patch_spatial_scenario builds and runs", {
  sc <- make_two_patch_spatial_scenario(
    name = "two_patch_test",
    n_runs = 3,
    n_years = 2,
    initial_n = c(5L, 5L),
    K_patches = c(10, 10),
    dispersal_matrix = matrix(c(1, 0,
                                0, 1),
                              nrow = 2, byrow = TRUE)
  )
  expect_true(inherits(sc, "openpva_scenario"))
  expect_equal(sc$n_runs, 3L)
  expect_equal(sc$n_years, 2L)
  expect_equal(sc$K_patches, c(10, 10))
  expect_true(is.function(sc$dispersal_fun))

  set.seed(456)
  out <- run_scenario(sc)
  expect_equal(length(out$sim_output$runs), 3L)
  check_patches <- function(run_output) {
    all(vapply(run_output$population, function(ind) ind$patch_id, integer(1)) %in% c(1L, 2L, NA_integer_))
  }
  expect_true(all(vapply(out$sim_output$runs, check_patches, logical(1))))
})

test_that("read_scenario_yaml handles management block", {
  lines <- c(
    "name: 'yaml_mgmt'",
    "n_runs: 3",
    "n_years: 4",
    "initializer:",
    "  fun: 'initialize_population'",
    "  args:",
    "    'n': 10",
    "survival_fun: 'default_survival_fun'",
    "breeding_fun: 'default_breeding_fun'",
    "fecundity_fun: 'default_fecundity_fun'",
    "K: 50",
    "lifecycle_steps:",
    "  - age",
    "  - survival",
    "  - supplementation",
    "  - harvest",
    "management:",
    "  harvest_quota: 3",
    "  supplement_quota: 1",
    "  supplement_patch: 2"
  )
  yaml_text <- paste(lines, collapse = "\n")

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc <- read_scenario_yaml(tmp)
  expect_true(inherits(sc, "openpva_scenario"))
  expect_equal(sc$harvest_quota, 3)
  expect_equal(sc$supplement_quota, 1)
  expect_equal(sc$supplement_patch, 2L)
  expect_true("supplementation" %in% sc$lifecycle_steps)

  out <- run_scenario(sc)
  expect_true(any(out$sim_output$summary$n_supplemented > 0L))
  expect_true(any(out$sim_output$summary$n_harvested >= 0L))
})

test_that("scenario_spec and run_scenario carry record_population_history", {
  sc <- scenario_spec(
    name = "history_demo",
    n_runs = 2,
    n_years = 2,
    init_fun = function() initialize_population(6),
    survival_fun = function(ind) 1,
    breeding_fun = function(ind) FALSE,
    fecundity_fun = function(ind) 0L,
    lifecycle_steps = c("age", "survival"),
    record_population_history = TRUE
  )

  expect_true(isTRUE(sc$record_population_history))
  out <- run_scenario(sc)
  expect_true(all(vapply(out$sim_output$runs, function(run) "population_history" %in% names(run), logical(1))))
})
test_that("read_scenario_yaml handles management block", {
  yaml_text <- "name: 'yaml_mgmt'\n"
  yaml_text <- paste0(yaml_text, "n_runs: 3\n")
  yaml_text <- paste0(yaml_text, "n_years: 4\n")
  yaml_text <- paste0(yaml_text, "initializer:\n")
  yaml_text <- paste0(yaml_text, "  fun: 'initialize_population'\n")
  yaml_text <- paste0(yaml_text, "  args:\n")
  yaml_text <- paste0(yaml_text, "    \"n\": 10\n")
  yaml_text <- paste0(yaml_text, "survival_fun: 'default_survival_fun'\n")
  yaml_text <- paste0(yaml_text, "breeding_fun: 'default_breeding_fun'\n")
  yaml_text <- paste0(yaml_text, "fecundity_fun: 'default_fecundity_fun'\n")
  yaml_text <- paste0(yaml_text, "K: 50\n")
  yaml_text <- paste0(yaml_text, "lifecycle_steps:\n")
  yaml_text <- paste0(yaml_text, "  - age\n")
  yaml_text <- paste0(yaml_text, "  - survival\n")
  yaml_text <- paste0(yaml_text, "  - supplementation\n")
  yaml_text <- paste0(yaml_text, "  - harvest\n")
  yaml_text <- paste0(yaml_text, "management:\n")
  yaml_text <- paste0(yaml_text, "  harvest_quota: 3\n")
  yaml_text <- paste0(yaml_text, "  supplement_quota: 1\n")
  yaml_text <- paste0(yaml_text, "  supplement_patch: 2\n")

  tmp <- tempfile(fileext = ".yaml")
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc <- read_scenario_yaml(tmp)
  expect_true(inherits(sc, "openpva_scenario"))
  expect_equal(sc$harvest_quota, 3)
  expect_equal(sc$supplement_quota, 1)
  expect_equal(sc$supplement_patch, 2L)
  expect_true("supplementation" %in% sc$lifecycle_steps)

  out <- run_scenario(sc)
  expect_true(any(out$sim_output$summary$n_supplemented > 0L))
  expect_true(any(out$sim_output$summary$n_harvested >= 0L))
})
