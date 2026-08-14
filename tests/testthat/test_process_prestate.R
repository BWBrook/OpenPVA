test_that("survival callbacks share one pre-process state and deaths apply together", {
  population <- lapply(seq_len(3L), function(id) {
    create_individual(id, if (id == 3L) "M" else "F", age = 4L)
  })
  state <- pva_state(population)
  seen <- new.env(parent = emptyenv())
  seen$eligible <- integer()
  seen$probability <- integer()

  process <- survival_process(
    probability = function(individual, state, context, params) {
      seen$probability <- c(
        seen$probability,
        sum(vapply(state$population, `[[`, logical(1), "alive"))
      )
      0
    },
    eligible = function(individual, state, context, params) {
      seen$eligible <- c(
        seen$eligible,
        sum(vapply(state$population, `[[`, logical(1), "alive"))
      )
      TRUE
    }
  )

  set.seed(8001L)
  result <- execute_processes(state, list(process))

  expect_identical(seen$eligible, rep(3L, 3L))
  expect_identical(seen$probability, rep(3L, 3L))
  expect_false(any(vapply(result$state$population, `[[`, logical(1), "alive")))
  expect_identical(result$events$value, 3L)
  expect_true(all(vapply(state$population, `[[`, logical(1), "alive")))
})

test_that("state-independent survival retains sequential fixed-seed draws", {
  state <- pva_state(make_test_population(6L))
  seed <- 8006L
  set.seed(seed)
  expected_alive <- stats::runif(length(state$population)) < 0.57
  expected_seed <- .Random.seed

  process <- survival_process(
    probability = function(individual, state, context, params) 0.57
  )
  set.seed(seed)
  result <- execute_processes(state, list(process))

  expect_identical(
    vapply(result$state$population, `[[`, logical(1), "alive"),
    expected_alive
  )
  expect_identical(.Random.seed, expected_seed)
})

test_that("reproduction callbacks share one pre-process state and births append together", {
  population <- list(
    create_individual(1L, "F", age = 4L),
    create_individual(2L, "F", age = 5L),
    create_individual(3L, "M", age = 6L)
  )
  state <- pva_state(population)
  seen <- new.env(parent = emptyenv())
  seen$state <- list()
  seen$mating <- list()
  seen$order <- character()
  seen$sex_index <- 0L
  seen$initializer_index <- 0L
  record_state <- function(label, mother, state) {
    seen$order <- c(seen$order, paste0(label, ":", mother$id))
    seen$state[[length(seen$state) + 1L]] <- c(
      n_population = length(state$population),
      next_id = state$next_id
    )
  }

  process <- reproduction_process(
    breeding_probability = function(mother, state, context, params) {
      record_state("breeding", mother, state)
      1
    },
    fecundity_mean = function(mother, state, context, params) {
      record_state("fecundity", mother, state)
      20
    },
    offspring_sex = function(mother, father, state, context, params) {
      record_state("sex", mother, state)
      seen$sex_index <- seen$sex_index + 1L
      if (seen$sex_index %% 2L) "F" else "M"
    },
    mating = function(population, mother, context, params) {
      seen$order <- c(seen$order, paste0("mating:", mother$id))
      seen$mating[[length(seen$mating) + 1L]] <- vapply(
        population,
        `[[`,
        integer(1),
        "id"
      )
      population[[3L]]
    },
    require_mate = TRUE,
    newborn_initializer = function(mother, father, state, context, params) {
      record_state("initializer", mother, state)
      seen$initializer_index <- seen$initializer_index + 1L
      list(source_index = seen$initializer_index)
    },
    initializer_fields = "source_index"
  )

  set.seed(8002L)
  result <- execute_processes(state, list(process))
  n_births <- result$events$value[[1L]]
  newborns <- tail(result$state$population, n_births)

  expect_gt(n_births, 0L)
  expect_true(all(vapply(
    seen$state,
    function(x) identical(unname(x), c(3L, 4L)),
    logical(1)
  )))
  expect_true(all(vapply(seen$mating, identical, logical(1), 1:3)))
  expect_identical(seen$order[[1L]], "breeding:1")
  expect_identical(seen$order[[2L]], "mating:1")
  expect_identical(seen$order[[3L]], "fecundity:1")
  expect_true(match("breeding:2", seen$order) > match("initializer:1", seen$order))
  expect_identical(vapply(newborns, `[[`, integer(1), "id"), seq.int(4L, length.out = n_births))
  expect_identical(
    vapply(newborns, `[[`, integer(1), "source_index"),
    seq_len(n_births)
  )
  expect_identical(result$state$next_id, as.integer(4L + n_births))
  expect_identical(length(result$state$population), 3L + n_births)
  expect_identical(length(state$population), 3L)
})

test_that("offspring sex is an explicit required biological callback", {
  breeding <- function(mother, state, context, params) 0
  fecundity <- function(mother, state, context, params) 0

  expect_error(
    reproduction_process(breeding, fecundity),
    "offspring_sex.*missing"
  )
  expect_error(
    reproduction_process(breeding, fecundity, offspring_sex = NULL),
    "offspring_sex must be a function"
  )
})

test_that("state-independent reproduction retains sequential fixed-seed draws", {
  state <- pva_state(list(
    create_individual(1L, "F", age = 4L),
    create_individual(2L, "F", age = 5L)
  ))
  seed <- 8003L
  expected <- list()
  set.seed(seed)
  for (mother in state$population) {
    if (stats::runif(1L) < 0.65) {
      litter_size <- stats::rpois(1L, 1.4)
      for (index in seq_len(litter_size)) {
        expected[[length(expected) + 1L]] <- list(
          mother_id = mother$id,
          sex = sample(c("F", "M"), 1L)
        )
      }
    }
  }
  expected_seed <- .Random.seed

  process <- reproduction_process(
    breeding_probability = function(mother, state, context, params) 0.65,
    fecundity_mean = function(mother, state, context, params) 1.4,
    offspring_sex = function(mother, father, state, context, params) {
      sample(c("F", "M"), 1L)
    }
  )
  set.seed(seed)
  result <- execute_processes(state, list(process))
  newborns <- result$state$population[-seq_along(state$population)]

  expect_identical(
    lapply(newborns, function(individual) {
      list(mother_id = individual$mother_id, sex = individual$sex)
    }),
    expected
  )
  expect_identical(.Random.seed, expected_seed)
})

test_that("trusted ID allocation does not rescan the population per newborn", {
  state <- pva_state(list(create_individual(1L, "F", age = 4L)))
  process <- reproduction_process(
    breeding_probability = function(mother, state, context, params) 1,
    fecundity_mean = function(mother, state, context, params) 20,
    offspring_sex = function(mother, father, state, context, params) "F"
  )
  original_validate_state <- .validate_state
  calls <- new.env(parent = emptyenv())
  calls$n <- 0L
  testthat::local_mocked_bindings(
    .validate_state = function(...) {
      calls$n <- calls$n + 1L
      original_validate_state(...)
    },
    .package = "OpenPVA"
  )

  set.seed(8004L)
  result <- execute_processes(state, list(process))

  expect_gt(result$events$value[[1L]], 1L)
  expect_identical(calls$n, 2L)
})
