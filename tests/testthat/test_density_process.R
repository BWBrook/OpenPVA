density_event_values <- function(output, event_type) {
  vapply(output$sim_output$runs, function(run) {
    events <- run$events
    rows <- which(events$event_type == event_type)
    if (!length(rows) || !"value" %in% names(events)) return(0)
    sum(as.numeric(events$value[rows]), na.rm = TRUE)
  }, numeric(1))
}

density_survival_scenario <- function(
    n_runs,
    capacity,
    base_survival = 0.8,
    environment_modifier = 0.75,
    use_density = TRUE,
    seed = 4104L) {
  population <- make_test_population(20L)
  processes <- list()
  if (use_density) processes <- list(density_snapshot_process())
  processes <- c(processes, list(
    survival_process(
      probability = function(individual, state, context, params) {
        density <- if (params$use_density) {
          ceiling_density_multiplier(
            state$globals$density_n_alive,
            params$capacity
          )
        } else {
          1
        }
        params$base_survival * state$globals$environment_modifier * density
      },
      requires = c(
        "globals.environment_modifier",
        if (use_density) "globals.density_n_alive" else character()
      ),
      params = list(
        base_survival = base_survival,
        capacity = capacity,
        use_density = use_density
      )
    ),
    census_process()
  ))
  scenario_spec(
    name = "density-survival-fixture",
    n_runs = n_runs,
    n_steps = 1L,
    init_fun = function() pva_state(
      population,
      globals = list(environment_modifier = environment_modifier)
    ),
    processes = processes,
    seed = seed
  )
}

density_reproduction_scenario <- function(
    n_runs,
    breeding_density,
    fecundity_density,
    n_mothers = 20L,
    base_breeding = 0.8,
    base_fecundity = 1.5,
    capacity = n_mothers / 2,
    n_steps = 1L,
    seed = 4204L) {
  population <- lapply(seq_len(n_mothers), function(id) {
    create_individual(id, "F", age = 4L)
  })
  uses_density <- breeding_density || fecundity_density
  processes <- list()
  if (uses_density) processes <- list(density_snapshot_process())
  processes <- c(processes, list(
    reproduction_process(
      breeding_probability = function(mother, state, context, params) {
        multiplier <- if (params$breeding_density) {
          ceiling_density_multiplier(
            state$globals$density_n_alive,
            params$capacity
          )
        } else {
          1
        }
        params$base_breeding * multiplier
      },
      fecundity_mean = function(mother, state, context, params) {
        multiplier <- if (params$fecundity_density) {
          ceiling_density_multiplier(
            state$globals$density_n_alive,
            params$capacity
          )
        } else {
          1
        }
        params$base_fecundity * multiplier
      },
      offspring_sex = function(mother, father, state, context, params) "F",
      requires = if (uses_density) "globals.density_n_alive" else character(),
      params = list(
        breeding_density = breeding_density,
        fecundity_density = fecundity_density,
        base_breeding = base_breeding,
        base_fecundity = base_fecundity,
        capacity = capacity
      )
    ),
    census_process()
  ))
  scenario_spec(
    name = "density-reproduction-fixture",
    n_runs = n_runs,
    n_steps = n_steps,
    init_fun = function() population,
    processes = processes,
    seed = seed,
    record_population_history = TRUE
  )
}

expect_compound_birth_mean <- function(
    output,
    n_mothers,
    breeding_probability,
    fecundity_mean,
    sigma = 5) {
  births <- density_event_values(output, "birth")
  expected <- n_mothers * breeding_probability * fecundity_mean
  per_mother_variance <- breeding_probability * fecundity_mean +
    breeding_probability * (1 - breeding_probability) * fecundity_mean^2
  mcse <- sqrt(n_mothers * per_mother_variance / length(births))
  expect_lt(abs(mean(births) - expected), sigma * mcse)
}

