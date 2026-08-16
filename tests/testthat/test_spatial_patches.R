spatial_population <- function(patch_ids, alive = rep(TRUE, length(patch_ids))) {
  population <- lapply(seq_along(patch_ids), function(id) {
    create_individual(
      id = id,
      sex = if (id %% 2L) "F" else "M",
      age = 2L,
      patch_id = patch_ids[[id]]
    )
  })
  for (index in seq_along(population)) population[[index]]$alive <- alive[[index]]
  population
}

without_patch <- function(population) {
  lapply(population, function(individual) {
    individual$patch_id <- NULL
    individual
  })
}

transition_count <- function(events, origin, destination) {
  rows <- events$event_type == "patch_transition" &
    events$origin_patch_id == origin &
    events$destination_patch_id == destination
  sum(events$value[rows], na.rm = TRUE)
}

test_that("patch initialisation is explicit, strict and permits empty patches", {
  population <- list(
    create_individual(1L, "F", age = 1L),
    create_individual(2L, "M", age = 2L)
  )
  assigned <- initialize_patches(
    population,
    patch_ids = c(2L, 9L),
    patch_domain = c(2L, 5L, 9L)
  )
  expect_identical(vapply(assigned, `[[`, integer(1), "patch_id"), c(2L, 9L))
  expect_identical(
    initialize_patches(list(), integer(), c(2L, 5L, 9L)),
    list()
  )
  expect_error(initialize_patches(list(1L), 1L, 1L), "record must be a list")

  expect_error(
    initialize_patches(population, c(1L, 1L), c(1, 1)),
    "patch_domain"
  )
  expect_error(
    initialize_patches(population, c(1L, 1L), c(1, 2.5)),
    "patch_domain"
  )
  expect_error(
    initialize_patches(population, c(1L, 3L), c(1L, 2L)),
    "patch_ids"
  )
  expect_error(
    initialize_patches(population, 1L, c(1L, 2L)),
    "length equal"
  )
})

test_that("identity transitions report retention and preserve all other state", {
  population <- spatial_population(c(1L, 1L, 2L), alive = c(TRUE, FALSE, TRUE))
  state <- pva_state(population, globals = list(marker = "unchanged"))
  process <- dispersal_process(
    c(1L, 2L),
    destination = function(individual, state, context, params) individual$patch_id
  )
  result <- execute_processes(state, list(process), run = 4L, time = 2L)

  expect_identical(result$state, state)
  expect_identical(transition_count(result$events, 1L, 1L), 1L)
  expect_identical(transition_count(result$events, 2L, 2L), 1L)
  expect_identical(sum(result$events$value), 2L)
})

test_that("custom dispersal is simultaneous and fixes dead or ineligible records", {
  population <- spatial_population(
    c(1L, 1L, 2L, 2L),
    alive = c(FALSE, TRUE, TRUE, TRUE)
  )
  state <- pva_state(population, globals = list(marker = 11L))
  process <- dispersal_process(
    c(1L, 2L),
    destination = function(individual, state, context, params) {
      pre_ids <- vapply(state$population, `[[`, integer(1), "patch_id")
      if (sum(pre_ids == 1L) == 2L) 3L - individual$patch_id else individual$patch_id
    },
    eligible = function(individual, state, context, params) individual$id != 4L
  )
  result <- execute_processes(state, list(process))

  expect_identical(
    vapply(result$state$population, `[[`, integer(1), "patch_id"),
    c(1L, 2L, 1L, 2L)
  )
  expect_identical(
    serialize(without_patch(result$state$population), NULL),
    serialize(without_patch(state$population), NULL)
  )
  expect_identical(result$state$globals, state$globals)
  expect_identical(result$state$next_id, state$next_id)
  expect_identical(sum(result$events$value), 2L)
  expect_identical(transition_count(result$events, 1L, 2L), 1L)
  expect_identical(transition_count(result$events, 2L, 1L), 1L)
})

