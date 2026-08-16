pedigree_record <- function(
    id,
    sex,
    mother_id = NA_integer_,
    father_id = NA_integer_,
    status = if (is.na(mother_id) && is.na(father_id)) {
      "base_founder"
    } else {
      "known_parentage"
    },
    alive = TRUE) {
  individual <- create_individual(
    id,
    sex,
    age = 2L,
    alive = alive,
    mother_id = mother_id,
    father_id = father_id
  )
  individual$pedigree_status <- status
  individual
}

dense_pedigree_oracle <- function(population) {
  n <- length(population)
  A <- matrix(0, nrow = n, ncol = n)
  ids <- vapply(population, `[[`, integer(1), "id")
  F <- numeric(n)
  for (index in seq_len(n)) {
    individual <- population[[index]]
    if (individual$pedigree_status == "base_founder") {
      A[index, index] <- 1
      next
    }
    mother <- match(individual$mother_id, ids)
    father <- match(individual$father_id, ids)
    if (index > 1L) {
      earlier <- seq_len(index - 1L)
      A[index, earlier] <- (A[mother, earlier] + A[father, earlier]) / 2
      A[earlier, index] <- A[index, earlier]
    }
    F[[index]] <- A[mother, father] / 2
    A[index, index] <- 1 + F[[index]]
  }
  list(A = A, F = F)
}

expect_pedigree_matches_oracle <- function(population) {
  initialized <- initialize_pedigree(population)
  oracle <- dense_pedigree_oracle(population)
  observed <- vapply(initialized, `[[`, numeric(1), "pedigree_F")
  expect_equal(observed, oracle$F, tolerance = 1e-13)
  initialized
}

test_that("hand pedigrees lock the A/kinship factor-of-two convention", {
  unrelated <- list(
    pedigree_record(101L, "F"),
    pedigree_record(207L, "M"),
    pedigree_record(350L, "F", 101L, 207L)
  )
  initialized <- expect_pedigree_matches_oracle(unrelated)
  expect_identical(vapply(initialized, `[[`, numeric(1), "pedigree_F"), c(0, 0, 0))

  half_sibs <- list(
    pedigree_record(10L, "F"),
    pedigree_record(20L, "M"),
    pedigree_record(30L, "F"),
    pedigree_record(40L, "F", 10L, 20L),
    pedigree_record(50L, "M", 30L, 20L),
    pedigree_record(60L, "F", 40L, 50L)
  )
  initialized <- expect_pedigree_matches_oracle(half_sibs)
  expect_equal(initialized[[6L]]$pedigree_F, 0.125)
  oracle <- dense_pedigree_oracle(half_sibs)
  expect_equal(oracle$A[4L, 5L], 0.25)
  expect_equal(initialized[[6L]]$pedigree_F, oracle$A[4L, 5L] / 2)

  full_sibs <- list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "M"),
    pedigree_record(3L, "F", 1L, 2L),
    pedigree_record(4L, "M", 1L, 2L),
    pedigree_record(5L, "F", 3L, 4L)
  )
  initialized <- expect_pedigree_matches_oracle(full_sibs)
  expect_equal(initialized[[5L]]$pedigree_F, 0.25)

  full_sib_backcross <- list(
    pedigree_record(10L, "F"),
    pedigree_record(20L, "M"),
    pedigree_record(30L, "F", 10L, 20L),
    pedigree_record(40L, "M", 10L, 20L),
    pedigree_record(50L, "M", 30L, 40L),
    pedigree_record(55L, "F", 30L, 50L)
  )
  initialized <- expect_pedigree_matches_oracle(full_sib_backcross)
  expect_equal(initialized[[6L]]$pedigree_F, 0.375)

  parent_offspring <- list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "M"),
    pedigree_record(3L, "M", 1L, 2L),
    pedigree_record(4L, "F", 1L, 3L)
  )
  initialized <- expect_pedigree_matches_oracle(parent_offspring)
  expect_equal(initialized[[4L]]$pedigree_F, 0.25)

  first_cousins <- list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "M"),
    pedigree_record(3L, "F", 1L, 2L),
    pedigree_record(4L, "M", 1L, 2L),
    pedigree_record(5L, "M"),
    pedigree_record(6L, "F"),
    pedigree_record(7L, "F", 3L, 5L),
    pedigree_record(8L, "M", 6L, 4L),
    pedigree_record(9L, "F", 7L, 8L)
  )
  initialized <- expect_pedigree_matches_oracle(first_cousins)
  expect_equal(initialized[[9L]]$pedigree_F, 0.0625)
})