test_that("ceiling density multiplier has exact bounded semantics", {
  expect_identical(ceiling_density_multiplier(0, 10), 1)
  expect_identical(ceiling_density_multiplier(4, 10), 1)
  expect_identical(ceiling_density_multiplier(10, 10), 1)
  expect_equal(ceiling_density_multiplier(20, 10), 0.5)
  expect_equal(ceiling_density_multiplier(3, 2), 2 / 3)

  for (value in list(-1, 0.5, Inf, NA_real_, "4", c(1, 2))) {
    expect_error(
      ceiling_density_multiplier(value, 10),
      "n_alive must be one finite non-negative whole number"
    )
  }
  for (value in list(0, -1, Inf, NA_real_, "10", c(10, 20))) {
    expect_error(
      ceiling_density_multiplier(4, value),
      "capacity must be one finite positive numeric value"
    )
  }
})

test_that("snapshot records exact positioned abundance without demographic mutation", {
  population <- make_test_population(4L)
  population[[2L]]$alive <- FALSE
  state <- pva_state(population)
  result <- execute_processes(
    state,
    list(density_snapshot_process()),
    run = 7L,
    time = 2L
  )

  expect_identical(result$state$population, state$population)
  expect_identical(result$state$next_id, state$next_id)
  expect_identical(result$state$globals$density_n_alive, 3L)
  expect_identical(result$events$event_type, "density_snapshot")
  expect_identical(result$events$n_alive, 3L)
  expect_identical(result$events$run, 7L)
  expect_identical(result$events$time, 2L)
  expect_identical(result$events$process_name, "density_snapshot")
  expect_identical(result$events$phase, "interval")

  empty <- execute_processes(
    pva_state(list()),
    list(density_snapshot_process())
  )
  expect_identical(empty$state$globals$density_n_alive, 0L)
  expect_identical(empty$events$n_alive, 0L)
})

test_that("a declared density consumer fails without an upstream snapshot", {
  consumer <- survival_process(
    probability = function(individual, state, context, params) {
      ceiling_density_multiplier(state$globals$density_n_alive, 10)
    },
    requires = "globals.density_n_alive"
  )
  scenario <- scenario_spec(
    "missing-density-snapshot",
    n_runs = 1L,
    n_steps = 1L,
    init_fun = function() make_test_population(4L),
    processes = list(consumer),
    seed = 4304L
  )
  expect_error(
    run_scenario(scenario),
    "requires unavailable field.*globals.density_n_alive"
  )
})

test_that("a neutral density term is exactly equivalent for stochastic survival", {
  plain <- run_scenario(density_survival_scenario(
    n_runs = 12L,
    capacity = 100,
    use_density = FALSE,
    seed = 4404L
  ))
  neutral <- run_scenario(density_survival_scenario(
    n_runs = 12L,
    capacity = 100,
    use_density = TRUE,
    seed = 4404L
  ))

  plain_alive <- lapply(plain$sim_output$runs, function(run) {
    vapply(run$population, `[[`, logical(1), "alive")
  })
  neutral_alive <- lapply(neutral$sim_output$runs, function(run) {
    vapply(run$population, `[[`, logical(1), "alive")
  })
  expect_identical(neutral_alive, plain_alive)
  expect_identical(neutral$sim_output$census$n_alive, plain$sim_output$census$n_alive)
})

test_that("survival density composition matches an independent binomial expectation", {
  n_runs <- 1200L
  output <- run_scenario(density_survival_scenario(
    n_runs = n_runs,
    capacity = 10,
    base_survival = 0.8,
    environment_modifier = 0.75,
    seed = 4504L
  ))
  effective_probability <- 0.8 * 0.75 * (10 / 20)
  expected <- 20 * effective_probability
  mcse <- sqrt(20 * effective_probability * (1 - effective_probability) / n_runs)
  expect_lt(abs(mean(output$sim_output$census$n_alive) - expected), 5 * mcse)
})

test_that("breeding and fecundity density terms match compound expectations", {
  n_runs <- 800L
  breeding_only <- run_scenario(density_reproduction_scenario(
    n_runs, breeding_density = TRUE, fecundity_density = FALSE, seed = 4604L
  ))
  fecundity_only <- run_scenario(density_reproduction_scenario(
    n_runs, breeding_density = FALSE, fecundity_density = TRUE, seed = 4704L
  ))
  combined <- run_scenario(density_reproduction_scenario(
    n_runs, breeding_density = TRUE, fecundity_density = TRUE, seed = 4804L
  ))

  expect_compound_birth_mean(breeding_only, 20, 0.8 * 0.5, 1.5)
  expect_compound_birth_mean(fecundity_only, 20, 0.8, 1.5 * 0.5)
  expect_compound_birth_mean(combined, 20, 0.8 * 0.5, 1.5 * 0.5)
})

