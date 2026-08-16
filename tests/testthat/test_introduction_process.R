test_that("zero, fixed and dynamic introduction counts are exact", {
  state <- pva_state(
    make_test_population(2L),
    globals = list(marker = list(value = 7L))
  )
  zero <- introduction_process(
    count = 0L,
    initializer = function(index, id, state, context, params) {
      stop("zero-count initializer must not run")
    },
    initializer_fields = "sex",
    source = "zero fixture"
  )
  zero_result <- execute_processes(state, list(zero), run = 2L, time = 3L)
  expect_identical(zero_result$state, state)
  expect_equal(nrow(zero_result$events), 0L)

  fixed <- introduction_process(
    count = 2.0,
    initializer = function(index, id, state, context, params) {
      list(sex = c("F", "M")[[index]], age = 3L)
    },
    initializer_fields = c("sex", "age"),
    source = " fixed fixture ",
    name = "stocking"
  )
  fixed_result <- execute_processes(state, list(fixed), run = 2L, time = 3L)
  newcomers <- tail(fixed_result$state$population, 2L)
  expect_identical(
    fixed_result$state$population[seq_along(state$population)],
    state$population
  )
  expect_identical(fixed_result$state$globals, state$globals)
  expect_identical(vapply(newcomers, `[[`, integer(1), "id"), c(3L, 4L))
  expect_identical(vapply(newcomers, `[[`, logical(1), "alive"), c(TRUE, TRUE))
  expect_identical(fixed_result$state$next_id, 5L)
  expect_identical(fixed_result$events$value, 2L)
  expect_identical(fixed_result$events$source, "fixed fixture")
  dynamic <- introduction_process(
    count = function(state, context, params) {
      length(state$population) + context$time + params$extra
    },
    initializer = function(index, id, state, context, params) list(),
    initializer_fields = character(),
    source = "dynamic fixture",
    params = list(extra = 1L)
  )
  dynamic_result <- execute_processes(state, list(dynamic), time = 1L)
  expect_identical(length(dynamic_result$state$population), 6L)
  expect_identical(dynamic_result$events$value, 4L)
})

test_that("invalid fixed and callback counts fail before allocation", {
  constructor <- function(count) {
    introduction_process(
      count = count,
      initializer = function(index, id, state, context, params) list(),
      initializer_fields = character(),
      source = "count validation fixture"
    )
  }
  expect_error(constructor(1.5), "count")
  expect_error(constructor(.Machine$integer.max + 1), "count")

  process <- constructor(function(state, context, params) -1)
  expect_error(
    execute_processes(pva_state(list()), list(process)),
    "count callback result"
  )

  exhausted <- pva_state(
    list(list(id = .Machine$integer.max - 1L)),
    next_id = .Machine$integer.max
  )
  expect_error(
    execute_processes(exhausted, list(constructor(1L))),
    "identifier allocation exceeds R's integer range"
  )
})

test_that("initializer fields are exact and engine fields are reserved", {
  initializer <- function(index, id, state, context, params) {
    list(sex = "F", age = 2L)
  }
  expect_error(
    introduction_process(1L, initializer, c("id", "sex"), "fixture"),
    "cannot override engine introduction fields"
  )
  expect_error(
    introduction_process(1L, initializer, c("sex", "sex"), "fixture"),
    "must not contain duplicates"
  )
  expect_error(
    introduction_process(1L, initializer, "population.sex", "fixture"),
    "without population. prefixes"
  )

  missing <- introduction_process(
    1L,
    function(index, id, state, context, params) list(sex = "F"),
    c("sex", "age"),
    "fixture"
  )
  expect_error(
    execute_processes(pva_state(list()), list(missing)),
    "exactly match initializer_fields"
  )
  extra <- introduction_process(
    1L,
    function(index, id, state, context, params) {
      list(sex = "F", age = 2L, cohort = "release")
    },
    c("sex", "age"),
    "fixture"
  )
  expect_error(
    execute_processes(pva_state(list()), list(extra)),
    "exactly match initializer_fields"
  )
  unnamed <- introduction_process(
    1L,
    function(index, id, state, context, params) list("F"),
    "sex",
    "fixture"
  )
  expect_error(
    execute_processes(pva_state(list()), list(unnamed)),
    "named list"
  )
  non_list <- introduction_process(
    1L,
    function(index, id, state, context, params) "F",
    "sex",
    "fixture"
  )
  expect_error(
    execute_processes(pva_state(list()), list(non_list)),
    "named list"
  )
  duplicate <- introduction_process(
    1L,
    function(index, id, state, context, params) {
      fields <- list("F", "M")
      names(fields) <- c("sex", "sex")
      fields
    },
    "sex",
    "fixture"
  )
  expect_error(
    execute_processes(pva_state(list()), list(duplicate)),
    "duplicate field names"
  )

  reordered <- introduction_process(
    1L,
    function(index, id, state, context, params) list(age = 2L, sex = "F"),
    c("sex", "age"),
    "fixture"
  )
  result <- execute_processes(pva_state(list()), list(reordered))
  expect_identical(
    names(result$state$population[[1L]]),
    c("id", "alive", "sex", "age")
  )

  wrong_core_type <- introduction_process(
    1L,
    function(index, id, state, context, params) list(age = 2),
    "age",
    "fixture"
  )
  expect_error(
    execute_processes(pva_state(list()), list(wrong_core_type)),
    "population.age must have type integer"
  )
})

