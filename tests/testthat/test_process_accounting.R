test_that("state, event, identifier, and accounting contracts reject silent changes", {
  population <- make_test_population(2L)
  state <- pva_state(population)

  expect_error(
    pva_state(list(population[[1L]], population[[1L]])),
    "unique"
  )
  expect_error(
    pva_state(population, next_id = 9L),
    "max\\(population id\\) \\+ 1"
  )

  silent_death <- pva_process(
    "silent_death",
    function(state, context, params) {
      state$population[[1L]]$alive <- FALSE
      pva_result(state)
    },
    requires = c("population.id", "population.alive"),
    writes = "population.alive"
  )
  expect_error(
    execute_processes(state, list(silent_death)),
    "reported 0 death/removal"
  )

  silent_swap <- pva_process(
    "silent_swap",
    function(state, context, params) {
      state$population[[2L]]$id <- state$next_id
      state$next_id <- state$next_id + 1L
      pva_result(state)
    },
    requires = c("population.id", "next_id"),
    writes = c("population", "population.id", "next_id"),
    creates = "population.id"
  )
  expect_error(
    execute_processes(state, list(silent_swap)),
    "changed an existing population id"
  )

  removal <- pva_process(
    "project_removal",
    function(state, context, params) {
      state$population[[1L]]$alive <- FALSE
      pva_result(state, list(list(event_type = "removal", value = 1L, cause = "fixture")))
    },
    requires = c("population.id", "population.alive"),
    writes = "population.alive"
  )
  result <- execute_processes(state, list(removal), run = 7L, time = 3L)
  expect_identical(
    names(result$events)[1:7],
    c("run", "time", "process_index", "process_name", "process_occurrence", "phase", "event_type")
  )
  expect_identical(result$events$value, 1L)
  expect_identical(result$events$process_name, "project_removal")
})

test_that("population records keep stable position and identity", {
  id_only <- pva_state(list(list(id = 1), list(id = 2)), next_id = 3)
  structural_process <- function(name, transform, requires = "population.id", creates = "population.id") {
    pva_process(
      name,
      function(state, context, params) pva_result(params$transform(state)),
      params = list(transform = transform),
      requires = requires,
      writes = c("population", "next_id"),
      creates = creates
    )
  }

  physical_removal <- structural_process("physical_removal", function(state) {
    state$population <- state$population[-1L]
    state
  })
  expect_error(
    execute_processes(id_only, list(physical_removal)),
    "physically removed population records"
  )

  permutation <- structural_process("permutation", function(state) {
    state$population <- rev(state$population)
    state
  })
  expect_error(
    execute_processes(id_only, list(permutation)),
    "reordered records or changed an existing population id"
  )

  abundance_neutral_id_swap <- structural_process("id_swap", function(state) {
    state$population[[2L]]$id <- state$next_id
    state$next_id <- state$next_id + 1L
    state
  })
  expect_error(
    execute_processes(id_only, list(abundance_neutral_id_swap)),
    "changed an existing population id"
  )

  population <- make_test_population(2L)
  same_id_replacement <- structural_process(
    "same_id_replacement",
    function(state) {
      state$population[[1L]] <- list(
        id = state$population[[1L]]$id,
        sex = "M",
        age = 99L,
        alive = TRUE
      )
      state
    },
    requires = c("population.id", "population.age"),
    creates = c("population.id", "population.age")
  )
  expect_error(
    execute_processes(pva_state(population), list(same_id_replacement)),
    "changed undeclared field"
  )

  expect_error(
    pva_process(
      "generic_population_write",
      function(state, context, params) pva_result(state),
      writes = "population"
    ),
    "reserved for declared creation processes"
  )
})

