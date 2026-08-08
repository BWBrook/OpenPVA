test_that("initial and interval-zero censuses are explicit and distinct", {
  census <- census_process(
    summarise = function(state, context, params) {
      alive <- Filter(function(ind) isTRUE(ind$alive), state$population)
      list(
        n_alive = as.integer(length(alive)),
        mean_age = mean(vapply(alive, `[[`, integer(1), "age"))
      )
    }
  )
  scenario <- scenario_spec(
    "time-contract",
    n_runs = 1L,
    n_steps = 2L,
    init_fun = function() list(create_individual(1L, "F", 2L)),
    processes = list(age_process(), census),
    initial_census = census,
    seed = 12L
  )

  census_events <- run_scenario(scenario)$sim_output$census
  expect_identical(census_events$time, c(0L, 0L, 1L))
  expect_identical(census_events$phase, c("initial", "interval", "interval"))
  expect_equal(census_events$mean_age, c(2, 3, 4))
})