test_that("snapshot placement makes process order visible", {
  deterministic_birth <- pva_process(
    name = "deterministic_birth",
    run = function(state, context, params) {
      allocation <- allocate_ids(state, 1L)
      state <- allocation$state
      state$population[[length(state$population) + 1L]] <- create_individual(
        allocation$ids[[1L]], "F", age = 0L
      )
      pva_result(state, list(list(event_type = "birth", value = 1L)))
    },
    requires = c("population.id", "next_id"),
    writes = c(
      "population", "next_id", "population.id", "population.sex",
      "population.age", "population.alive"
    ),
    creates = c(
      "population.id", "population.sex", "population.age", "population.alive"
    )
  )
  state <- pva_state(make_test_population(2L))
  before <- execute_processes(
    state,
    list(density_snapshot_process(), deterministic_birth)
  )
  after <- execute_processes(
    state,
    list(deterministic_birth, density_snapshot_process())
  )
  expect_identical(
    before$events$n_alive[before$events$event_type == "density_snapshot"],
    2L
  )
  expect_identical(
    after$events$n_alive[after$events$event_type == "density_snapshot"],
    3L
  )
})

test_that("the grizzly density extension is explicit, synthetic and non-canonical", {
  canonical <- grizzly_benchmark_scenarios(n_runs = 1L)
  expect_identical(
    names(canonical),
    c(
      "baseline", "female_low_survival", "female_high_survival",
      "human_mortality", "immigration"
    )
  )
  expect_false(any(vapply(
    canonical,
    function(scenario) {
      "density_snapshot" %in% vapply(scenario$processes, `[[`, character(1), "name")
    },
    logical(1)
  )))

  extension <- grizzly_density_extension_scenario(
    capacity = 8,
    n_runs = 3L,
    n_steps = 2L,
    seed = 5004L
  )
  order <- vapply(extension$processes, `[[`, character(1), "name")
  expect_lt(match("density_snapshot", order), match("reproduction", order))
  for (name in c("reproduction", "dependent_survival", "independent_survival")) {
    process <- extension$processes[[match(name, order)]]
    expect_true("globals.density_n_alive" %in% process$requires)
  }
  expect_identical(extension$benchmark$density_extension$calibrated, FALSE)
  expect_identical(extension$benchmark$density_extension$capacity, 8)
  expect_match(extension$benchmark$source_label, "synthetic.*not empirical")
  expect_match(extension$benchmark$density_extension$interpretation, "not a hard cap")

  output <- run_scenario(extension)
  snapshots <- output$sim_output$events[
    output$sim_output$events$event_type == "density_snapshot",
    , drop = FALSE
  ]
  expect_equal(nrow(snapshots), 6L)
  expect_true(all(is.finite(snapshots$n_alive)))
  expect_error(
    grizzly_density_extension_scenario(capacity = 0),
    "capacity must be one finite positive"
  )
})

