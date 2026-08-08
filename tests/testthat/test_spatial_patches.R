test_that("initialize_patches assigns explicit and computed patch ids", {
  base <- initialize_population(6L, max_age = 2L)
  explicit <- initialize_patches(base, patch_ids = c(1L, 1L, 2L, 2L, 3L, 3L))
  expect_identical(vapply(explicit, `[[`, integer(1), "patch_id"),
                   c(1L, 1L, 2L, 2L, 3L, 3L))

  round_robin <- initialize_patches(base, n_patches = 2L)
  expect_identical(vapply(round_robin, `[[`, integer(1), "patch_id"),
                   c(1L, 2L, 1L, 2L, 1L, 2L))
  expect_error(initialize_patches(base, patch_ids = c(1L, 2L)), "length")
})

test_that("spatial population initializers create patch and genotype structure", {
  spatial <- initialize_spatial_population(c(3L, 2L), max_age = 3L)
  expect_length(spatial, 5L)
  expect_identical(vapply(spatial, `[[`, integer(1), "patch_id"),
                   c(1L, 1L, 1L, 2L, 2L))

  genetic <- initialize_spatial_genetic_population(c(2L, 2L), n_loci = 3L)
  expect_true(all(vapply(genetic, function(ind) is.matrix(ind$alleles), logical(1))))
})

test_that("dispersal helpers update living individuals and preserve the dead", {
  population <- initialize_patches(
    initialize_population(4L),
    patch_ids = c(1L, 1L, 2L, 2L)
  )
  population[[1L]]$alive <- FALSE
  move <- function(ind, population) if (ind$patch_id == 1L) 2L else ind$patch_id
  result <- apply_dispersal(population, move)
  expect_identical(vapply(result, `[[`, integer(1), "patch_id"), c(1L, 2L, 2L, 2L))
})

test_that("Markov dispersal validates and samples destination rows", {
  transition <- matrix(c(1, 0, 0, 1), nrow = 2L, byrow = TRUE)
  move <- make_markov_dispersal_fun(transition)
  first <- create_individual(1L, "F", 2L, patch_id = 1L)
  second <- create_individual(2L, "M", 2L, patch_id = 2L)
  expect_identical(move(first, list(first, second)), 1L)
  expect_identical(move(second, list(first, second)), 2L)
  expect_error(make_markov_dispersal_fun(matrix(c(0.5, 0.2), nrow = 1L)), "square")
})
