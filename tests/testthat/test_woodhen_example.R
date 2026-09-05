woodhen_example_dir <- function() {
  installed <- system.file("examples", "woodhen", package = "OpenPVA")
  if (nzchar(installed)) {
    return(installed)
  }
  testthat::test_path("..", "..", "inst", "examples", "woodhen")
}

load_woodhen_example <- function() {
  environment <- new.env(parent = globalenv())
  directory <- woodhen_example_dir()
  for (file in c("parameters.R", "model.R", "analyse.R")) {
    sys.source(file.path(directory, file), envir = environment)
  }
  environment
}

test_that("Woodhen project uses only the public package surface", {
  directory <- woodhen_example_dir()
  scripts <- unlist(lapply(
    c("parameters.R", "model.R", "analyse.R", "run.R"),
    function(file) readLines(file.path(directory, file), warn = FALSE)
  ))

  expect_false(any(grepl("OpenPVA:::", scripts, fixed = TRUE)))
  expect_false(any(grepl("pkgload::", scripts, fixed = TRUE)))
  expect_false(any(grepl("source(\"R/", scripts, fixed = TRUE)))
})

test_that("Woodhen scenarios share an explicit two-sex parentage foundation", {
  model <- load_woodhen_example()
  parameters <- model$woodhen_parameters()

  expect_silent(model$woodhen_validate_parameters(parameters))
  expect_identical(
    model$woodhen_scenario_ids(parameters),
    c("no_intervention", "pig_control", "pig_control_captive")
  )

  no_action <- model$woodhen_build_scenario("no_intervention", n_runs = 2L)
  combined <- model$woodhen_build_scenario("pig_control_captive", n_runs = 2L)
  initial <- no_action$init_fun()

  expect_length(initial$population, 36L)
  sex_counts <- table(vapply(initial$population, `[[`, character(1), "sex"))
  expect_identical(names(sex_counts), c("F", "M"))
  expect_identical(as.integer(sex_counts), c(18L, 18L))
  reconstructed <- model$woodhen_reconstruct_pedigree(initial$population)
  expect_silent(validate_pedigree(reconstructed))
  expect_identical(
    vapply(no_action$processes, `[[`, character(1), "name"),
    c(
      "annual_conditions", "survival", "age", "territory_allocation",
      "reproduction", "census"
    )
  )
  expect_identical(
    vapply(combined$processes, `[[`, character(1), "name"),
    c(
      "annual_conditions", "survival", "age", "territory_allocation",
      "reproduction", "scheduled_capture",
      "captive_release", "census"
    )
  )
})

test_that("Woodhen management receipts and population accounting reconcile", {
  model <- load_woodhen_example()
  parameters <- model$woodhen_parameters()
  parameters$n_steps <- 5L
  scenario <- model$woodhen_build_scenario(
    "pig_control_captive",
    n_runs = 4L,
    seed = 90210L,
    parameters = parameters
  )
  result <- run_scenario(scenario)
  accounting <- model$woodhen_accounting(result, "pig_control_captive")
  events <- result$sim_output$events

  expect_true(all(accounting$reconciled))
  expect_true(all(accounting$introductions == 78L))
  expect_true(all(accounting$removals <= 8L))
  interval_census <- result$sim_output$census[
    result$sim_output$census$phase == "interval",
    ,
    drop = FALSE
  ]
  expect_true(all(
    interval_census$n_potential_pairs <=
      interval_census$territory_capacity_pairs
  ))
  expect_equal(sum(events$event_type == "capture_attempt"), 8L)
  expect_equal(
    sum(events$value[events$event_type == "introduction"], na.rm = TRUE),
    4L * 78L
  )
  audited <- model$woodhen_reconstruct_pedigree(
    result$sim_output$runs[[1L]]$state$population
  )
  expect_silent(validate_pedigree(audited))
})

test_that("Woodhen entry science is reproducible at fixed seed", {
  model <- load_woodhen_example()
  parameters <- model$woodhen_parameters()
  parameters$n_steps <- 3L
  scenario <- model$woodhen_build_scenario(
    "pig_control",
    n_runs = 3L,
    seed = 2468L,
    parameters = parameters
  )

  first <- run_scenario(scenario)
  second <- run_scenario(scenario)

  expect_identical(first$sim_output$events, second$sim_output$events)
  expect_identical(first$sim_output$census, second$sim_output$census)
  expect_identical(first$sim_output$provenance, second$sim_output$provenance)
})

test_that("Woodhen one-step mean agrees with an age-structured oracle", {
  model <- load_woodhen_example()
  parameters <- model$woodhen_parameters()
  parameters$n_steps <- 1L
  parameters$annual_environment$survival_sd <- 0
  parameters$annual_environment$fecundity_log_sd <- 0
  parameters$annual_environment$cyclone_probability <- 0
  parameters$scenarios$territory_capacity_pairs <- 1000000
  parameters$scenarios$territory_capacity_sd <- 0
  parameters$initial_population$males <- c(0L, rep(20L, 6L))

  female_rates <- model$woodhen_rate_rows(parameters, "F")
  female_counts <- parameters$initial_population$females
  expected_survivors <- female_counts * female_rates$p_surv
  post_survival_ages <- pmin(parameters$initial_population$age + 1L, 6L)
  expected_births <- sum(
    expected_survivors * female_rates$lambda[post_survival_ages + 1L]
  ) * parameters$offspring_female_probability
  expected_females <- sum(expected_survivors) + expected_births

  scenario <- model$woodhen_build_scenario(
    "no_intervention",
    n_runs = 100L,
    seed = 12345L,
    parameters = parameters
  )
  result <- run_scenario(scenario)
  final_females <- vapply(result$sim_output$runs, function(run) {
    sum(vapply(run$state$population, function(individual) {
      isTRUE(individual$alive) && identical(individual$sex, "F")
    }, logical(1)))
  }, integer(1))
  monte_carlo_bound <- 4 * stats::sd(final_females) / sqrt(length(final_females))

  expect_lte(abs(mean(final_females) - expected_females), monte_carlo_bound)
})