test_that("the shipped grizzly extension callbacks apply the declared multiplier", {
  extension <- grizzly_density_extension_scenario(
    capacity = 5,
    n_runs = 1L,
    n_steps = 1L,
    include_observation = FALSE
  )
  order <- vapply(extension$processes, `[[`, character(1), "name")
  snapshot_index <- match("density_snapshot", order)
  positioned <- execute_processes(
    grizzly_benchmark_initial_state(),
    extension$processes[seq_len(snapshot_index)]
  )$state
  expect_identical(positioned$globals$density_n_alive, 10L)
  expect_identical(positioned$globals$environment_modifier, 1)

  reproduction <- extension$processes[[match("reproduction", order)]]
  eligible_mother <- Filter(function(individual) {
    isTRUE(individual$alive) && identical(individual$sex, "F") &&
      identical(individual$reproductive_status, "eligible")
  }, positioned$population)[[1L]]
  expect_equal(
    reproduction$params$breeding_probability(
      eligible_mother, positioned, list(), reproduction$params$model
    ),
    0.35
  )
  expect_equal(
    reproduction$params$fecundity_mean(
      eligible_mother, positioned, list(), reproduction$params$model
    ),
    0.40
  )

  dependent <- Filter(function(individual) {
    individual$dependency %in% c("cub", "yearling")
  }, positioned$population)[[1L]]
  independent_female <- Filter(function(individual) {
    identical(individual$dependency, "independent") &&
      identical(individual$sex, "F")
  }, positioned$population)[[1L]]
  independent_male <- Filter(function(individual) {
    identical(individual$dependency, "independent") &&
      identical(individual$sex, "M")
  }, positioned$population)[[1L]]
  dependent_survival <- extension$processes[[match("dependent_survival", order)]]
  independent_survival <- extension$processes[[match("independent_survival", order)]]
  expect_equal(
    dependent_survival$params$probability(
      dependent, positioned, list(), dependent_survival$params$model
    ),
    0.39
  )
  expect_equal(
    independent_survival$params$probability(
      independent_female, positioned, list(), independent_survival$params$model
    ),
    0.465
  )
  expect_equal(
    independent_survival$params$probability(
      independent_male, positioned, list(), independent_survival$params$model
    ),
    0.455
  )
})

test_that("the shipped extension is exactly neutral at high capacity", {
  parameters <- grizzly_benchmark_parameters(horizon = 3L)
  baseline <- run_scenario(grizzly_benchmark_scenario(
    scenario = "baseline",
    parameters = parameters,
    n_runs = 8L,
    n_steps = 3L,
    seed = 5104L
  ))
  extension <- run_scenario(grizzly_density_extension_scenario(
    capacity = 1e9,
    parameters = parameters,
    n_runs = 8L,
    n_steps = 3L,
    seed = 5104L
  ))

  baseline_populations <- lapply(baseline$sim_output$runs, `[[`, "population")
  extension_populations <- lapply(extension$sim_output$runs, `[[`, "population")
  expect_identical(extension_populations, baseline_populations)

  normalize_rows <- function(rows, remove_snapshot = FALSE) {
    if (remove_snapshot) {
      rows <- rows[rows$event_type != "density_snapshot", , drop = FALSE]
    }
    rows$process_index <- NULL
    rows <- rows[, sort(names(rows)), drop = FALSE]
    rownames(rows) <- NULL
    rows
  }
  expect_identical(
    normalize_rows(extension$sim_output$census),
    normalize_rows(baseline$sim_output$census)
  )
  expect_identical(
    normalize_rows(extension$sim_output$events, remove_snapshot = TRUE),
    normalize_rows(baseline$sim_output$events)
  )
  snapshots <- extension$sim_output$events[
    extension$sim_output$events$event_type == "density_snapshot",
    , drop = FALSE
  ]
  expect_equal(nrow(snapshots), 8L * 3L)
  expect_true(all(snapshots$n_alive <= 1e9))
})

test_that("density scenarios preserve accounting, repeatability and fork identity", {
  skip_on_os("windows")
  scenario <- density_reproduction_scenario(
    n_runs = 6L,
    breeding_density = TRUE,
    fecundity_density = TRUE,
    n_mothers = 5L,
    base_breeding = 0.5,
    base_fecundity = 0.4,
    capacity = 3,
    n_steps = 2L,
    seed = 4904L
  )
  first <- run_scenario(scenario)
  repeated <- run_scenario(scenario)
  forked <- run_scenario(scenario, parallel = TRUE, workers = 2L)
  expect_identical(repeated, first)
  expect_identical(forked, first)

  for (run in first$sim_output$runs) {
    births <- sum(run$events$value[run$events$event_type == "birth"], na.rm = TRUE)
    expect_identical(length(run$population), 5L + as.integer(births))
  }
  density_events <- first$sim_output$events[
    first$sim_output$events$event_type == "density_snapshot",
    , drop = FALSE
  ]
  expect_equal(nrow(density_events), 12L)
  expect_true(all(density_events$process_name == "density_snapshot"))
  expect_true(all(density_events$phase == "interval"))
  expect_true(all(density_events$process_index == 1L))
})
