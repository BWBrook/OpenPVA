test_that("illustrative benchmark fixture is explicit and bounded", {
  parameters <- grizzly_benchmark_parameters(horizon = 4L)
  expect_false(parameters$calibrated)
  expect_match(parameters$source_label, "not empirical")
  expect_identical(parameters$horizon, 4L)
  expect_length(parameters$environmental_modifiers, 4L)
  expect_true(all(parameters$female_survival >= 0 & parameters$female_survival <= 1))

  scenarios <- grizzly_benchmark_scenarios(parameters, n_runs = 1L)
  expect_identical(
    names(scenarios),
    c("baseline", "female_low_survival", "female_high_survival", "human_mortality", "immigration")
  )
  expect_true(all(vapply(scenarios, inherits, logical(1), what = "openpva_scenario")))
  process_ok <- vapply(scenarios, function(x) {
    length(x$processes) >= 9L &&
      all(vapply(x$processes, inherits, logical(1), what = "pva_process"))
  }, logical(1))
  expect_true(all(process_ok))
})

test_that("empty, one-sex and all-dependent states are valid edge cases", {
  parameters <- grizzly_benchmark_parameters(horizon = 1L)
  processes <- grizzly_benchmark_processes(parameters, "baseline", include_observation = FALSE)

  empty <- grizzly_benchmark_initial_state(0L, 0L, 0L, 0L, parameters)
  empty_result <- execute_processes(empty, processes)
  expect_identical(empty_result$state$population, list())
  expect_equal(sum(empty_result$events$event_type == "birth"), 0L)

  one_sex <- grizzly_benchmark_initial_state(2L, 0L, 0L, 0L, parameters)
  one_sex_result <- execute_processes(one_sex, processes)
  expect_equal(sum(one_sex_result$events$event_type == "birth"), 0L)

  all_dependent <- grizzly_benchmark_initial_state(2L, 2L, 2L, 2L, parameters)
  all_dependent_result <- execute_processes(all_dependent, processes)
  expect_equal(sum(all_dependent_result$events$event_type == "birth"), 0L)
  expect_true(all(vapply(
    all_dependent_result$state$population,
    function(ind) ind$dependency %in% c("cub", "yearling"),
    logical(1)
  )))
})

test_that("required scenarios retain events, replicate units and provenance", {
  output <- run_grizzly_benchmark("human_mortality", n_runs = 8L, n_steps = 3L, seed = 17L)
  summary <- output$benchmark_summary
  expect_true(all(c(
    "n_alive", "n_female_alive", "n_male_alive", "n_dependent_alive",
    "n_independent_alive", "n_female_independent_alive", "finite_growth"
  ) %in% names(summary$trajectory)))
  expect_true(all(c("birth", "death", "census", "environment") %in% summary$events$event_type))
  expect_equal(nrow(summary$run_summary), 8L)
  expect_true(all(c("root_seed", "rng_kind", "streams", "benchmark") %in%
    names(output$sim_output$provenance)))
  expect_match(summary$provenance$parameter_hash, "^[0-9a-f]{32}$")
  expect_identical(summary$provenance$software$package, as.character(utils::packageVersion("OpenPVA")))
  expect_true(is.finite(summary$quasi_extinction_mcse))
})

test_that("environmental variation is an ordinary extension", {
  varied_scenario <- grizzly_benchmark_scenario(
    "environmental_variation", n_runs = 1L, n_steps = 4L, seed = 8L
  )
  varied <- run_scenario(varied_scenario)
  environment_events <- varied$sim_output$events[
    varied$sim_output$events$event_type == "environment", , drop = FALSE
  ]
  expect_equal(environment_events$modifier, c(0.9, 1.05, 0.96, 1.02))

})

