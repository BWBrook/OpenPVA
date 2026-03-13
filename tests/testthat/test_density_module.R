make_density_test_population <- function(
    n_female = 4L,
    n_male = 4L,
    patch_ids = NULL) {
  n_female <- as.integer(n_female)
  n_male <- as.integer(n_male)
  n_total <- n_female + n_male
  if (is.null(patch_ids)) {
    patch_ids <- rep.int(NA_integer_, n_total)
  }
  stopifnot(length(patch_ids) == n_total)

  population <- vector("list", n_total)
  sexes <- c(rep.int("F", n_female), rep.int("M", n_male))
  for (i in seq_len(n_total)) {
    population[[i]] <- create_individual(
      id = i,
      sex = sexes[[i]],
      age = 4L,
      patch_id = patch_ids[[i]]
    )
  }
  population
}

test_that("density_spec validates channel function contracts", {
  spec <- density_spec(
    survival_fun = function(population, ind) 1
  )
  expect_s3_class(spec, "openpva_density_spec")

  expect_error(density_spec(), "at least one channel function")
  expect_error(validate_density_spec(1), "must be a list")
  expect_error(
    validate_density_spec(list(foo = function(population, ind) 1)),
    "unknown fields"
  )
  expect_error(
    validate_density_spec(list(survival_fun = "not_a_function")),
    "must be NULL or a function"
  )
})

test_that("make_ceiling_density_fun computes global and patch multipliers", {
  pop_global <- make_density_test_population(n_female = 2L, n_male = 2L)
  f_global <- make_ceiling_density_fun(K = 2)
  expect_equal(f_global(pop_global, pop_global[[1]]), 0.5)

  pop_patch <- make_density_test_population(
    n_female = 3L,
    n_male = 2L,
    patch_ids = c(1L, 1L, 2L, 2L, 2L)
  )
  f_patch <- make_ceiling_density_fun(K_patches = c(1, 3))
  expect_equal(f_patch(pop_patch, pop_patch[[1]]), 0.5)
  expect_equal(f_patch(pop_patch, pop_patch[[3]]), 1)
})

test_that("density survival channel scales survival outcomes", {
  pop <- make_density_test_population(n_female = 3L, n_male = 3L)

  out <- run_basic_simulation(
    initial_population = pop,
    n_years = 1,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 0,
    fecundity_lambda_fun = function(ind) 0,
    lifecycle_steps = c("age", "survival"),
    density_spec = density_spec(
      survival_fun = function(population, ind) 0
    )
  )

  expect_equal(out$summary$n_alive[[1]], 0L)
})

test_that("density breeding and fecundity channels scale reproduction pathway", {
  pop <- make_density_test_population(n_female = 6L, n_male = 6L)

  set.seed(20261102)
  out_neutral <- run_basic_simulation(
    initial_population = pop,
    n_years = 1,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 2,
    lifecycle_steps = c("age", "survival", "breeding_births"),
    density_spec = density_spec(
      breeding_fun = function(population, ind) 1,
      fecundity_fun = function(population, ind) 1
    )
  )

  out_no_breeding <- run_basic_simulation(
    initial_population = pop,
    n_years = 1,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 2,
    lifecycle_steps = c("age", "survival", "breeding_births"),
    density_spec = density_spec(
      breeding_fun = function(population, ind) 0,
      fecundity_fun = function(population, ind) 1
    )
  )

  out_no_fecundity <- run_basic_simulation(
    initial_population = pop,
    n_years = 1,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 2,
    lifecycle_steps = c("age", "survival", "breeding_births"),
    density_spec = density_spec(
      breeding_fun = function(population, ind) 1,
      fecundity_fun = function(population, ind) 0
    )
  )

  expect_gt(out_neutral$summary$n_births[[1]], 0L)
  expect_equal(out_no_breeding$summary$n_births[[1]], 0L)
  expect_equal(out_no_fecundity$summary$n_births[[1]], 0L)
})

test_that("density functions must return finite non-negative scalars", {
  pop <- make_density_test_population(n_female = 2L, n_male = 2L)

  expect_error(
    run_basic_simulation(
      initial_population = pop,
      n_years = 1,
      survival_fun = function(ind) 1,
      breeding_prob_fun = function(ind) 1,
      fecundity_lambda_fun = function(ind) 1,
      lifecycle_steps = c("age", "survival", "breeding_births"),
      density_spec = density_spec(
        breeding_fun = function(population, ind) -1
      )
    ),
    "breeding density function must return"
  )
})

test_that("replicate runs remain deterministic with active density_spec and seed", {
  init_fun <- function() make_density_test_population(n_female = 8L, n_male = 8L)
  spec <- density_spec(
    survival_fun = make_ceiling_density_fun(K = 12),
    breeding_fun = function(population, ind) 0.9,
    fecundity_fun = function(population, ind) 0.8
  )

  out_a <- run_basic_simulation_replicates(
    n_runs = 4,
    n_years = 5,
    init_fun = init_fun,
    survival_fun = function(ind) 0.9,
    breeding_prob_fun = function(ind) 0.7,
    fecundity_lambda_fun = function(ind) 1.8,
    density_spec = spec,
    seed = 9911L
  )
  out_b <- run_basic_simulation_replicates(
    n_runs = 4,
    n_years = 5,
    init_fun = init_fun,
    survival_fun = function(ind) 0.9,
    breeding_prob_fun = function(ind) 0.7,
    fecundity_lambda_fun = function(ind) 1.8,
    density_spec = spec,
    seed = 9911L
  )

  expect_identical(out_a$summary, out_b$summary)
  expect_identical(out_a$extinction, out_b$extinction)
})