test_that("all initializers see one pre-process state and append in allocator order", {
  state <- pva_state(
    make_test_population(2L),
    globals = list(marker = 11L)
  )
  before_population <- serialize(state$population, NULL)
  before_globals <- serialize(state$globals, NULL)
  process <- introduction_process(
    3L,
    function(index, id, state, context, params) {
      list(
        observed_n = as.integer(length(state$population)),
        observed_next_id = state$next_id,
        incoming_index = index
      )
    },
    c("observed_n", "observed_next_id", "incoming_index"),
    "pre-state fixture"
  )
  result <- execute_processes(state, list(process))
  newcomers <- tail(result$state$population, 3L)

  expect_identical(
    serialize(result$state$population[seq_len(2L)], NULL),
    before_population
  )
  expect_identical(serialize(result$state$globals, NULL), before_globals)
  expect_identical(vapply(newcomers, `[[`, integer(1), "id"), 3:5)
  expect_identical(vapply(newcomers, `[[`, integer(1), "observed_n"), rep(2L, 3L))
  expect_identical(
    vapply(newcomers, `[[`, integer(1), "observed_next_id"),
    rep(3L, 3L)
  )
  expect_identical(
    vapply(newcomers, `[[`, integer(1), "incoming_index"),
    1:3
  )
  expect_identical(result$state$next_id, 6L)
})

test_that("community initializer fields compose without an engine edit", {
  introduction <- introduction_process(
    2L,
    function(index, id, state, context, params) {
      list(community_score = as.integer(index * 10L))
    },
    "community_score",
    "community fixture"
  )
  observer <- pva_process(
    "community_observer",
    function(state, context, params) {
      score <- sum(vapply(
        state$population,
        `[[`,
        integer(1),
        "community_score"
      ))
      pva_result(
        state,
        list(list(event_type = "observation", value = as.integer(score)))
      )
    },
    requires = c(
      "population.id", "population.alive", "population.community_score"
    )
  )
  result <- execute_processes(pva_state(list()), list(introduction, observer))
  expect_identical(result$events$event_type, c("introduction", "observation"))
  expect_identical(result$events$value, c(2L, 30L))
})

test_that("downstream patch fields fail decisively or initialise correctly", {
  patches <- patch_density_snapshot_process(c(1L, 2L))
  missing_patch <- introduction_process(
    1L,
    function(index, id, state, context, params) list(sex = "F"),
    "sex",
    "spatial fixture"
  )
  expect_error(
    validate_processes(list(missing_patch, patches), pva_state(list())),
    "does not declare initialisation of: population.patch_id"
  )

  na_patch <- introduction_process(
    1L,
    function(index, id, state, context, params) list(patch_id = NA_integer_),
    "patch_id",
    "spatial fixture"
  )
  expect_error(
    execute_processes(pva_state(list()), list(na_patch, patches)),
    "does not initialise required field population.patch_id"
  )

  grouped <- introduction_process(
    3L,
    function(index, id, state, context, params) {
      list(patch_id = c(1L, 2L, 1L)[[index]])
    },
    "patch_id",
    "spatial fixture",
    group_by = "patch_id"
  )
  result <- execute_processes(
    pva_state(list()),
    list(grouped, patches),
    run = 4L,
    time = 2L
  )
  introductions <- result$events[
    result$events$event_type == "introduction", , drop = FALSE
  ]
  snapshots <- result$events[
    result$events$event_type == "patch_density_snapshot", , drop = FALSE
  ]
  expect_identical(introductions$patch_id, c(1L, 2L))
  expect_identical(introductions$value, c(2L, 1L))
  expect_identical(sum(introductions$value), 3L)
  expect_true(all(introductions$source == "spatial fixture"))
  expect_true(all(introductions$run == 4L & introductions$time == 2L))
  expect_identical(snapshots$patch_id, c(1L, 2L))
  expect_identical(snapshots$value, c(2L, 1L))
})

