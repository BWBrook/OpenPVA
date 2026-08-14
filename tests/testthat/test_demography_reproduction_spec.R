breeding_table <- function() {
  data.frame(
    age_min = c(0, 4, 0),
    age_max = c(3, Inf, Inf),
    sex = c("F", "F", "M"),
    p_breed = c(0, 0.6, 0)
  )
}

fecundity_table <- function() {
  data.frame(
    age_min = c(0, 4, 0),
    age_max = c(3, Inf, Inf),
    sex = c("F", "F", "M"),
    lambda = c(0, 1.5, 0)
  )
}

test_that("reproduction tables enforce structure, bounds and non-overlap", {
  expect_error(validate_breeding_prob_table(breeding_table()), NA)
  expect_error(validate_fecundity_lambda_table(fecundity_table()), NA)

  overlapping <- breeding_table()
  overlapping$age_min[[2L]] <- 3
  expect_error(validate_breeding_prob_table(overlapping), "Overlapping age ranges")

  invalid_probability <- breeding_table()
  invalid_probability$p_breed[[2L]] <- 1.1
  expect_error(validate_breeding_prob_table(invalid_probability), "p_breed")

  invalid_lambda <- fecundity_table()
  invalid_lambda$lambda[[2L]] <- -1
  expect_error(validate_fecundity_lambda_table(invalid_lambda), "lambda")

  factor_sex <- breeding_table()
  factor_sex$sex <- factor(factor_sex$sex)
  expect_error(validate_breeding_prob_table(factor_sex), "sex must be character")
})

test_that("reproduction table builders return explicit matched values", {
  breeding_probability <- build_breeding_prob_fun_from_table(breeding_table())
  fecundity_mean <- build_fecundity_lambda_fun_from_table(fecundity_table())

  expect_equal(breeding_probability(create_individual(1L, "F", age = 2L)), 0)
  expect_equal(breeding_probability(create_individual(2L, "F", age = 6L)), 0.6)
  expect_equal(breeding_probability(create_individual(3L, "M", age = 6L)), 0)
  expect_equal(fecundity_mean(create_individual(4L, "F", age = 2L)), 0)
  expect_equal(fecundity_mean(create_individual(5L, "F", age = 6L)), 1.5)
  expect_equal(fecundity_mean(create_individual(6L, "M", age = 6L)), 0)
})

test_that("reproduction table builders reject missing coverage", {
  breeding_probability <- build_breeding_prob_fun_from_table(breeding_table())
  fecundity_mean <- build_fecundity_lambda_fun_from_table(fecundity_table())

  expect_error(
    breeding_probability(create_individual(1L, "U", age = 2L)),
    "No breeding probability rows found for sex"
  )
  expect_error(
    fecundity_mean(create_individual(2L, "U", age = 2L)),
    "No fecundity lambda rows found for sex"
  )

  gap <- breeding_table()
  gap$age_min[[2L]] <- 5
  breeding_with_gap <- build_breeding_prob_fun_from_table(gap)
  expect_error(
    breeding_with_gap(create_individual(3L, "F", age = 4L)),
    "No breeding probability row matches age"
  )
})

test_that("reproduction table builders reject malformed individuals", {
  breeding_probability <- build_breeding_prob_fun_from_table(breeding_table())
  fecundity_mean <- build_fecundity_lambda_fun_from_table(fecundity_table())

  expect_error(breeding_probability(list(age = 4L)), "individual\\$sex")
  expect_error(fecundity_mean(list(sex = "F")), "individual\\$age")
  expect_error(fecundity_mean(4L), "individual must be a list")
})