test_that("custom observer is non-mutating and mortality order changes births", {
  parameters <- grizzly_benchmark_parameters(horizon = 1L)
  parameters$breeding_probability <- 1
  parameters$fecundity_lambda <- 1000
  parameters$human_mortality_probability <- 1
  initial <- function() grizzly_benchmark_initial_state(1L, 1L, 0L, 0L, parameters)

  after <- grizzly_benchmark_scenario("human_mortality", parameters, n_runs = 1L, n_steps = 1L, seed = 2L)
  before <- grizzly_benchmark_scenario(
    "human_mortality_before_reproduction", parameters,
    n_runs = 1L, n_steps = 1L, seed = 2L
  )
  after$init_fun <- initial
  before$init_fun <- initial
  after_output <- run_scenario(after)$sim_output
  before_output <- run_scenario(before)$sim_output
  expect_true(any(after_output$events$event_type == "birth"))
  expect_false(any(before_output$events$event_type == "birth"))

  observer <- grizzly_observation_process()
  state <- initial()
  result <- execute_processes(state, list(observer))
  expect_identical(result$state, state)
  expect_identical(result$events$event_type, "observation")
})

test_that("mating selects only mature eligible males", {
  parameters <- grizzly_benchmark_parameters(horizon = 1L)
  parameters$breeding_probability <- 1
  parameters$fecundity_lambda <- 100
  parameters$dependent_survival <- 1
  parameters$male_survival <- 1
  parameters$female_survival[] <- 1
  parameters$environmental_modifiers[] <- 1
  parameters$varying_environmental_modifiers[] <- 1
  processes <- grizzly_benchmark_processes(parameters, "baseline", include_observation = FALSE)
  reproduction <- processes[[which(vapply(processes, function(x) x$name == "reproduction", logical(1)))[[1L]]]]
  eligibility <- processes[[which(vapply(processes, function(x) x$name == "breeding_eligibility", logical(1)))[[1L]]]]

  state <- grizzly_benchmark_initial_state(1L, 2L, 0L, 0L, parameters)
  state$population[[2L]]$age <- parameters$dependency_age
  state$population[[2L]]$dependency <- "independent"
  state$population[[3L]]$age <- parameters$maturity_age
  state$population[[3L]]$dependency <- "independent"
  result <- execute_processes(state, list(eligibility, reproduction))
  newborns <- result$state$population[vapply(
    result$state$population, function(ind) ind$age == 0L, logical(1)
  )]
  expect_gt(length(newborns), 0L)
  expect_true(all(vapply(newborns, function(ind) identical(ind$father_id, 3L), logical(1))))

  no_mature <- state
  no_mature$population[[3L]]$age <- parameters$dependency_age
  result <- execute_processes(no_mature, list(eligibility, reproduction))
  expect_false(any(result$events$event_type == "birth"))
})

test_that("seeded benchmark execution is exactly reproducible", {
  first <- run_grizzly_benchmark("baseline", n_runs = 4L, n_steps = 3L, seed = 81L)
  second <- run_grizzly_benchmark("baseline", n_runs = 4L, n_steps = 3L, seed = 81L)
  expect_identical(first$sim_output$events, second$sim_output$events)
  expect_identical(first$benchmark_summary$run_summary, second$benchmark_summary$run_summary)
})

test_that("one-interval benchmark mean follows an independent expectation", {
  parameters <- grizzly_benchmark_parameters(horizon = 1L)
  parameters$breeding_probability <- 1
  parameters$fecundity_lambda <- 0.5
  parameters$dependent_survival <- 1
  parameters$male_survival <- 1
  parameters$female_survival[] <- 1
  parameters$human_mortality_probability <- 0
  parameters$environmental_modifiers[] <- 1
  parameters$varying_environmental_modifiers[] <- 1
  output <- run_grizzly_benchmark("baseline", parameters, n_runs = 400L, n_steps = 1L, seed = 91L)
  birth_events <- output$sim_output$events |>
    dplyr::filter(.data$event_type == "birth") |>
    dplyr::group_by(.data$run) |>
    dplyr::summarise(value = sum(.data$value), .groups = "drop")
  birth_counts <- data.frame(run = seq_len(400L)) |>
    dplyr::left_join(birth_events, by = "run") |>
    dplyr::mutate(value = dplyr::coalesce(.data$value, 0))
  # Three initially mature females remain eligible after their maternal links
  # are assigned; zero-event replicates are part of the unconditional mean.
  n_eligible <- 3L
  expected <- n_eligible * parameters$fecundity_lambda
  mcse <- sqrt(expected / 400)
  expect_equal(nrow(birth_counts), 400L)
  expect_lt(abs(mean(birth_counts$value) - expected), 6 * mcse)
})

