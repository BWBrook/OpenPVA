test_that("process objects validate their declarations", {
  run <- function(state, context, params) pva_result(state)
  expect_s3_class(pva_process("p", run), "pva_process")
  expect_output(print(pva_process("p", run, writes = "globals.x")), "writes: globals.x")
  expect_error(pva_process("", run), "non-empty")
  expect_error(pva_process("p", function(state) state), "state, context, params")
  expect_error(pva_process("p", run, writes = "age"), "field paths")
  expect_error(pva_process("p", run, writes = "population.id"), "engine-owned")
  expect_error(pva_process("p", run, writes = "population.pedigree_F"), "engine-owned")
  expect_error(pva_process("p", run, creates = "sex"), "sex and age")
  expect_error(pva_process("p", run, creates = c("sex", "age", "origin")), "engine-owned")
  expect_error(validate_processes(list()), "non-empty ordered list")
  expect_error(pva_result(list(), events = list(a = 1)), "pva_events")
  expect_error(pva_result(list(), census = c(1, 2)), "named numeric")
  expect_error(pva_events("death", value = NA), "non-missing numeric")
})

test_that("the field plan is checked before any process runs", {
  state <- pva_state(adult_population(2L, 2L, patch = "a"))
  needs_global <- pva_process(
    "reader", function(state, context, params) pva_result(state),
    requires = "globals.weather"
  )
  expect_error(execute_processes(state, list(needs_global)), "neither in the initial state")
  writer <- environment_process(list(weather = function(state, context, params) 1))
  expect_silent(validate_processes(list(writer, needs_global), state))
  expect_error(validate_processes(list(needs_global, writer), state), "written upstream")

  # A creator that would leave a field uninitialised fails at preflight.
  breeding <- reproduction_process(1, litter_poisson(1), offspring_sex_bernoulli())
  expect_error(execute_processes(state, list(breeding)), "without initialising: patch")
  unknown <- pva_process(
    "w", function(state, context, params) pva_result(state),
    writes = "population.absent"
  )
  expect_error(execute_processes(state, list(unknown)), "absent from the initial state")
})

test_that("strict validation rejects undeclared and engine-owned changes", {
  state <- pva_state(adult_population(3L, 3L), globals = list(k = 1))
  run_one <- function(run, ...) {
    execute_processes(state, list(custom_process(run, ...)))
  }
  expect_error(run_one(function(state, context, params) {
    state$population$age <- state$population$age + 1L
    pva_result(state)
  }), "undeclared field population.age")
  expect_error(run_one(function(state, context, params) {
    state$globals$k <- 2
    pva_result(state)
  }), "undeclared field globals.k")
  expect_error(run_one(function(state, context, params) {
    state$population <- lapply(state$population, `[`, -1L)
    pva_result(state)
  }), "deleted population records")
  expect_error(run_one(function(state, context, params) {
    state$population$id <- rev(state$population$id)
    pva_result(state)
  }), "undeclared field population.id")
  expect_error(run_one(function(state, context, params) {
    state$population$age <- as.numeric(state$population$age)
    pva_result(state)
  }, writes = "population.age"), "wrong type or length")
  expect_error(run_one(function(state, context, params) {
    state$population$age[[1L]] <- NA
    pva_result(state)
  }, writes = "population.age"), "missing values")
  expect_error(run_one(function(state, context, params) {
    state$next_id <- state$next_id + 1L
    pva_result(state)
  }), "changed next_id")
  expect_error(run_one(function(state, context, params) state), "must return pva_result")
  expect_error(run_one(function(state, context, params) {
    pva_result(add_individuals(state, sex = "F", age = 0L), pva_events("birth", 1))
  }), "without a creates declaration")
})

test_that("omitted or mistyped accounting events are caught", {
  state <- pva_state(adult_population(4L, 4L))
  kill <- function(events) {
    custom_process(function(state, context, params) {
      state$population$alive[1:2] <- FALSE
      pva_result(state, events)
    }, writes = "population.alive")
  }
  expect_error(execute_processes(state, list(kill(NULL))), "accounting mismatch: 2 existing")
  expect_error(
    execute_processes(state, list(kill(pva_events("death", 1)))),
    "accounting mismatch"
  )
  expect_error(
    execute_processes(state, list(kill(pva_events(c("death", "removal"), c(1, 1))))),
    "one loss type"
  )
  expect_error(
    execute_processes(state, list(kill(pva_events("death", 2.5)))),
    "negative or fractional"
  )
  ok <- execute_processes(state, list(kill(pva_events("removal", 2, "cull"))))
  expect_identical(ok$accounting$removals_resident, 2L)
  expect_identical(length(ok$state$population$id), 6L)
  expect_identical(ok$ledger$exit_type[1:2], c("removal", "removal"))
})

test_that("compensating errors that preserve net abundance are caught", {
  state <- pva_state(adult_population(4L, 4L))
  swap <- function(events) {
    custom_process(function(state, context, params) {
      state$population$alive[[1L]] <- FALSE
      state <- add_individuals(state, sex = "F", age = 0L)
      pva_result(state, events)
    }, writes = "population.alive", creates = c("sex", "age"))
  }
  # One unreported death offset by one unreported birth: net N is unchanged,
  # so reconciliation of aggregate abundance alone would pass.
  silent <- suppressWarnings(execute_processes(
    state, list(swap(NULL)), validation = "fast"
  ))
  expect_identical(silent$accounting$n_before, silent$accounting$n_after)
  expect_error(execute_processes(state, list(swap(NULL))), "accounting mismatch")
  # Reporting only the birth, or only the death, is still caught.
  expect_error(
    execute_processes(state, list(swap(pva_events("birth", 1)))),
    "1 existing individual\\(s\\) stopped living"
  )
  expect_error(
    execute_processes(state, list(swap(pva_events("death", 1)))),
    "1 individual\\(s\\) were created"
  )
  honest <- execute_processes(
    state, list(swap(pva_events(c("death", "birth"), c(1, 1))))
  )
  expect_identical(honest$accounting$deaths_resident, 1L)
  expect_identical(honest$accounting$births, 1L)

  stillborn <- custom_process(function(state, context, params) {
    state <- add_individuals(state, sex = "F", age = 0L)
    state$population$alive[[length(state$population$alive)]] <- FALSE
    pva_result(state, pva_events("birth", 1))
  }, writes = "population.alive", creates = c("sex", "age"))
  expect_error(execute_processes(state, list(stillborn)), "not alive when it returned")
})