test_that("founder and topology declarations fail decisively", {
  partial <- list(pedigree_record(1L, "F"), pedigree_record(2L, "M"))
  partial[[2L]]$pedigree_status <- "known_parentage"
  partial[[2L]]$mother_id <- 1L
  expect_error(initialize_pedigree(partial), "unsupported partial parentage")

  missing_parent <- list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "M"),
    pedigree_record(3L, "F", 1L, 99L)
  )
  expect_error(initialize_pedigree(missing_parent), "father_id 99 does not exist")

  later_parent <- list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "F", 1L, 3L),
    pedigree_record(3L, "M")
  )
  expect_error(initialize_pedigree(later_parent), "later/cyclic topology")

  self_parent <- list(pedigree_record(1L, "F", 1L, 2L), pedigree_record(2L, "M"))
  expect_error(initialize_pedigree(self_parent), "cannot be its own parent")

  same_parent <- list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "M", 1L, 1L)
  )
  expect_error(initialize_pedigree(same_parent), "same mother_id and father_id")

  wrong_mother <- list(
    pedigree_record(1L, "M"),
    pedigree_record(2L, "F"),
    pedigree_record(3L, "F", 1L, 2L)
  )
  expect_error(initialize_pedigree(wrong_mother), "mother_id 1.*female")

  wrong_father <- list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "F"),
    pedigree_record(3L, "M", 1L, 2L)
  )
  expect_error(initialize_pedigree(wrong_father), "father_id 2.*male")

  founder_with_parent <- list(pedigree_record(1L, "F"), pedigree_record(2L, "M"))
  founder_with_parent[[2L]]$mother_id <- 1L
  founder_with_parent[[2L]]$father_id <- 1L
  expect_error(initialize_pedigree(founder_with_parent), "base founder.*both parents absent")

  ambiguous <- list(pedigree_record(1L, "F", status = "uncertain"))
  expect_error(initialize_pedigree(ambiguous), "pedigree_status")

  duplicate <- list(pedigree_record(1L, "F"), pedigree_record(1L, "M"))
  expect_error(initialize_pedigree(duplicate), "id values must be unique")
})

test_that("missing, invalid and inconsistent pedigree fields fail", {
  missing_status <- list(create_individual(1L, "F", 2L))
  expect_error(initialize_pedigree(missing_status), "missing pedigree field.*pedigree_status")

  pedigree <- initialize_pedigree(list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "M"),
    pedigree_record(3L, "F", 1L, 2L)
  ))
  incomplete <- pedigree
  incomplete[[2L]]$pedigree_F <- NULL
  expect_error(pva_state(incomplete), "missing pedigree field pedigree_F")
  invalid <- pedigree
  invalid[[2L]]$pedigree_F <- NaN
  expect_error(pva_state(invalid), "pedigree_F")
  invalid <- pedigree
  invalid[[2L]]$pedigree_F <- 1.1
  expect_error(pva_state(invalid), "pedigree_F")
  inconsistent <- pedigree
  inconsistent[[3L]]$pedigree_F <- 0.25
  expect_error(pva_state(inconsistent), "inconsistent with its recorded ancestry")
})

test_that("non-pedigree records retain optional one-parent semantics", {
  dependent <- create_individual(
    2L,
    "F",
    1L,
    mother_id = 1L,
    father_id = NA_integer_
  )
  expect_silent(pva_state(list(create_individual(1L, "F", 5L), dependent)))
})