test_that("human mortality frequency is calibrated for target hazards", {
  parameters <- grizzly_benchmark_parameters(horizon = 1L)
  parameters$breeding_probability <- 0
  parameters$fecundity_lambda <- 0
  parameters$dependent_survival <- 1
  parameters$male_survival <- 1
  parameters$female_survival[] <- 1
  parameters$environmental_modifiers[] <- 1
  parameters$varying_environmental_modifiers[] <- 1
  parameters$human_mortality_probability <- 0.4
  output <- run_grizzly_benchmark(
    "human_mortality", parameters, n_runs = 500L, n_steps = 1L, seed = 1901L
  )
  human_deaths <- output$sim_output$events |>
    dplyr::filter(.data$event_type == "death", .data$cause == "human") |>
    dplyr::group_by(.data$run) |>
    dplyr::summarise(deaths = sum(.data$value), .groups = "drop")
  death_counts <- data.frame(run = seq_len(500L)) |>
    dplyr::left_join(human_deaths, by = "run") |>
    dplyr::mutate(deaths = dplyr::coalesce(.data$deaths, 0))
  expected <- 4 * parameters$human_mortality_probability
  mcse <- sqrt(4 * parameters$human_mortality_probability *
    (1 - parameters$human_mortality_probability) / 500)
  expect_lt(abs(mean(death_counts$deaths) - expected), 6 * mcse)
  deaths <- output$sim_output$events |>
    dplyr::filter(.data$event_type == "death", .data$cause == "human")
  expect_true(all(c("age", "age_class") %in% names(deaths)))
  if (nrow(deaths)) {
    expect_true(all(deaths$age == 5L))
    expect_true(all(deaths$age_class == "adult"))
  }
})

test_that("maternal care is immediate and blocks repeated reproduction", {
  parameters <- grizzly_benchmark_parameters(horizon = 1L)
  parameters$breeding_probability <- 1
  parameters$fecundity_lambda <- 100
  parameters$dependent_survival <- 1
  parameters$male_survival <- 1
  parameters$female_survival[] <- 1
  parameters$environmental_modifiers[] <- 1
  parameters$varying_environmental_modifiers[] <- 1
  processes <- grizzly_benchmark_processes(parameters, "baseline", include_observation = FALSE)
  reproduction <- processes[[which(vapply(processes, function(x) x$name == "reproduction", logical(1)))[[1L]]]]
  state <- grizzly_benchmark_initial_state(1L, 1L, 0L, 0L, parameters)
  state$population[[1L]]$reproductive_status <- "eligible"
  first <- execute_processes(state, list(reproduction))
  second <- execute_processes(first$state, list(reproduction))
  expect_equal(sum(first$events$event_type == "birth"), 1L)
  expect_false(any(second$events$event_type == "birth"))
  expect_gt(length(first$state$population), length(state$population))
  mother <- first$state$population[[1L]]
  expect_identical(mother$reproductive_status, "caring")
})

