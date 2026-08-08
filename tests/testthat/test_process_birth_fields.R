test_that("newborn patch requirements fail at preflight and against a lying creator", {
  population <- list(
    create_individual(1L, "F", 4L, patch_id = 1L),
    create_individual(2L, "M", 5L, patch_id = 1L)
  )
  patch_observer <- pva_process(
    "patch_observer",
    function(state, context, params) {
      pva_result(state, list(list(event_type = "observation", value = length(state$population))))
    },
    requires = c("population.id", "population.patch_id")
  )
  incomplete_birth <- reproduction_process(
    breeding_probability = function(mother, state, context, params) 1,
    fecundity_mean = function(mother, state, context, params) 1
  )
  expect_error(
    validate_processes(list(incomplete_birth, patch_observer), pva_state(population)),
    "population.patch_id.*required by patch_observer"
  )

  lying_birth <- pva_process(
    "lying_birth",
    function(state, context, params) {
      id <- state$next_id
      state$next_id <- state$next_id + 1L
      state$population[[length(state$population) + 1L]] <- list(
        id = id,
        sex = "F",
        age = 0L,
        alive = TRUE
      )
      pva_result(state, list(list(event_type = "birth", value = 1L)))
    },
    requires = c("population.id", "next_id"),
    writes = c("population", "next_id"),
    creates = c(
      "population.id", "population.sex", "population.age",
      "population.alive", "population.patch_id"
    )
  )
  expect_error(
    execute_processes(pva_state(population), list(lying_birth, patch_observer)),
    "does not initialise required field population.patch_id"
  )
})
test_that("the birth fixture owns maternal patch inheritance", {
  population <- list(
    create_individual(1L, "F", 4L, patch_id = 2L),
    create_individual(2L, "M", 5L, patch_id = 2L)
  )
  birth <- reproduction_process(
    breeding_probability = function(mother, state, context, params) 1,
    fecundity_mean = function(mother, state, context, params) 8,
    offspring_sex = function(mother, father, state, context, params) "F",
    inherit_fields = "patch_id"
  )
  patch_observer <- pva_process(
    "patch_observer",
    function(state, context, params) {
      pva_result(state, list(list(event_type = "observation", value = length(state$population))))
    },
    requires = c("population.id", "population.patch_id")
  )
  scenario <- scenario_spec(
    "patch-birth",
    1L,
    1L,
    function() population,
    list(birth, patch_observer),
    seed = 15L
  )
  final_population <- run_scenario(scenario)$sim_output$runs[[1L]]$population
  newborns <- Filter(function(ind) ind$age == 0L, final_population)
  expect_gt(length(newborns), 0L)
  expect_true(all(vapply(newborns, `[[`, integer(1), "patch_id") == 2L))
})