test_that("public creator helpers use persistent IDs and dead ancestors", {
  founders <- initialize_pedigree(list(
    pedigree_record(20L, "F", alive = FALSE),
    pedigree_record(5L, "M")
  ))
  state <- pva_state(founders)
  fields <- pedigree_parentage_fields(20L, 5L, state)
  expect_identical(fields$mother_id, 20L)
  expect_identical(fields$father_id, 5L)
  expect_identical(fields$pedigree_status, "known_parentage")
  expect_equal(fields$pedigree_F, 0)
  expect_identical(
    pedigree_newborn_fields(founders[[1L]], founders[[2L]], state),
    fields[c("pedigree_status", "pedigree_F")]
  )
  expect_error(pedigree_newborn_fields(founders[[1L]], NULL, state), "two known parents")
  expect_error(pedigree_parentage_fields(20L, 20L, state), "distinct records")
  expect_error(pedigree_parentage_fields(999L, 5L, state), "mother_id does not reference")
})

test_that("pedigree-enabled births initialise exact fields and downstream use", {
  founders <- initialize_pedigree(list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "M")
  ))
  missing_fields <- reproduction_process(
    breeding_probability = function(mother, state, context, params) 1,
    fecundity_mean = function(mother, state, context, params) 1,
    offspring_sex = function(mother, father, state, context, params) "F",
    mating = function(population, mother, context, params) population[[2L]],
    require_mate = TRUE
  )
  consumer <- pva_process(
    "pedigree_consumer",
    function(state, context, params) pva_result(state),
    requires = c("population.pedigree_status", "population.pedigree_F")
  )
  expect_error(
    validate_processes(list(missing_fields, consumer), pva_state(founders)),
    "does not declare initialisation of.*pedigree"
  )

  birth <- reproduction_process(
    breeding_probability = function(mother, state, context, params) {
      as.numeric(mother$id == 1L)
    },
    fecundity_mean = function(mother, state, context, params) 8,
    offspring_sex = function(mother, father, state, context, params) "F",
    mating = function(population, mother, context, params) population[[2L]],
    require_mate = TRUE,
    newborn_initializer = function(mother, father, state, context, params) {
      pedigree_newborn_fields(mother, father, state)
    },
    initializer_fields = c("pedigree_status", "pedigree_F"),
    requires = c(
      "population.mother_id", "population.father_id",
      "population.pedigree_status", "population.pedigree_F"
    )
  )
  set.seed(7007L)
  result <- execute_processes(pva_state(founders), list(birth, consumer))
  newborns <- tail(result$state$population, result$events$value[[1L]])
  expect_gt(length(newborns), 0L)
  expect_true(all(vapply(newborns, `[[`, character(1), "pedigree_status") == "known_parentage"))
  expect_true(all(vapply(newborns, `[[`, numeric(1), "pedigree_F") == 0))
  expect_identical(result$state$next_id, as.integer(3L + length(newborns)))
  expect_silent(validate_pedigree(result$state$population))

  incomplete_birth <- reproduction_process(
    breeding_probability = function(mother, state, context, params) 1,
    fecundity_mean = function(mother, state, context, params) 8,
    offspring_sex = function(mother, father, state, context, params) "F",
    newborn_initializer = function(mother, father, state, context, params) {
      pedigree_newborn_fields(mother, father, state)
    },
    initializer_fields = c("pedigree_status", "pedigree_F"),
    requires = c(
      "population.mother_id", "population.father_id",
      "population.pedigree_status", "population.pedigree_F"
    )
  )
  original <- serialize(pva_state(founders), NULL)
  set.seed(17L)
  expect_error(
    execute_processes(pva_state(founders), list(incomplete_birth)),
    "requires two known parents"
  )
  expect_identical(serialize(pva_state(founders), NULL), original)
})