test_that("post-survival maternal status distinguishes live and dead dependants", {
  parameters <- grizzly_benchmark_parameters(horizon = 1L)
  parameters$breeding_probability <- 1
  parameters$fecundity_lambda <- 100
  parameters$dependent_survival <- 1
  parameters$male_survival <- 1
  parameters$female_survival[] <- 1
  parameters$environmental_modifiers[] <- 1
  parameters$varying_environmental_modifiers[] <- 1
  processes <- grizzly_benchmark_processes(parameters, "baseline", include_observation = FALSE)
  reproduction <- processes[[which(vapply(processes, function(x) x$name == "reproduction", logical(1)))[[1L]]]]
  dependent <- processes[[which(vapply(processes, function(x) x$name == "dependent_survival", logical(1)))[[1L]]]]
  state <- grizzly_benchmark_initial_state(1L, 1L, 0L, 0L, parameters)
  state$population[[1L]]$reproductive_status <- "eligible"
  surviving <- execute_processes(state, list(reproduction, dependent))
  expect_identical(surviving$state$population[[1L]]$reproductive_status, "caring")

  parameters$dependent_survival <- 0
  processes <- grizzly_benchmark_processes(parameters, "baseline", include_observation = FALSE)
  reproduction <- processes[[which(vapply(processes, function(x) x$name == "reproduction", logical(1)))[[1L]]]]
  dependent <- processes[[which(vapply(processes, function(x) x$name == "dependent_survival", logical(1)))[[1L]]]]
  state$population[[1L]]$reproductive_status <- "eligible"
  dead <- execute_processes(state, list(reproduction, dependent))
  expect_identical(dead$state$population[[1L]]$reproductive_status, "ineligible")
  newborns <- dead$state$population[vapply(
    dead$state$population, function(ind) ind$age == 0L, logical(1)
  )]
  expect_true(length(newborns) > 0L)
  expect_false(any(vapply(newborns, function(ind) isTRUE(ind$alive), logical(1))))
})

test_that("engine accounting and human mortality strata reconcile each interval", {
  output <- run_grizzly_benchmark("human_mortality", n_runs = 6L, n_steps = 3L, seed = 44L)
  trajectory <- output$benchmark_summary$trajectory |>
    dplyr::filter(.data$phase == "interval")
  initial <- output$benchmark_summary$trajectory |>
    dplyr::filter(.data$phase == "initial") |>
    dplyr::select(run, before = n_alive)
  events <- output$sim_output$events |>
    dplyr::filter(.data$event_type %in% c("birth", "introduction", "death")) |>
    dplyr::mutate(delta = dplyr::case_when(
      .data$event_type %in% c("birth", "introduction") ~ as.numeric(.data$value),
      TRUE ~ -as.numeric(.data$value)
    )) |>
    dplyr::group_by(.data$run, .data$time) |>
    dplyr::summarise(delta = sum(.data$delta), .groups = "drop")
  checks <- trajectory |>
    dplyr::select(run, time, after = n_alive) |>
    dplyr::left_join(initial, by = "run") |>
    dplyr::left_join(events, by = c("run", "time")) |>
    dplyr::mutate(
      delta = dplyr::coalesce(.data$delta, 0),
      before = dplyr::if_else(.data$time == 0L, .data$before, NA_integer_)
    )
  for (run in unique(checks$run)) {
    previous <- initial$before[initial$run == run][[1L]]
    for (time in sort(checks$time[checks$run == run])) {
      after <- checks$after[checks$run == run & checks$time == time][[1L]]
      delta <- checks$delta[checks$run == run & checks$time == time][[1L]]
      expect_identical(as.integer(previous + delta), as.integer(after))
      previous <- after
    }
  }
  human <- output$sim_output$events |>
    dplyr::filter(.data$event_type == "death", .data$cause == "human")
  expect_true(all(c("sex", "age_class", "dependency") %in% names(human)))
  if (nrow(human)) expect_true(all(human$sex == "F" & human$dependency == "independent"))
})