test_that("cohort accounting exposes released animals charged a full interval of mortality", {
  annual <- 0.64
  n_release <- 20L
  release <- introduction_process(
    count = n_release,
    fields = function(n, state, context, params) {
      list(sex = rep(c("F", "M"), length.out = n), age = 2L, survival_draw = NA_real_)
    },
    creates = c("sex", "age", "survival_draw")
  )
  pre <- staged_survival_process(annual, post_share = 0.5, stage = "pre")
  post <- staged_survival_process(annual, post_share = 0.5, stage = "post")
  run <- function(processes) {
    run_scenario(scenario_spec(
      name = "release_timing", n_runs = 400L, n_steps = 1L, seed = 11L,
      init_fun = function() adult_population(20L, 20L, survival_draw = NA_real_),
      processes = c(processes, list(census_process()))
    ))
  }
  correct <- run(list(pre, release, post))
  faulty <- run(list(release, pre, post))

  # Both lifecycles reconcile in aggregate and give plausible abundances.
  for (result in list(correct, faulty)) {
    expect_true(all(summarise_accounting(result)$reconciled))
  }
  expect_gt(mean(faulty$census$n_alive), 30)

  introduced_deaths <- function(result, process) {
    names <- result$provenance$process_plan$process_name
    result$accounting$deaths_introduced[names[result$accounting$process_index] == process]
  }
  # Correct: released animals are exposed only to the post-release stage.
  expect_identical(sum(introduced_deaths(correct, "survival_pre")), 0L)
  expect_gt(sum(introduced_deaths(faulty, "survival_pre")), 0L)

  survivors <- function(result) {
    n_release - summarise_accounting(result)$deaths_introduced
  }
  z <- function(result, expected) {
    x <- survivors(result)
    (mean(x) - expected) / (stats::sd(x) / sqrt(length(x)))
  }
  expect_lt(abs(z(correct, n_release * sqrt(annual))), 3)
  expect_gt(abs(z(faulty, n_release * sqrt(annual))), 10)
  expect_lt(abs(z(faulty, n_release * annual)), 3)
})

test_that("events, census, context and repeated processes are recorded", {
  seen <- NULL
  probe <- custom_process(function(state, context, params) {
    seen <<- context
    pva_result(state, pva_events("note", 3, "probe"))
  }, name = "probe")
  state <- pva_state(adult_population(2L, 1L))
  out <- execute_processes(
    state, list(census_process(name = "before"), probe, probe, census_process()),
    time = 4L, run = 2L, dt = 0.5
  )
  expect_identical(seen$time, 4L)
  expect_identical(seen$run, 2L)
  expect_identical(seen$dt, 0.5)
  expect_identical(seen$process_index, 3L)
  expect_identical(seen$occurrence, 2L)
  expect_identical(seen$phase, "interval")
  expect_identical(out$events$occurrence, 1:2)
  expect_identical(out$events$label, c("probe", "probe"))
  expect_identical(out$census$process_name, c("before", "census"))
  expect_identical(out$census$n_alive, c(3, 3))
  expect_identical(nrow(out$accounting), 4L)
})

test_that("individual accounting receipts cannot offset invalid counts", {
  state <- pva_state(adult_population())
  for (values in list(c(2, -1), c(0.5, 0.5), c(Inf, 0))) {
    loss <- custom_process(function(state, context, params) {
      state$population$alive[1L] <- FALSE
      pva_result(state, pva_events(c("death", "death"), values))
    }, writes = "population.alive")
    expect_error(execute_processes(state, list(loss)), "accounting event value")
  }
})

test_that("patch flows include stays and use distinct origin and destination columns", {
  state <- pva_state(adult_population(3L, 1L, patch_id = c("A", "A", "B", "B")))
  flow <- dispersal_process(function(...) c("A", "B", "B"),
                            patches = c("A", "B"), eligible = function(pop, ...) pop$sex == "F")
  events <- execute_processes(state, list(flow))$events
  moves <- events[events$event_type == "patch_transition", ]
  expect_identical(moves$origin_patch_id, c("A", "A", "B"))
  expect_identical(moves$destination_patch_id, c("A", "B", "B"))
  expect_equal(moves$value, c(1, 1, 1))
  expect_equal(events$value[events$event_type == "dispersal"], 1)
})

test_that("NA selection is rejected and environmental updates follow list order", {
  state <- pva_state(adult_population(1, 1))
  remove <- removal_process(select = function(...) c(TRUE, NA))
  expect_error(execute_processes(state, list(remove)), "non-missing")
  expect_identical(shift_logit(c(0, 1, 0.5), c(Inf, -Inf, -Inf)), c(0, 1, 0))
  env <- environment_process(list(first = function(...) 2,
                                  second = function(state, ...) state$globals$first + 3))
  expect_equal(execute_processes(state, list(env))$state$globals$second, 5)
})