test_that("founder and known-parentage introductions compose and share pre-state", {
  initial <- initialize_pedigree(list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "M")
  ))
  founder_intro <- introduction_process(
    1L,
    function(index, id, state, context, params) {
      c(list(sex = "F", age = 2L), pedigree_founder_fields())
    },
    c("sex", "age", "mother_id", "father_id", "pedigree_status", "pedigree_F"),
    "declared founder"
  )
  founder_result <- execute_processes(pva_state(initial), list(founder_intro))
  expect_identical(tail(founder_result$state$population, 1L)[[1L]]$pedigree_status, "base_founder")

  related_intro <- introduction_process(
    1L,
    function(index, id, state, context, params) {
      c(list(sex = "M", age = 1L), pedigree_parentage_fields(1L, 2L, state))
    },
    c("sex", "age", "mother_id", "father_id", "pedigree_status", "pedigree_F"),
    "known ancestry"
  )
  related_result <- execute_processes(pva_state(initial), list(related_intro))
  newcomer <- tail(related_result$state$population, 1L)[[1L]]
  expect_identical(newcomer$pedigree_status, "known_parentage")
  expect_equal(newcomer$pedigree_F, 0)
  expect_identical(related_result$events$value, 1L)

  same_batch <- introduction_process(
    2L,
    function(index, id, state, context, params) {
      if (index == 1L) {
        return(c(list(sex = "F", age = 2L), pedigree_founder_fields()))
      }
      c(
        list(sex = "M", age = 1L),
        pedigree_parentage_fields(id - 1L, 2L, state)
      )
    },
    c("sex", "age", "mother_id", "father_id", "pedigree_status", "pedigree_F"),
    "same-batch ancestry"
  )
  expect_error(
    execute_processes(pva_state(initial), list(same_batch)),
    "mother_id does not reference an existing pedigree record"
  )

  manual_same_batch <- introduction_process(
    2L,
    function(index, id, state, context, params) {
      if (index == 1L) {
        return(c(list(sex = "F", age = 2L), pedigree_founder_fields()))
      }
      list(
        sex = "M", age = 1L, mother_id = id - 1L, father_id = 2L,
        pedigree_status = "known_parentage", pedigree_F = 0
      )
    },
    c("sex", "age", "mother_id", "father_id", "pedigree_status", "pedigree_F"),
    "manual same-batch ancestry"
  )
  expect_error(
    execute_processes(pva_state(initial), list(manual_same_batch)),
    "parents present before the creation process"
  )
})

test_that("ledger and summaries retain exact ancestry semantics", {
  pedigree <- initialize_pedigree(list(
    pedigree_record(1L, "F", alive = FALSE),
    pedigree_record(2L, "M"),
    pedigree_record(3L, "F", 1L, 2L)
  ))
  ledger <- pedigree_ledger(pedigree)
  expect_identical(ledger$id, 1:3)
  expect_identical(ledger$pedigree_status, c("base_founder", "base_founder", "known_parentage"))
  alive <- summarise_pedigree(pedigree, alive_only = TRUE)
  expect_identical(alive$n_individuals, 2L)
  expect_identical(alive$n_base_founders, 1L)
  expect_identical(alive$n_known_parentage, 1L)
  expect_equal(alive$mean_pedigree_F, 0)
  expect_identical(nrow(pedigree_ledger(list())), 0L)
})

test_that("many generated pedigrees match an independent dense oracle", {
  set.seed(17007L)
  for (replicate in seq_len(10L)) {
    population <- vector("list", 32L)
    sexes <- rep(c("F", "M"), 16L)
    for (index in seq_len(8L)) {
      population[[index]] <- pedigree_record(index * 10L, sexes[[index]])
    }
    for (index in 9:32) {
      females <- which(sexes[seq_len(index - 1L)] == "F")
      males <- which(sexes[seq_len(index - 1L)] == "M")
      mother <- sample(females, 1L)
      father <- sample(males, 1L)
      population[[index]] <- pedigree_record(
        index * 10L,
        sexes[[index]],
        population[[mother]]$id,
        population[[father]]$id
      )
    }
    if (replicate == 1L) {
      population[[1L]]$marker_payload <- matrix(999, 20L, 20L)
    }
    expect_pedigree_matches_oracle(population)
  }
})

