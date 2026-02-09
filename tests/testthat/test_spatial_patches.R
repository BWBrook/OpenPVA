test_that("initialize_patches assigns explicit and computed patch_ids", {
  base_pop <- initialize_population(n = 6, max_age = 2)

  pop_explicit <- initialize_patches(base_pop, patch_ids = c(1, 1, 2, 2, 3, 3))
  expect_equal(vapply(pop_explicit, function(ind) ind$patch_id, integer(1)), c(1L, 1L, 2L, 2L, 3L, 3L))

  pop_round_robin <- initialize_patches(base_pop, n_patches = 2)
  expect_equal(vapply(pop_round_robin, function(ind) ind$patch_id, integer(1)), c(1L, 2L, 1L, 2L, 1L, 2L))

  assignment_fun <- function(population, n_patches) rep.int(1L, length(population))
  pop_custom <- initialize_patches(base_pop, n_patches = 3, assignment_fun = assignment_fun)
  expect_true(all(vapply(pop_custom, function(ind) ind$patch_id, integer(1)) == 1L))

  expect_error(initialize_patches(base_pop, n_patches = 0), "n_patches")
})

test_that("run_basic_simulation applies patch-level K", {
  make_pop <- function() {
    pop <- initialize_population(n = 6, max_age = 1)
    initialize_patches(pop, patch_ids = c(1, 1, 1, 2, 2, 2))
  }
  survival_fun <- function(ind) 1
  breeding_fun <- function(ind) FALSE
  fecundity_fun <- function(ind) 0L

  set.seed(101)
  res_none <- run_basic_simulation(
    initial_population = make_pop(),
    n_years = 1,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun
  )
  expect_equal(res_none$summary$n_alive[1], 6L)
  expect_equal(res_none$summary$survival_scale[1], 1)

  set.seed(101)
  res_patch <- run_basic_simulation(
    initial_population = make_pop(),
    n_years = 1,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun,
    K_patches = c(1, 1)
  )
  expect_lt(res_patch$summary$n_alive[1], res_none$summary$n_alive[1])
  expect_true(is.na(res_patch$summary$survival_scale[1]))

  expect_error(
    run_basic_simulation(
      initial_population = make_pop(),
      n_years = 1,
      survival_fun = survival_fun,
      breeding_fun = breeding_fun,
      fecundity_fun = fecundity_fun,
      K = 100,
      K_patches = c(50, 50)
    ),
    "Specify either K or K_patches"
  )
})

test_that("run_basic_simulation_replicates threads patch-level K", {
  init_fun <- function() {
    pop <- initialize_population(n = 4, max_age = 1)
    initialize_patches(pop, patch_ids = c(1, 1, 2, 2))
  }
  survival_fun <- function(ind) 1
  breeding_fun <- function(ind) FALSE
  fecundity_fun <- function(ind) 0L

  set.seed(202)
  res <- run_basic_simulation_replicates(
    n_runs = 3,
    n_years = 1,
    init_fun = init_fun,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun,
    K_patches = c(1, 1)
  )
  expect_equal(nrow(res$summary), 3L)
  expect_true(all(res$summary$n_alive < 4L))
  expect_true(all(is.na(res$summary$survival_scale)))
})

test_that("apply_dispersal updates patch_ids for alive individuals", {
  pop <- initialize_population(n = 4, max_age = 1)
  pop <- initialize_patches(pop, patch_ids = c(1, 1, 2, 2))
  pop[[1]]$alive <- FALSE

  dispersal_fun <- function(ind, population) {
    if (!is.na(ind$patch_id) && ind$patch_id == 1L) return(2L)
    ind$patch_id
  }

  pop_after <- apply_dispersal(pop, dispersal_fun)
  patch_ids <- vapply(pop_after, function(ind) ind$patch_id, integer(1))
  expect_equal(patch_ids, c(1L, 2L, 2L, 2L))
})

test_that("lifecycle pipeline supports dispersal step", {
  pop <- initialize_population(n = 4, max_age = 1)
  pop <- initialize_patches(pop, patch_ids = c(1, 1, 2, 2))

  survival_fun <- function(ind) 1
  breeding_fun <- function(ind) FALSE
  fecundity_fun <- function(ind) 0L
  dispersal_fun <- function(ind, population) {
    if (!is.na(ind$patch_id) && ind$patch_id == 1L) return(2L)
    ind$patch_id
  }

  steps <- c("age", "survival", "dispersal", "breeding_births", "harvest")
  res <- run_basic_simulation(
    initial_population = pop,
    n_years = 1,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun,
    lifecycle_steps = steps,
    dispersal_fun = dispersal_fun
  )
  final_pids <- vapply(res$population, function(ind) ind$patch_id, integer(1))
  expect_true(all(final_pids == 2L))

  expect_error(
    run_basic_simulation(
      initial_population = pop,
      n_years = 1,
      survival_fun = survival_fun,
      breeding_fun = breeding_fun,
      fecundity_fun = fecundity_fun,
      lifecycle_steps = c("foo"),
      dispersal_fun = dispersal_fun
    ),
    "Invalid lifecycle steps"
  )
})

