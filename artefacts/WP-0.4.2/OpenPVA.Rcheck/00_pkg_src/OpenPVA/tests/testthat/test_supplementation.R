test_that("apply_supplementation handles quotas and patch ids", {
  pop <- initialize_population(n = 3, max_age = 1)

  res_zero <- apply_supplementation(pop, n_add = 0)
  expect_equal(res_zero$n_added, 0L)
  expect_length(res_zero$population, 3L)

  set.seed(123)
  res_add <- apply_supplementation(pop, n_add = 2)
  expect_equal(res_add$n_added, 2L)
  expect_length(res_add$population, 5L)
  new_inds <- tail(res_add$population, 2)
  expect_true(all(vapply(new_inds, function(ind) ind$age == 0L, logical(1))))
  expect_true(all(vapply(new_inds, function(ind) is.na(ind$patch_id), logical(1))))

  res_patch <- apply_supplementation(pop, n_add = 1, patch_id = 2L)
  new_ind <- tail(res_patch$population, 1)[[1]]
  expect_equal(new_ind$patch_id, 2L)
})

test_that("supplementation step increases population and summary tracks additions", {
  pop <- initialize_population(n = 3, max_age = 1)
  survival_fun <- function(ind) 1
  breeding_fun <- function(ind) FALSE
  fecundity_fun <- function(ind) 0L
  steps <- c("age", "survival", "supplementation", "harvest")

  res <- run_basic_simulation(
    initial_population = pop,
    n_years = 1,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun,
    lifecycle_steps = steps,
    supplement_quota = 2,
    supplement_patch = 3L
  )

  expect_length(res$population, 5L)
  patch_counts <- table(vapply(res$population, function(ind) ind$patch_id, integer(1)))
  expect_equal(patch_counts[[as.character(3)]], 2L)
  expect_equal(res$summary$n_supplemented[1], 2L)
  expect_equal(res$summary$n_alive[1], 5L)
})

test_that("replicated simulations handle supplementation quotas", {
  init_fun <- function() initialize_population(n = 3, max_age = 1)
  survival_fun <- function(ind) 1
  breeding_fun <- function(ind) FALSE
  fecundity_fun <- function(ind) 0L
  steps <- c("age", "survival", "supplementation")

  res <- run_basic_simulation_replicates(
    n_runs = 3,
    n_years = 2,
    init_fun = init_fun,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun,
    lifecycle_steps = steps,
    supplement_quota = 1,
    supplement_patch = 1L
  )

  expect_equal(nrow(res$summary), 6L)
  expect_true(all(res$summary$n_supplemented == 1L))
  expect_true(all(diff(res$summary$n_alive[res$summary$run == 1]) >= 0))
})

test_that("scenario supplementation plumbing works", {
  steps <- c("age", "survival", "supplementation", "harvest")

  sc_no <- scenario_spec(
    name = "no_supp",
    n_runs = 2,
    n_years = 2,
    init_fun = function() initialize_population(5),
    lifecycle_steps = steps
  )
  sc_yes <- scenario_spec(
    name = "supp",
    n_runs = 2,
    n_years = 2,
    init_fun = function() initialize_population(5),
    lifecycle_steps = steps,
    supplement_quota = 2,
    supplement_patch = 1L
  )

  out_no <- run_scenario(sc_no)
  out_yes <- run_scenario(sc_yes)

  expect_true(all(out_no$sim_output$summary$n_supplemented == 0L))
  expect_true(any(out_yes$sim_output$summary$n_supplemented > 0L))
})