test_that("arbitrary marker attributes cannot alter pedigree_F", {
  plain <- list(
    pedigree_record(11L, "F"),
    pedigree_record(29L, "M"),
    pedigree_record(47L, "F", 11L, 29L)
  )
  marked <- plain
  marked[[1L]]$marker_payload <- matrix(1:400, nrow = 20L)
  marked[[2L]]$observed_heterozygosity <- 0.999
  marked[[3L]]$alleles_from_external_module <- c("A", "B")
  expect_identical(
    vapply(initialize_pedigree(marked), `[[`, numeric(1), "pedigree_F"),
    vapply(initialize_pedigree(plain), `[[`, numeric(1), "pedigree_F")
  )
})

test_that("large public pedigree initialization and reproduction remain valid", {
  n <- 800L
  population <- vector("list", n)
  sexes <- rep(c("F", "M"), length.out = n)
  for (index in seq_len(20L)) {
    population[[index]] <- pedigree_record(index, sexes[[index]])
  }
  for (index in 21:n) {
    prior <- seq_len(index - 1L)
    mother <- tail(prior[sexes[prior] == "F"], 1L)
    father <- tail(prior[sexes[prior] == "M"], 1L)
    population[[index]] <- pedigree_record(index, sexes[[index]], mother, father)
  }
  initialized <- initialize_pedigree(population)
  expect_identical(length(initialized), n)
  expect_silent(validate_pedigree(initialized))

  creator <- reproduction_process(
    breeding_probability = function(mother, state, context, params) {
      as.numeric(mother$id == 1L)
    },
    fecundity_mean = function(mother, state, context, params) 25,
    mating = function(population, mother, context, params) population[[2L]],
    require_mate = TRUE,
    offspring_sex = function(mother, father, state, context, params) "F",
    newborn_initializer = function(mother, father, state, context, params) {
      pedigree_newborn_fields(mother, father, state)
    },
    initializer_fields = c("pedigree_status", "pedigree_F"),
    requires = c(
      "population.mother_id", "population.father_id",
      "population.pedigree_status", "population.pedigree_F"
    )
  )
  set.seed(7017L)
  created <- execute_processes(pva_state(initialized), list(creator))
  expect_gt(nrow(created$events), 0L)
  expect_gt(length(created$state$population), n)
  expect_silent(validate_pedigree(created$state$population))
})

test_that("public engine entry points reject inconsistent pedigree_F", {
  pedigree <- initialize_pedigree(list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "M"),
    pedigree_record(3L, "F", 1L, 2L)
  ))
  valid <- pva_state(pedigree)
  mutated <- valid
  mutated$population[[3L]]$pedigree_F <- 0.25
  raw <- list(
    population = mutated$population,
    globals = list(),
    next_id = 4L
  )
  expect_error(pva_state(raw$population), "inconsistent with its recorded ancestry")
  expect_error(
    execute_processes(raw, list(census_process())),
    "inconsistent with its recorded ancestry"
  )
  expect_error(
    allocate_ids(mutated, 0L),
    "inconsistent with its recorded ancestry"
  )
})

test_that("trusted execution exactly validates every actual lineage change", {
  pedigree <- initialize_pedigree(list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "M"),
    pedigree_record(3L, "F", 1L, 2L)
  ))
  corrupt_lineage <- pva_process(
    "corrupt_lineage",
    function(state, context, params) {
      state$population[[3L]]$pedigree_F <- 0.25
      pva_result(state)
    },
    requires = "population.pedigree_F",
    writes = "population.pedigree_F"
  )

  expect_error(
    execute_processes(pva_state(pedigree), list(corrupt_lineage)),
    "inconsistent with its recorded ancestry"
  )
})

test_that("trusted process results retain complete pedigree record structure", {
  pedigree <- initialize_pedigree(list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "M"),
    pedigree_record(3L, "F", 1L, 2L)
  ))
  remove_alive <- pva_process(
    "remove_alive",
    function(state, context, params) {
      state$population[[3L]]$alive <- NULL
      pva_result(
        state,
        list(list(event_type = "death", value = 1L, cause = "test"))
      )
    },
    requires = "population.alive",
    writes = "population.alive"
  )

  expect_error(
    execute_processes(pva_state(pedigree), list(remove_alive)),
    "missing pedigree field.*alive"
  )
})

