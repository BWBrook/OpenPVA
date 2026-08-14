test_that("scenario_spec validates and exposes the ordered biological program", {
  processes <- list(age_process(), constant_survival_process(1), census_process())
  scenario <- scenario_spec(
    "minimal",
    2L,
    3L,
    function() make_test_population(4L),
    processes,
    seed = 41L,
    record_population_history = TRUE
  )
  expect_s3_class(scenario, "openpva_scenario")
  expect_identical(vapply(scenario$processes, `[[`, character(1), "name"),
                   c("age", "survival", "census"))
  output <- run_scenario(scenario)$sim_output
  expect_length(output$runs, 2L)
  expect_length(output$runs[[1L]]$population_history, 3L)
  expect_identical(output$provenance$rng_kind, "L'Ecuyer-CMRG")
})

test_that("process validation rejects malformed objects and context writes", {
  expect_error(pva_process("x", 1), "must be a function")
  expect_error(
    pva_process("x", function(state, context, params) pva_result(state),
                writes = "context.time"),
    "engine-owned context"
  )
  expect_error(
    scenario_spec("bad", 1.5, 2L, function() list(), list(age_process())),
    "n_runs must be a single positive integer"
  )
})

test_that("scenario execution prepares static process validation once", {
  scenario <- scenario_spec(
    "static-execution-metadata",
    n_runs = 2L,
    n_steps = 4L,
    init_fun = function() make_test_population(4L),
    processes = list(age_process(), zero_birth_process(), census_process()),
    seed = 8005L
  )
  original_validate_process <- .validate_process
  original_validate_field_plan <- .validate_process_field_plan
  original_build_plan <- .build_process_plan
  calls <- new.env(parent = emptyenv())
  calls$process <- 0L
  calls$field_plan <- 0L
  calls$build_plan <- 0L
  testthat::local_mocked_bindings(
    .validate_process = function(...) {
      calls$process <- calls$process + 1L
      original_validate_process(...)
    },
    .validate_process_field_plan = function(...) {
      calls$field_plan <- calls$field_plan + 1L
      original_validate_field_plan(...)
    },
    .build_process_plan = function(...) {
      calls$build_plan <- calls$build_plan + 1L
      original_build_plan(...)
    },
    .package = "OpenPVA"
  )

  expect_silent(run_scenario(scenario))
  expect_identical(calls$process, 3L)
  expect_identical(calls$field_plan, 2L)
  expect_identical(calls$build_plan, 1L)
})
