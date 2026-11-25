test_that("known pedigrees give textbook inbreeding coefficients", {
  mate_parents <- function(pairs) {
    function(pop, state, context, params) {
      father <- rep(NA_integer_, length(pop$id))
      father[match(pairs[, 1L], pop$id)] <- match(pairs[, 2L], pop$id)
      father
    }
  }
  breed <- function(pairs) {
    reproduction_process(
      breeding_probability = function(pop, state, context, params) {
        as.numeric(pop$id %in% pairs[, 1L])
      },
      litter_size = litter_categorical(2L, 1),
      offspring_sex = function(mothers, pop, state, context, params) {
        rep(c("F", "M"), length.out = length(mothers))
      },
      mate = mate_parents(pairs),
      require_mate = TRUE
    )
  }
  state <- pva_state(adult_population(1L, 1L), pedigree = TRUE)
  # Founders 1 x 2 -> full sibs 3, 4; 3 x 4 -> 5, 6 (F = 1/4); 5 x 6 -> F = 3/8.
  state <- execute_processes(state, list(breed(cbind(1L, 2L))))$state
  expect_equal(state$population$pedigree_F, c(0, 0, 0, 0))
  expect_equal(state$kinship[3L, 4L], 0.25)
  state <- execute_processes(state, list(breed(cbind(3L, 4L))))$state
  expect_equal(state$population$pedigree_F[5:6], c(0.25, 0.25))
  state <- execute_processes(state, list(breed(cbind(5L, 6L))))$state
  expect_equal(state$population$pedigree_F[7:8], c(0.375, 0.375))
  # Parent-offspring mating: dam 3 with her sire 2 gives F = 1/4.
  state <- execute_processes(state, list(breed(cbind(3L, 2L))))$state
  expect_equal(state$population$pedigree_F[9:10], c(0.25, 0.25))

  summary <- summarise_pedigree(state)
  expect_identical(summary$n_founders, 2L)
  expect_equal(summary$max_inbreeding, 0.375)
  expect_equal(summary$gene_diversity, 1 - mean(state$kinship))
  expect_error(summarise_pedigree(pva_state(adult_population())), "not enabled")
})

test_that("incremental kinship matches the dense relationship oracle over many years", {
  keep <- c("census", "state", "ledger")
  result <- run_scenario(pedigree_scenario(n_runs = 4L, n_steps = 25L, seed = 71L), keep = keep)
  fast <- run_scenario(
    pedigree_scenario(n_runs = 4L, n_steps = 25L, seed = 71L),
    validation = "fast", keep = keep
  )
  expect_identical(fast$ledgers, result$ledgers)
  records <- 0L
  inbred <- 0L
  for (run in seq_along(result$ledgers)) {
    ledger <- result$ledgers[[run]]
    oracle <- dense_inbreeding(ledger)
    expect_lt(max(abs(ledger$pedigree_F - oracle)), 1e-13)
    records <- records + nrow(ledger)
    inbred <- inbred + sum(oracle > 0)
    # The retained kinship of the survivors matches the dense oracle too.
    state <- result$states[[run]]
    expect_equal(2 * diag(state$kinship) - 1, state$population$pedigree_F, tolerance = 1e-13)
    survivors <- match(state$population$id, ledger$id)
    expect_lt(
      max(abs(2 * state$kinship - dense_relationship(ledger)[survivors, survivors])),
      1e-13
    )
    expect_identical(
      ledger$id[is.na(ledger$exit_time)],
      state$population$id
    )
  }
  # The comparison is not vacuous: hundreds of records, many of them inbred.
  expect_gt(records, 400L)
  expect_gt(inbred, 100L)
})

test_that("related founders are honoured by engine and oracle alike", {
  kinship <- diag(0.5, 8L)
  kinship[1L, 2L] <- kinship[2L, 1L] <- 0.25
  kinship[3L, 4L] <- kinship[4L, 3L] <- 0.125
  result <- run_scenario(
    pedigree_scenario(n_runs = 2L, n_steps = 10L, seed = 5L, kinship = kinship),
    keep = "ledger"
  )
  for (ledger in result$ledgers) {
    oracle <- dense_inbreeding(ledger, initial_relationship = 2 * kinship)
    expect_lt(max(abs(ledger$pedigree_F - oracle)), 1e-13)
  }
})