test_that("ordinary pedigree mortality checks structure without rebuilding ancestry", {
  pedigree <- initialize_pedigree(list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "M"),
    pedigree_record(3L, "F", 1L, 2L)
  ))
  state <- pva_state(pedigree)
  mortality <- survival_process(
    probability = function(individual, state, context, params) 0
  )
  original_expected_F <- .pedigree_expected_F
  calls <- new.env(parent = emptyenv())
  calls$n <- 0L
  testthat::local_mocked_bindings(
    .pedigree_expected_F = function(...) {
      calls$n <- calls$n + 1L
      original_expected_F(...)
    },
    .package = "OpenPVA"
  )

  set.seed(8007L)
  result <- execute_processes(state, list(mortality))

  expect_false(any(vapply(result$state$population, `[[`, logical(1), "alive")))
  expect_identical(calls$n, 1L)
})

test_that("trusted unchanged and zero-birth intervals audit ancestry once", {
  founders <- initialize_pedigree(list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "M")
  ))
  state <- pva_state(founders)
  zero_birth <- reproduction_process(
    breeding_probability = function(mother, state, context, params) 0,
    fecundity_mean = function(mother, state, context, params) 1,
    offspring_sex = function(mother, father, state, context, params) "F",
    mating = function(population, mother, context, params) population[[2L]],
    require_mate = TRUE,
    newborn_initializer = function(mother, father, state, context, params) {
      pedigree_newborn_fields(mother, father, state)
    },
    initializer_fields = c("pedigree_status", "pedigree_F"),
    requires = c(
      "population.mother_id", "population.father_id",
      "population.pedigree_status", "population.pedigree_F"
    )
  )
  original_expected_F <- .pedigree_expected_F
  calls <- new.env(parent = emptyenv())
  calls$n <- 0L
  testthat::local_mocked_bindings(
    .pedigree_expected_F = function(...) {
      calls$n <- calls$n + 1L
      original_expected_F(...)
    },
    .package = "OpenPVA"
  )
  scenario <- scenario_spec(
    "trusted-pedigree-continuation",
    1L,
    3L,
    function() state,
    list(age_process(), zero_birth, census_process()),
    seed = 7008L
  )
  expect_silent(run_scenario(scenario))
  expect_identical(calls$n, 1L)
})

test_that("pedigree reproduction preserves descendant lineage", {
  founders <- initialize_pedigree(list(
    pedigree_record(1L, "F"),
    pedigree_record(2L, "M")
  ))
  birth <- reproduction_process(
    breeding_probability = function(mother, state, context, params) {
      as.numeric(mother$age >= 2L)
    },
    fecundity_mean = function(mother, state, context, params) 4,
    mating = function(population, mother, context, params) population[[2L]],
    require_mate = TRUE,
    offspring_sex = function(mother, father, state, context, params) "F",
    newborn_initializer = function(mother, father, state, context, params) {
      pedigree_newborn_fields(mother, father, state)
    },
    initializer_fields = c("pedigree_status", "pedigree_F"),
    requires = c(
      "population.age", "population.mother_id", "population.father_id",
      "population.pedigree_status", "population.pedigree_F"
    )
  )
  scenario <- scenario_spec(
    "pedigree-repeatability",
    1L,
    3L,
    function() pva_state(founders),
    list(age_process(), birth, census_process()),
    seed = 7007L,
    record_population_history = TRUE
  )
  output <- run_scenario(scenario)
  expect_true(any(vapply(output$sim_output$runs, function(run) {
    any(vapply(run$population, function(individual) {
      !is.na(individual$mother_id) && individual$mother_id > 2L
    }, logical(1)))
  }, logical(1))))
  expect_true(all(vapply(output$sim_output$runs, function(run) {
    isTRUE(tryCatch({
      validate_pedigree(run$population)
      TRUE
    }, error = function(error) FALSE))
  }, logical(1))))
})
