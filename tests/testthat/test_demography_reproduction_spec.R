test_that("default breeding and fecundity rate functions return expected baselines", {
  expect_equal(default_breeding_prob_fun(create_individual(1L, "F", age = 3L)), 0)
  expect_equal(default_breeding_prob_fun(create_individual(2L, "F", age = 4L)), 1)
  expect_equal(default_breeding_prob_fun(create_individual(3L, "M", age = 6L)), 0)

  expect_equal(default_fecundity_lambda_fun(create_individual(4L, "F", age = 5L)), 1.5)
  expect_equal(default_fecundity_lambda_fun(create_individual(5L, "M", age = 5L)), 0)
})

test_that("validate_breeding_prob_table enforces required structure and bounds", {
  tbl <- data.frame(
    age_min = c(0, 4, 0),
    age_max = c(3, Inf, Inf),
    sex = c("F", "F", "M"),
    p_breed = c(0, 1, 0)
  )
  expect_error(validate_breeding_prob_table(tbl), NA)

  tbl_overlap <- tbl
  tbl_overlap$age_min[2] <- 2
  expect_error(validate_breeding_prob_table(tbl_overlap), "Overlapping age ranges")

  tbl_bad <- tbl
  tbl_bad$p_breed[2] <- 1.1
  expect_error(validate_breeding_prob_table(tbl_bad), "p_breed")
})

test_that("breeding probability table builder returns expected values", {
  tbl <- data.frame(
    age_min = c(0, 3),
    age_max = c(2, Inf),
    sex = c("F", "F"),
    p_breed = c(0.1, 0.7)
  )
  prob_fun <- build_breeding_prob_fun_from_table(tbl)

  expect_equal(prob_fun(create_individual(1L, "F", age = 1L)), 0.1)
  expect_equal(prob_fun(create_individual(2L, "F", age = 5L)), 0.7)
  expect_equal(prob_fun(create_individual(3L, "M", age = 5L)), 0)
})

test_that("validate_fecundity_lambda_table enforces required structure and bounds", {
  tbl <- data.frame(
    age_min = c(0, 4),
    age_max = c(3, Inf),
    sex = c("F", "F"),
    lambda = c(0, 2.5)
  )
  expect_error(validate_fecundity_lambda_table(tbl), NA)

  tbl_bad <- tbl
  tbl_bad$lambda[2] <- -1
  expect_error(validate_fecundity_lambda_table(tbl_bad), "lambda")
})

test_that("fecundity lambda table builder returns expected values", {
  tbl <- data.frame(
    age_min = c(0, 4),
    age_max = c(3, Inf),
    sex = c("F", "F"),
    lambda = c(0, 2.5)
  )
  lambda_fun <- build_fecundity_lambda_fun_from_table(tbl)

  expect_equal(lambda_fun(create_individual(1L, "F", age = 1L)), 0)
  expect_equal(lambda_fun(create_individual(2L, "F", age = 5L)), 2.5)
  expect_equal(lambda_fun(create_individual(3L, "M", age = 5L)), 0)
})

test_that("default probability and lambda tables are valid", {
  breeding_tbl <- make_default_breeding_prob_table()
  fecundity_tbl <- make_default_fecundity_lambda_table()

  expect_error(validate_breeding_prob_table(breeding_tbl), NA)
  expect_error(validate_fecundity_lambda_table(fecundity_tbl), NA)
})