test_that("summarise_patch_occupancy_final aggregates across runs", {
  init_fun <- function() {
    pop <- initialize_population(n = 4, max_age = 1)
    initialize_patches(pop, patch_ids = c(1, 1, 2, 2))
  }
  survival_fun <- function(ind) 1
  breeding_fun <- function(ind) FALSE
  fecundity_fun <- function(ind) 0L
  dispersal_fun <- function(ind, population) ind$patch_id

  res <- run_basic_simulation_replicates(
    n_runs = 2,
    n_years = 1,
    init_fun = init_fun,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun,
    K_patches = c(10, 10),
    dispersal_fun = dispersal_fun
  )

  summary <- summarise_patch_occupancy_final(
    sim_output = res,
    n_patches = 2,
    alive_only = TRUE
  )
  expect_equal(nrow(summary), 2L)
  expect_equal(summary$n_runs, rep(2L, 2))
  expect_equal(summary$alive_only, rep(TRUE, 2))
  expect_true(all(summary$mean_n_alive > 0))
})

test_that("make_markov_dispersal_fun samples destinations by row", {
  tm <- matrix(c(0.8, 0.2,
                 0.1, 0.9),
               nrow = 2, byrow = TRUE)
  dispersal_fun <- make_markov_dispersal_fun(tm)

  ind1 <- create_individual(1L, "F", age = 2L, patch_id = 1L)
  ind2 <- create_individual(2L, "M", age = 2L, patch_id = 2L)

  set.seed(123)
  draws1 <- replicate(100, dispersal_fun(ind1, NULL))
  draws2 <- replicate(100, dispersal_fun(ind2, NULL))

  expect_true(all(draws1 %in% c(1L, 2L)))
  expect_true(all(draws2 %in% c(1L, 2L)))
  expect_true(sum(draws1 == 1L) > sum(draws1 == 2L))
  expect_true(sum(draws2 == 2L) > sum(draws2 == 1L))

  bad_tm <- matrix(c(0, 0, 1, 0), nrow = 2, byrow = TRUE)
  expect_error(make_markov_dispersal_fun(bad_tm), "positive sum")
})

test_that("summarise_patch_genetic_diversity_final aggregates per-patch diversity", {
  ind <- function(id, patch_id, alleles, alive = TRUE) {
    x <- create_individual(id = id, sex = "F", age = 3L, patch_id = patch_id)
    x$alive <- alive
    x$alleles <- alleles
    x$F <- if (is.null(alleles)) NA_real_ else .Fhat_from_alleles(alleles)
    x
  }

  run1_pop <- list(
    ind(1L, 1L, rbind(c(1L, 2L), c(2L, 1L))), # H = 1
    ind(2L, 2L, rbind(c(1L, 1L), c(1L, 1L)))  # H = 0
  )
  run2_pop <- list(
    ind(3L, 1L, rbind(c(1L, 1L), c(1L, 1L))), # H = 0
    ind(4L, 2L, NULL)
  )

  sim_output <- list(
    runs = list(
      list(population = run1_pop),
      list(population = run2_pop)
    )
  )

  summary <- summarise_patch_genetic_diversity_final(
    sim_output = sim_output,
    n_patches = 2,
    alive_only = TRUE
  )

  expect_equal(nrow(summary), 2L)
  expect_true(all(summary$n_runs == 2L))
  expect_equal(summary$mean_n_genotyped[summary$patch_id == 1L], 1)
  expect_equal(summary$p_patch_genotyped[summary$patch_id == 2L], 0.5)
  expect_equal(summary$mean_heterozygosity[summary$patch_id == 1L], 0.5)
  expect_equal(summary$mean_Fhat[summary$patch_id == 1L], 0.5)
})

test_that("summarise_patch_genetic_diversity_final validates inputs", {
  expect_error(
    summarise_patch_genetic_diversity_final(sim_output = list(), n_patches = 2),
    "non-empty 'runs'"
  )
  expect_error(
    summarise_patch_genetic_diversity_final(
      sim_output = list(runs = list(list(population = list()))),
      n_patches = 0
    ),
    "n_patches"
  )
})
