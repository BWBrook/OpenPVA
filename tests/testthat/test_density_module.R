make_density_test_population <- function(
    n_female = 4L,
    n_male = 4L,
    patch_ids = NULL) {
  n_total <- as.integer(n_female + n_male)
  if (is.null(patch_ids)) patch_ids <- rep.int(NA_integer_, n_total)
  sexes <- c(rep.int("F", n_female), rep.int("M", n_male))
  lapply(seq_len(n_total), function(id) {
    create_individual(id, sexes[[id]], 4L, patch_id = patch_ids[[id]])
  })
}

test_that("density_spec validates channel function contracts", {
  spec <- density_spec(survival_fun = function(population, ind) 1)
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
  expect_equal(f_global(pop_global, pop_global[[1L]]), 0.5)

  pop_patch <- make_density_test_population(
    n_female = 3L,
    n_male = 2L,
    patch_ids = c(1L, 1L, 2L, 2L, 2L)
  )
  f_patch <- make_ceiling_density_fun(K_patches = c(1, 3))
  expect_equal(f_patch(pop_patch, pop_patch[[1L]]), 0.5)
  expect_equal(f_patch(pop_patch, pop_patch[[3L]]), 1)
})