test_that("transition events reconcile every patch abundance", {
  start <- c(`1` = 3L, `2` = 2L, `3` = 1L)
  population <- spatial_population(rep(as.integer(names(start)), start))
  process <- dispersal_process(
    1:3,
    destination = function(individual, state, context, params) {
      c(`1` = 2L, `2` = 3L, `3` = 3L)[[as.character(individual$patch_id)]]
    }
  )
  result <- execute_processes(pva_state(population), list(process))
  end <- table(factor(
    vapply(result$state$population, `[[`, integer(1), "patch_id"),
    levels = 1:3
  ))
  for (patch in 1:3) {
    inflow <- sum(result$events$value[
      result$events$destination_patch_id == patch &
        result$events$origin_patch_id != patch
    ])
    outflow <- sum(result$events$value[
      result$events$origin_patch_id == patch &
        result$events$destination_patch_id != patch
    ])
    expect_identical(
      as.integer(end[[patch]]),
      as.integer(start[[as.character(patch)]] + inflow - outflow)
    )
  }
})

test_that("Markov transitions require a domain-aligned stochastic matrix", {
  domain <- c(2L, 5L)
  valid <- matrix(c(0.7, 0.3, 0.2, 0.8), nrow = 2L, byrow = TRUE)
  expect_s3_class(markov_dispersal_process(domain, valid), "pva_process")
  nearly_one <- valid
  nearly_one[1L, 1L] <- nearly_one[1L, 1L] + .Machine$double.eps
  expect_s3_class(markov_dispersal_process(domain, nearly_one), "pva_process")

  expect_error(markov_dispersal_process(domain, matrix(1, 1L, 1L)), "dimensions")
  expect_error(
    markov_dispersal_process(domain, matrix(c(0.2, 0.2, 0.5, 0.5), 2L, byrow = TRUE)),
    "rows must sum"
  )
  bad <- matrix(c(-0.1, 1.1, 0, 1), 2L, byrow = TRUE)
  expect_error(markov_dispersal_process(domain, bad), "probabilities")
  dimnames(valid) <- list(c("2", "9"), c("2", "5"))
  expect_error(markov_dispersal_process(domain, valid), "dimnames")
})

test_that("Markov execution validates and consumes its effective parameters", {
  population <- spatial_population(c(1L, 2L))
  process <- markov_dispersal_process(
    1:2,
    diag(2L),
    eligible = function(individual, state, context, params) params$move,
    params = list(move = TRUE)
  )
  expect_identical(process$params$model, list(move = TRUE))

  invalid <- process
  invalid$params$destination_model$transition_matrix <- matrix(
    c(0.4, 0.4, 0, 1),
    nrow = 2L,
    byrow = TRUE
  )
  expect_error(validate_processes(list(invalid)), "rows must sum")
  expect_error(
    scenario_spec(
      "invalid-mutated-markov",
      n_runs = 1L,
      n_steps = 1L,
      init_fun = function() population,
      processes = list(invalid),
      seed = 5305L
    ),
    "rows must sum"
  )

  changed <- process
  changed$params$destination_model$transition_matrix <- matrix(
    c(0, 1, 1, 0),
    nrow = 2L,
    byrow = TRUE
  )
  changed_result <- execute_processes(pva_state(population), list(changed))
  expect_identical(
    vapply(changed_result$state$population, `[[`, integer(1), "patch_id"),
    c(2L, 1L)
  )
  expect_identical(transition_count(changed_result$events, 1L, 2L), 1L)
  expect_identical(transition_count(changed_result$events, 2L, 1L), 1L)

  mismatched_domain <- process
  mismatched_domain$params$destination_model$patch_domain <- c(1L, 3L)
  expect_error(
    validate_processes(list(mismatched_domain)),
    "destination patch_domain must match"
  )
})

test_that("deterministic Markov identity and swap matrices are exact", {
  population <- spatial_population(c(1L, 1L, 2L))
  identity_result <- execute_processes(
    pva_state(population),
    list(markov_dispersal_process(1:2, diag(2L)))
  )
  swap_result <- execute_processes(
    pva_state(population),
    list(markov_dispersal_process(
      1:2,
      matrix(c(0, 1, 1, 0), nrow = 2L, byrow = TRUE)
    ))
  )
  expect_identical(
    vapply(identity_result$state$population, `[[`, integer(1), "patch_id"),
    c(1L, 1L, 2L)
  )
  expect_identical(
    vapply(swap_result$state$population, `[[`, integer(1), "patch_id"),
    c(2L, 2L, 1L)
  )
  expect_identical(transition_count(identity_result$events, 1L, 1L), 2L)
  expect_identical(transition_count(identity_result$events, 2L, 2L), 1L)
  expect_identical(transition_count(swap_result$events, 1L, 2L), 2L)
  expect_identical(transition_count(swap_result$events, 2L, 1L), 1L)
})