test_that("known parents resolve in both modes and a missing parent is unrelated", {
  state <- pva_state(adult_population(2L, 2L), pedigree = TRUE)
  creator <- function(mother_id, father_id) {
    custom_process(function(state, context, params) {
      state <- add_individuals(
        state, sex = "F", age = 0L, mother_id = mother_id, father_id = father_id
      )
      pva_result(state, pva_events("birth", 1))
    }, creates = c("sex", "age"))
  }
  for (mode in c("strict", "fast")) {
    for (pair in list(c(1L, NA_integer_), c(NA_integer_, 3L))) {
      child <- execute_processes(state, list(creator(pair[1L], pair[2L])), validation = mode)$state
      expect_identical(child$population$pedigree_F[5L], 0)
      expect_identical(child$kinship[5L, pair[!is.na(pair)]], 0.25)
      expect_false(anyNA(child$kinship))
    }
    expect_error(execute_processes(state, list(creator(1L, 99L)), validation = mode), "unknown parent ID")
    expect_error(execute_processes(state, list(creator(1.5, 3L)), validation = mode), "whole numbers")
  }
  expect_error(execute_processes(state, list(creator(3L, 1L))), "non-female mother")
  founder <- execute_processes(state, list(creator(NA, NA)))$state
  expect_identical(founder$population$pedigree_F[[5L]], 0)
  tamper <- custom_process(function(state, context, params) {
    state$kinship <- diag(0.75, 4L)
    pva_result(state)
  })
  expect_error(execute_processes(state, list(tamper)), "engine-owned kinship")
  scribble <- custom_process(function(state, context, params) {
    state$kinship$values[1L, 2L] <- 0.25
    pva_result(state)
  })
  expect_error(execute_processes(state, list(scribble)), "engine-owned kinship")
  expect_identical(kinship_matrix(state)[1L, 2L], 0)
  # Inside a process the living kinship matrix is available on request.
  seen <- NULL
  reader <- custom_process(function(state, context, params) {
    seen <<- kinship_matrix(state)
    pva_result(state)
  })
  invisible(execute_processes(state, list(creator(NA, NA), reader)))
  expect_identical(seen, diag(0.5, 5L))
  expect_identical(kinship_matrix(state), diag(0.5, 4L))
})

test_that("inbreeding helpers follow their definitions", {
  expect_equal(inbreeding_multiplier(c(0, 0.25), 3), c(1, exp(-0.75)))
  expect_error(inbreeding_multiplier(1.2, 3), "\\[0, 1\\]")
  expect_error(inbreeding_multiplier(0.1, -1), "non-negative")
  expect_equal(sex_ratio_effective_size(10, 10), 20)
  expect_equal(sex_ratio_effective_size(c(1, 0), c(9, 0)), c(3.6, 0))

  proxy <- inbreeding_proxy_process(
    effective_size = function(pop, state, context, params) params$ne,
    generation_time = 1,
    migration = function(pop, state, context, params) params$m,
    params = list(ne = 10, m = 0.1)
  )
  state <- pva_state(adult_population(), globals = list(inbreeding_proxy = 0.2))
  out <- execute_processes(state, list(proxy))$state
  expect_equal(out$globals$inbreeding_proxy, (0.05 + 0.95 * 0.2) * 0.81)
  closed <- inbreeding_proxy_process(function(pop, state, context, params) 0, generation_time = 4)
  expect_equal(execute_processes(state, list(closed))$state$globals$inbreeding_proxy, 0.2)
})

test_that("initial parentage can point forward in ID order and must be resolvable", {
  pop <- pva_population(c("F", "M", "F", "M", "F"), 1L,
                        mother_id = c(3L, 3L, NA, NA, 1L),
                        father_id = c(4L, 4L, NA, NA, 2L))
  for (limit in c(2L, 100L)) {
    state <- pva_state(pop, pedigree = TRUE, max_dense_kinship = limit)
    k <- kinship_matrix(state)
    expect_identical(k[1L, 2L], 0.25)
    expect_identical(k[1L, 3L], 0.25)
    expect_identical(state$population$pedigree_F[5L], 0.25)
    expect_equal(summarise_pedigree(state)$mean_kinship, mean(k))
  }
  pop$mother_id[3L] <- 1L
  expect_error(pva_state(pop, pedigree = TRUE), "cyclic")
  pop$mother_id[3L] <- 77L
  expect_error(pva_state(pop, pedigree = TRUE), "unresolvable")
  expect_equal(kinship_matrix(pva_state(pop, pedigree = TRUE, kinship = diag(0.5, 5))), diag(0.5, 5))
})

