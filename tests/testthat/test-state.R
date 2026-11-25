test_that("populations are columnar, typed and living", {
  population <- pva_population(sex = c("F", "M", "F"), age = c(0, 3, 7), patch = "a")
  expect_identical(population$id, 1:3)
  expect_identical(population$age, c(0L, 3L, 7L))
  expect_identical(population$origin, rep("initial", 3L))
  expect_identical(population$entry_time, rep(-1L, 3L))
  expect_identical(population$patch, rep("a", 3L))
  expect_true(all(is.na(population$mother_id)))

  expect_error(pva_population(sex = c("F", "X"), age = 1), "sex must be")
  expect_error(pva_population(sex = "F", age = 1.5), "whole numbers")
  expect_error(pva_population(sex = "F", age = -1), "non-negative")
  expect_error(pva_population(sex = c("F", "M"), age = 1, weight = 1:3), "length 1 or")
  expect_error(pva_population(sex = "F", age = 1, 3), "must be named")
})

test_that("states validate inputs and own identifiers and pedigree", {
  state <- pva_state(data.frame(sex = c("F", "M"), age = c(2, 4)), globals = list(k = 5))
  expect_s3_class(state, "pva_state")
  expect_identical(state$next_id, 3L)
  expect_null(state$kinship)
  expect_output(print(state), "pedigree: off")

  tracked <- pva_state(adult_population(2L, 1L), pedigree = TRUE)
  expect_identical(tracked$population$pedigree_F, rep(0, 3L))
  expect_identical(tracked$kinship, diag(0.5, 3L))

  related <- matrix(c(0.5, 0.25, 0.25, 0.625), 2L)
  inbred <- pva_state(adult_population(1L, 1L), pedigree = TRUE, kinship = related)
  expect_equal(inbred$population$pedigree_F, c(0, 0.25))

  expect_error(pva_state(adult_population(1L, 1L), globals = list(1)), "uniquely named")
  expect_error(pva_state(adult_population(1L, 1L), kinship = related), "pedigree = TRUE")
  expect_error(
    pva_state(adult_population(1L, 1L), pedigree = TRUE, kinship = diag(0.2, 2L)),
    "self-kinship"
  )
  expect_error(
    pva_state(data.frame(sex = "F", age = 1, pedigree_F = 0)),
    "engine-owned"
  )
  expect_error(pva_state(data.frame(sex = "F", age = 1, id = 4L)), "engine fields")
})

test_that("add_individuals allocates ids and demands complete initialisation", {
  state <- pva_state(adult_population(1L, 1L, patch = "a"))
  grown <- add_individuals(state, sex = c("M", "F"), age = 0L, patch = "b", mother_id = 1L)
  expect_identical(grown$population$id, 1:4)
  expect_identical(grown$next_id, 5L)
  expect_identical(grown$population$patch, c("a", "a", "b", "b"))
  expect_true(all(is.na(grown$population$origin[3:4])))
  expect_identical(add_individuals(state, sex = character(), age = integer()), state)

  expect_error(add_individuals(state, sex = "F", age = 0L), "initialise exactly")
  expect_error(
    add_individuals(state, sex = "F", age = 0L, patch = "a", weight = 1),
    "initialise exactly"
  )
  expect_error(add_individuals(state, sex = "F", age = 0L, patch = 1L), "has type")
})