test_that("seeded Markov transition frequencies match the analytic expectation", {
  population <- spatial_population(rep(1L, 4000L))
  transition <- matrix(c(0.7, 0.3, 0, 1), nrow = 2L, byrow = TRUE)
  scenario <- scenario_spec(
    "markov-frequency",
    n_runs = 1L,
    n_steps = 1L,
    init_fun = function() population,
    processes = list(markov_dispersal_process(1:2, transition)),
    seed = 5005L
  )
  output <- run_scenario(scenario)
  moved <- transition_count(output$sim_output$events, 1L, 2L)
  expected <- 4000 * 0.3
  sd <- sqrt(4000 * 0.3 * 0.7)
  expect_lt(abs(moved - expected), 5 * sd)
})

test_that("invalid patch state, eligibility and destinations fail loudly", {
  process <- dispersal_process(
    1:2,
    destination = function(individual, state, context, params) 1L
  )
  missing <- spatial_population(1L)
  missing[[1L]]$patch_id <- NULL
  expect_error(execute_processes(pva_state(missing), list(process)), "patch_id")
  expect_error(
    execute_processes(pva_state(spatial_population(3L)), list(process)),
    "outside patch_domain"
  )

  bad <- dispersal_process(
    1:2,
    destination = function(individual, state, context, params) NA_real_
  )
  expect_error(
    execute_processes(pva_state(spatial_population(1L)), list(bad)),
    "destination"
  )
  bad_eligible <- dispersal_process(
    1:2,
    destination = function(individual, state, context, params) 1L,
    eligible = function(individual, state, context, params) NA
  )
  expect_error(
    execute_processes(pva_state(spatial_population(1L)), list(bad_eligible)),
    "eligible must return"
  )
})

test_that("newborn patch inheritance is explicit and lifecycle order matters", {
  initial <- spatial_population(c(1L, 1L))
  birth <- reproduction_process(
    breeding_probability = function(mother, state, context, params) 1,
    fecundity_mean = function(mother, state, context, params) 8,
    offspring_sex = function(mother, father, state, context, params) "F",
    inherit_fields = "patch_id"
  )
  incomplete_birth <- reproduction_process(
    breeding_probability = function(mother, state, context, params) 1,
    fecundity_mean = function(mother, state, context, params) 8,
    offspring_sex = function(mother, father, state, context, params) "F"
  )
  move_adults <- dispersal_process(
    1:2,
    destination = function(individual, state, context, params) 2L,
    eligible = function(individual, state, context, params) individual$age > 0L,
    requires = "population.age"
  )
  expect_error(
    validate_processes(list(incomplete_birth, move_adults), pva_state(initial)),
    "population.patch_id.*required by dispersal"
  )

  run_order <- function(processes) {
    run_scenario(scenario_spec(
      "birth-dispersal-order",
      n_runs = 1L,
      n_steps = 1L,
      init_fun = function() initial,
      processes = processes,
      seed = 5205L
    ))$sim_output$runs[[1L]]$population
  }
  move_then_birth <- run_order(list(move_adults, birth))
  birth_then_move <- run_order(list(birth, move_adults))
  newborn_after_move <- Filter(function(individual) individual$age == 0L, move_then_birth)
  newborn_before_move <- Filter(function(individual) individual$age == 0L, birth_then_move)
  expect_gt(length(newborn_after_move), 0L)
  expect_identical(length(newborn_after_move), length(newborn_before_move))
  expect_true(all(vapply(newborn_after_move, `[[`, integer(1), "patch_id") == 2L))
  expect_true(all(vapply(newborn_before_move, `[[`, integer(1), "patch_id") == 1L))
})