test_that("partial pedigrees and parents lost before birth agree in both storage modes", {
  for (limit in c(1L, 100L)) for (mode in c("strict", "fast")) {
    kin <- matrix(c(0.5, 0.125, 0.125, 0.625), 2L)
    state <- pva_state(adult_population(1L, 1L, mate_id = NA_integer_),
                       pedigree = TRUE, kinship = kin, max_dense_kinship = limit)
    paired <- pairing_process(always, capacity = 1, priority = "id")
    harvest <- removal_process(select = function(pop, state, context, params) pop$sex == "M")
    breed <- reproduction_process(1, litter_categorical(1, 1), offspring_sex_bernoulli(1),
                                  mate = mate_from_field(),
                                  newborn_fields = function(...) list(mate_id = NA_integer_),
                                  newborn_field_names = "mate_id")
    result <- execute_processes(state, list(paired, harvest, breed), validation = mode)
    expect_identical(result$state$population$father_id[2L], 2L)
    expect_identical(result$state$population$pedigree_F[2L], 0.125)
    expect_equal(kinship_matrix(result$state)[1L, 2L], (0.5 + 0.125) / 2)

    single <- reproduction_process(1, litter_categorical(1, 1), offspring_sex_bernoulli(1),
                                   newborn_fields = function(...) list(mate_id = NA_integer_),
                                   newborn_field_names = "mate_id")
    family <- execute_processes(state, list(single), validation = mode)$state
    expect_false(anyNA(kinship_matrix(family)))
    expect_identical(kinship_matrix(family)[1L, 3L], 0.25)
  }
})

test_that("compressed pedigrees, including a mid-run switch, match the dense oracle", {
  base <- diag(0.5, 8L)
  base[2L, 7L] <- base[7L, 2L] <- 0.125
  base[1L, 1L] <- 0.625
  scenario <- pedigree_scenario(n_runs = 2L, n_steps = 24L, seed = 71L, kinship = base)
  initial <- scenario$init_fun()
  pop <- initial$population
  pop$pedigree_F <- NULL
  for (limit in c(3L, 12L)) {
    scenario$init_fun <- function() pva_state(pop, pedigree = TRUE, kinship = base,
                                              max_dense_kinship = limit)
    result <- run_scenario(scenario, keep = c("ledger", "state"))
    for (i in seq_along(result$states)) {
      state <- result$states[[i]]
      ledger <- result$ledgers[[i]]
      oracle <- dense_relationship(ledger, initial_relationship = 2 * base) / 2
      f <- 2 * diag(oracle) - 1
      expect_gt(sum(f > 0), 8)
      expect_lt(max(abs(f - ledger$pedigree_F)), 1e-13)
      expect_true(is.list(state$kinship))
      living <- match(state$population$id, ledger$id)
      expected <- oracle[living, living, drop = FALSE]
      expect_lt(max(c(0, abs(expected - kinship_matrix(state)))), 1e-13)
      expect_equal(summarise_pedigree(state)$mean_kinship, mean(expected), tolerance = 1e-13)
    }
  }
})

test_that("generation time scales drift, and migration must account for actual introductions", {
  ne <- function(...) 5
  expect_error(inbreeding_proxy_process(ne), "generation_time")
  proxy <- inbreeding_proxy_process(ne, 4)
  state <- pva_state(adult_population(), globals = list(inbreeding_proxy = 0))
  later <- execute_processes(state, rep(list(proxy), 4L))$state
  expect_equal(later$globals$inbreeding_proxy, 0.1)
  for (bad in list(NULL, numeric(), NA_real_, "0")) {
    s <- pva_state(adult_population(), globals = list(inbreeding_proxy = bad))
    expect_error(execute_processes(s, list(proxy)), "initialise globals")
  }
  intro <- introduction_process(1, function(...) list(sex = "F", age = 2L))
  expect_error(execute_processes(state, list(proxy, intro)), "explicit migration")
  expect_warning(execute_processes(state, list(intro, proxy), validation = "fast"), "explicit migration")
})