test_that("integer-like population inputs are validated before coercion", {
  individual <- create_individual(
    id = 1,
    sex = "F",
    age = 2,
    mother_id = NA_integer_,
    father_id = 3,
    patch_id = 4
  )
  expect_identical(individual$id, 1L)
  expect_identical(individual$age, 2L)
  expect_identical(individual$mother_id, NA_integer_)
  expect_identical(individual$father_id, 3L)
  expect_identical(individual$patch_id, 4L)

  state <- pva_state(
    list(list(id = 1, age = 2, mother_id = NA_integer_, patch_id = 4)),
    next_id = 2
  )
  expect_identical(state$population[[1L]]$id, 1L)
  expect_identical(state$population[[1L]]$age, 2L)
  expect_identical(state$population[[1L]]$mother_id, NA_integer_)
  expect_identical(state$population[[1L]]$patch_id, 4L)
  expect_identical(state$next_id, 2L)

  expect_error(create_individual(1.5, "F", 2), "id.*integer-like")
  expect_error(create_individual(1, "F", 2.5), "age.*integer-like")
  expect_error(create_individual(1, "F", 2, mother_id = 1.5), "mother_id.*integer-like")
  expect_error(create_individual(1, "F", 2, father_id = 1.5), "father_id.*integer-like")
  expect_error(create_individual(1, "F", 2, patch_id = 1.5), "patch_id.*integer-like")
  expect_error(
    create_individual(.Machine$integer.max + 1, "F", 2),
    "representable as an R integer"
  )

  expect_error(pva_state(list(list(id = 1.5)), next_id = 2), "id.*integer-like")
  expect_error(pva_state(list(list(id = 1, age = 2.5)), next_id = 2), "age.*integer-like")
  expect_error(
    pva_state(list(list(id = 1, mother_id = 1.5)), next_id = 2),
    "mother_id.*integer-like"
  )
  expect_error(
    pva_state(list(list(id = 1, patch_id = .Machine$integer.max + 1)), next_id = 2),
    "patch_id.*representable"
  )
  expect_error(pva_state(list(list(id = 1)), next_id = 2.5), "next_id.*integer-like")
})

test_that("event provenance fields and event names cannot be overwritten", {
  event_process <- function(name, event) {
    pva_process(
      name,
      function(state, context, params) pva_result(state, list(params$event)),
      params = list(event = event)
    )
  }

  expect_error(
    execute_processes(
      pva_state(list()),
      list(event_process("phase_writer", list(event_type = "observation", phase = "other")))
    ),
    "engine-owned column.*phase"
  )

  duplicate <- list(event_type = "observation", 1L, 2L)
  names(duplicate) <- c("event_type", "detail", "detail")
  expect_error(
    execute_processes(
      pva_state(list()),
      list(event_process("duplicate_fields", duplicate))
    ),
    "duplicate field names"
  )
})

test_that("retired incompatible helpers are absent from the public surface", {
  exports <- getNamespaceExports("OpenPVA")
  expect_false("apply_reproduction" %in% exports)
  expect_false("make_mate_limited_mating_fun" %in% exports)
  expect_false("summarise_sensitivity_oat" %in% exports)
  expect_true("reproduction_process" %in% exports)
  expect_true("summarise_sensitivity_prcc" %in% exports)
})

test_that("project-defined observation and management processes need no controller edit", {
  observer <- pva_process(
    "project_observer",
    function(state, context, params) {
      n_female <- sum(vapply(
        state$population,
        function(ind) isTRUE(ind$alive) && identical(ind$sex, "F"),
        logical(1)
      ))
      pva_result(state, list(list(event_type = "observation", value = n_female)))
    },
    requires = c("population.sex", "population.alive")
  )
  manager <- pva_process(
    "project_management",
    function(state, context, params) {
      alive <- which(vapply(state$population, function(ind) isTRUE(ind$alive), logical(1)))
      if (!length(alive)) return(pva_result(state))
      state$population[[alive[[1L]]]]$alive <- FALSE
      pva_result(state, list(list(event_type = "removal", value = 1L)))
    },
    requires = c("population.id", "population.alive"),
    writes = "population.alive"
  )
  scenario <- scenario_spec(
    "external-processes",
    1L,
    1L,
    function() make_test_population(4L),
    list(observer, manager, census_process()),
    seed = 3L
  )
  events <- run_scenario(scenario)$sim_output$events
  expect_identical(
    events$process_name,
    c("project_observer", "project_management", "census")
  )
  expect_identical(events$event_type, c("observation", "removal", "census"))
})