test_that("source and event grouping declarations are strict", {
  initializer <- function(index, id, state, context, params) {
    list(patch_id = 1L)
  }
  expect_error(
    introduction_process(1L, initializer, "patch_id", ""),
    "source must be a non-blank"
  )
  expect_error(
    introduction_process(
      1L, initializer, "patch_id", "fixture", group_by = "sex"
    ),
    "only declared initializer_fields"
  )
  expect_error(
    introduction_process(
      1L,
      function(index, id, state, context, params) list(source = "local"),
      "source",
      "fixture",
      group_by = "source"
    ),
    "event or engine provenance fields"
  )

  missing_group <- introduction_process(
    1L,
    function(index, id, state, context, params) list(cohort = NA_character_),
    "cohort",
    "fixture",
    group_by = "cohort"
  )
  expect_error(
    execute_processes(pva_state(list()), list(missing_group)),
    "group_by fields must be non-missing atomic scalars"
  )

  mutable <- introduction_process(
    1L, initializer, "patch_id", "fixture"
  )
  mutable$params$source <- ""
  expect_error(validate_processes(list(mutable)), "source must be a non-blank")
  mutable <- introduction_process(
    1L, initializer, "patch_id", "fixture"
  )
  mutable$params$initializer_fields <- character()
  expect_error(
    validate_processes(list(mutable)),
    "initializer_fields cannot be changed"
  )
})

test_that("introduction position relative to survival changes exposure", {
  introduction <- introduction_process(
    1L,
    function(index, id, state, context, params) list(),
    character(),
    "order fixture"
  )
  certain_death <- survival_process(
    probability = function(individual, state, context, params) 0,
    name = "certain_death"
  )

  exposed <- execute_processes(
    pva_state(list()),
    list(introduction, certain_death)
  )
  deferred <- execute_processes(
    pva_state(list()),
    list(certain_death, introduction)
  )
  expect_false(exposed$state$population[[1L]]$alive)
  expect_true(deferred$state$population[[1L]]$alive)
  expect_identical(exposed$events$event_type, c("introduction", "death"))
  expect_identical(deferred$events$event_type, "introduction")
})

test_that("stochastic counts and initializers match independent expectations", {
  process <- introduction_process(
    count = function(state, context, params) {
      stats::rbinom(1L, size = params$trials, prob = params$arrival_probability)
    },
    initializer = function(index, id, state, context, params) {
      list(
        sex = if (stats::runif(1L) < params$female_probability) "F" else "M",
        age = 0L
      )
    },
    initializer_fields = c("sex", "age"),
    source = "stochastic fixture",
    params = list(
      trials = 4L,
      arrival_probability = 0.25,
      female_probability = 0.30
    )
  )
  n_runs <- 400L
  scenario <- scenario_spec(
    "stochastic-introductions",
    n_runs = n_runs,
    n_steps = 1L,
    init_fun = function() pva_state(list()),
    processes = list(process, census_process()),
    seed = 6026L
  )
  output <- run_scenario(scenario)
  counts <- vapply(
    output$sim_output$runs,
    function(run) length(run$population),
    integer(1)
  )
  females <- vapply(output$sim_output$runs, function(run) {
    sum(vapply(
      run$population,
      function(individual) identical(individual$sex, "F"),
      logical(1)
    ))
  }, numeric(1))

  expected_count <- 4 * 0.25
  count_mcse <- sqrt(4 * 0.25 * 0.75 / n_runs)
  expected_females <- 4 * 0.25 * 0.30
  female_probability <- 0.25 * 0.30
  female_mcse <- sqrt(
    4 * female_probability * (1 - female_probability) / n_runs
  )
  expect_lt(abs(mean(counts) - expected_count), 6 * count_mcse)
  expect_lt(abs(mean(females) - expected_females), 6 * female_mcse)
})