test_that("dependency transitions are cub to yearling to independent", {
  parameters <- grizzly_benchmark_parameters(horizon = 1L)
  state <- grizzly_benchmark_initial_state(2L, 1L, 1L, 1L, parameters)
  state$population[[1L]]$age <- 1L
  state$population[[2L]]$age <- 2L
  state$population[[3L]]$age <- 3L
  state$population[[1L]]$dependency <- "cub"
  state$population[[2L]]$dependency <- "cub"
  state$population[[3L]]$dependency <- "yearling"
  result <- execute_processes(state, list(age_process(), grizzly_dependency_process(parameters)))
  statuses <- vapply(result$state$population, `[[`, character(1), "dependency")
  expect_identical(statuses, c("yearling", "independent", "independent"))
  expect_true(all(result$events$event_type == "dependency_transition"))
})

test_that("females caring for live dependent offspring are ineligible", {
  parameters <- grizzly_benchmark_parameters(horizon = 1L)
  state <- grizzly_benchmark_initial_state(2L, 1L, 0L, 0L, parameters)
  state$population[[1L]]$mother_id <- NA_integer_
  state$population[[2L]]$age <- 1L
  state$population[[2L]]$dependency <- "cub"
  state$population[[2L]]$mother_id <- state$population[[1L]]$id
  result <- execute_processes(
    state,
    list(grizzly_breeding_eligibility_process(parameters))
  )
  expect_identical(result$events$value, 0L)
  expect_identical(result$state$population[[1L]]$reproductive_status, "caring")
})

test_that("summary counts initial threshold crossings and empty initial growth honestly", {
  parameters <- grizzly_benchmark_parameters(horizon = 1L, quasi_extinction_threshold = 10L)
  initial_crossing <- run_grizzly_benchmark(
    "baseline", parameters, n_runs = 1L, n_steps = 1L, seed = 13L
  )$benchmark_summary
  expect_true(initial_crossing$run_summary$quasi_extinct)
  expect_identical(initial_crossing$run_summary$quasi_extinction_phase, "initial")
  expect_identical(initial_crossing$run_summary$quasi_extinction_time, 0L)

  parameters$quasi_extinction_threshold <- 0L
  parameters$immigration_count <- 1L
  scenario <- grizzly_benchmark_scenario(
    "immigration", parameters, n_runs = 1L, n_steps = 1L, seed = 14L
  )
  scenario$init_fun <- function() {
    grizzly_benchmark_initial_state(0L, 0L, 0L, 0L, parameters)
  }
  output <- run_scenario(scenario)
  benchmark <- scenario$benchmark
  benchmark$initial_state_spec <- list(
    n_females = 0L, n_males = 0L, dependent_females = 0L, dependent_males = 0L
  )
  benchmark$parameter_hash <- "explicit-empty-initial-test"
  summary <- summarise_grizzly_benchmark(output, benchmark)
  expect_true(summary$run_summary$initial_abundance == 0L)
  expect_true(is.na(summary$run_summary$finite_growth))
  expect_true(summary$run_summary$quasi_extinct)
  expect_identical(summary$run_summary$quasi_extinction_phase, "initial")
  expect_identical(summary$run_summary$quasi_extinction_time, 0L)
  expect_true(any(output$sim_output$events$event_type == "introduction"))
})

