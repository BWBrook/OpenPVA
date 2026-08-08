test_that("apply_supplementation handles quotas, stable ids, and patch assignment", {
  population <- initialize_population(3L)
  unchanged <- apply_supplementation(population, 0L)
  expect_identical(unchanged$population, population)
  expect_identical(unchanged$n_added, 0L)

  result <- apply_supplementation(population, 2L, patch_id = 3L)
  newcomers <- tail(result$population, 2L)
  expect_identical(vapply(newcomers, `[[`, integer(1), "id"), c(4L, 5L))
  expect_true(all(vapply(newcomers, `[[`, integer(1), "patch_id") == 3L))
  expect_error(apply_supplementation(population, 1.5), "non-negative integer")
})
