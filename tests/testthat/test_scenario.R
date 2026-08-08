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