test_that("immigration is positioned, configured and recorded end to end", {
  parameters <- grizzly_benchmark_parameters(horizon = 1L)
  parameters$immigration_count <- 2.0
  parameters$immigration_age <- 4.0
  process <- grizzly_benchmark_processes(parameters, "immigration", include_observation = FALSE)
  immigration <- process[[which(vapply(process, function(x) x$name == "immigration", logical(1)))[[1L]]]]
  expect_identical(immigration$params$count, 2L)
  expect_identical(immigration$params$model$age, 4L)
  expect_identical(immigration$params$model$sexes, c("M", "F"))
  expect_identical(immigration$params$source, "illustrative translocation")
  expect_identical(
    vapply(process, `[[`, character(1), "name"),
    c(
      "environment", "age", "dependency", "breeding_eligibility",
      "reproduction", "dependent_survival", "independent_survival",
      "immigration", "census"
    )
  )
  output <- run_grizzly_benchmark(
    "immigration", parameters, n_runs = 1L, n_steps = 1L, seed = 18L
  )
  introductions <- output$sim_output$events[
    output$sim_output$events$event_type == "introduction", , drop = FALSE
  ]
  expect_identical(nrow(introductions), 1L)
  expect_identical(introductions$value, 2L)
  expect_identical(introductions$source, "illustrative translocation")
  newcomers <- tail(output$sim_output$runs[[1L]]$population, 2L)
  expect_identical(
    lapply(newcomers, function(individual) {
      individual[c("sex", "age", "dependency", "reproductive_status")]
    }),
    list(
      list(
        sex = "M", age = 4L, dependency = "independent",
        reproductive_status = "ineligible"
      ),
      list(
        sex = "F", age = 4L, dependency = "independent",
        reproductive_status = "ineligible"
      )
    )
  )
  summary_introductions <- output$benchmark_summary$events[
    output$benchmark_summary$events$event_type == "introduction", , drop = FALSE
  ]
  expect_identical(summary_introductions$source, "illustrative translocation")
})

test_that("source and unit metadata reject missing or blank values", {
  parameters <- grizzly_benchmark_parameters(horizon = 1L)
  parameters$source_label <- ""
  expect_error(grizzly_benchmark_processes(parameters, "baseline"), "source-labelled")
  parameters <- grizzly_benchmark_parameters(horizon = 1L)
  parameters$units$human_mortality <- NA_character_
  expect_error(grizzly_benchmark_processes(parameters, "baseline"), "units")
  parameters <- grizzly_benchmark_parameters(horizon = 1L)
  parameters$units$time <- ""
  expect_error(grizzly_benchmark_processes(parameters, "baseline"), "units")
})

test_that("canonical runner rejects mutable scenario objects and generic summaries need metadata", {
  scenario <- grizzly_benchmark_scenario("baseline", n_runs = 1L, n_steps = 1L)
  expect_error(run_grizzly_benchmark(scenario), "arg|scenario")
  output <- run_scenario(scenario)
  expect_error(summarise_grizzly_benchmark(output), "explicit benchmark metadata")
  expect_true(is.list(summarise_grizzly_benchmark(output, scenario$benchmark)))
  output$scenario$benchmark <- NULL
  output$sim_output$provenance$benchmark <- NULL
  expect_error(summarise_grizzly_benchmark(output), "explicit benchmark metadata")
})

test_that("female survival alternatives wire exact effective rates", {
  parameters <- grizzly_benchmark_parameters(horizon = 1L)
  state <- grizzly_benchmark_initial_state(1L, 0L, 0L, 0L, parameters)
  state$globals$environment_modifier <- 0.9
  individual <- state$population[[1L]]
  survival <- function(scenario) {
    processes <- grizzly_benchmark_processes(
      parameters, scenario, include_observation = FALSE
    )
    processes[[which(vapply(
      processes,
      function(process) identical(process$name, "independent_survival"),
      logical(1)
    ))[[1L]]]]
  }
  low <- survival("female_low_survival")
  high <- survival("female_high_survival")
  effective_rate <- function(process) {
    process$params$probability(
      individual, state, list(), process$params$model
    )
  }
  expect_identical(low$params$model$female_survival, parameters$female_survival[["low"]])
  expect_identical(high$params$model$female_survival, parameters$female_survival[["high"]])
  expect_equal(
    effective_rate(low),
    parameters$female_survival[["low"]] * state$globals$environment_modifier
  )
  expect_equal(
    effective_rate(high),
    parameters$female_survival[["high"]] * state$globals$environment_modifier
  )
  expect_lt(effective_rate(low), effective_rate(high))
})