test_that("patch snapshots include zeros and keyed density lookup is strict", {
  population <- spatial_population(c(2L, 2L, 5L), alive = c(TRUE, FALSE, TRUE))
  state <- pva_state(population)
  result <- execute_processes(
    state,
    list(patch_density_snapshot_process(c(2L, 5L, 9L)))
  )
  expect_identical(
    result$state$globals$patch_density_counts,
    c(`2` = 1L, `5` = 1L, `9` = 0L)
  )
  expect_identical(result$state$population, state$population)
  expect_identical(result$state$next_id, state$next_id)
  expect_identical(result$events$patch_id, c(2L, 5L, 9L))
  expect_identical(result$events$value, c(1L, 1L, 0L))

  empty <- execute_processes(
    pva_state(list()),
    list(patch_density_snapshot_process(c(2L, 5L, 9L)))
  )
  expect_identical(
    empty$state$globals$patch_density_counts,
    c(`2` = 0L, `5` = 0L, `9` = 0L)
  )
  expect_identical(empty$events$value, c(0L, 0L, 0L))

  counts <- c(`2` = 10L, `5` = 0L, `9` = 20L)
  capacities <- c(`2` = 5, `5` = 5, `9` = 10)
  expect_equal(patch_density_multiplier(2L, counts, capacities), 0.5)
  expect_identical(patch_density_multiplier(5L, counts, capacities), 1)
  expect_equal(patch_density_multiplier(9L, counts, capacities), 0.5)
  expect_error(
    patch_density_multiplier(integer(), counts, capacities),
    "exactly one"
  )
  expect_error(
    patch_density_multiplier(c(2L, 5L), counts, capacities),
    "exactly one"
  )
  expect_error(patch_density_multiplier(7L, counts, capacities), "not present")
  expect_error(
    patch_density_multiplier(2L, counts, capacities[c("5", "2", "9")]),
    "identical patch keys"
  )
  expect_error(
    patch_density_multiplier(2L, counts, c(`2` = 5, `5` = 5)),
    "identical patch keys"
  )
  expect_error(
    patch_density_multiplier(2L, c(`2` = 1.5, `5` = 0, `9` = 2), capacities),
    "whole-number"
  )
  expect_error(
    patch_density_multiplier(2L, counts, c(`2` = 0, `5` = 5, `9` = 10)),
    "positive"
  )
})

test_that("patch-density callbacks yield exact local vital-rate multipliers", {
  population <- spatial_population(c(1L, 1L, 1L, 1L, 2L, 2L))
  snapshot <- execute_processes(
    pva_state(population),
    list(patch_density_snapshot_process(1:2))
  )$state
  survival <- survival_process(
    probability = function(individual, state, context, params) {
      params$base * patch_density_multiplier(
        individual$patch_id,
        state$globals$patch_density_counts,
        params$capacities
      )
    },
    requires = c("population.patch_id", "globals.patch_density_counts"),
    params = list(base = 0.8, capacities = c(`1` = 2, `2` = 4))
  )
  expect_equal(
    survival$params$probability(
      snapshot$population[[1L]], snapshot, list(), survival$params$model
    ),
    0.4
  )
  expect_equal(
    survival$params$probability(
      snapshot$population[[5L]], snapshot, list(), survival$params$model
    ),
    0.8
  )
})

test_that("dispersal and density order changes the expected patch-local rate", {
  initial <- spatial_population(c(1L, 1L, 1L, 1L, 2L))
  move_one <- dispersal_process(
    1:2,
    destination = function(individual, state, context, params) {
      if (individual$id == 1L) 2L else individual$patch_id
    }
  )
  rate_observer <- pva_process(
    name = "patch_rate_observer",
    run = function(state, context, params) {
      multiplier <- patch_density_multiplier(
        2L,
        state$globals$patch_density_counts,
        c(`1` = 99, `2` = 1)
      )
      pva_result(
        state,
        list(list(event_type = "patch_rate", patch_id = 2L, multiplier = multiplier))
      )
    },
    requires = "globals.patch_density_counts"
  )
  state <- pva_state(initial)
  density_before <- execute_processes(
    state,
    list(patch_density_snapshot_process(1:2), move_one, rate_observer)
  )
  density_after <- execute_processes(
    state,
    list(move_one, patch_density_snapshot_process(1:2), rate_observer)
  )
  before_rate <- density_before$events$multiplier[
    density_before$events$event_type == "patch_rate"
  ]
  after_rate <- density_after$events$multiplier[
    density_after$events$event_type == "patch_rate"
  ]
  expect_identical(before_rate, 1)
  expect_equal(after_rate, 0.5)
  expect_identical(length(density_before$state$population), length(initial))
  expect_identical(length(density_after$state$population), length(initial))
  expect_true(all(vapply(density_after$state$population, `[[`, logical(1), "alive")))
})
