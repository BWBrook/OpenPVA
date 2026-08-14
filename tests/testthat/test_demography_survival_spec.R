survival_table <- function() {
  data.frame(
    age_min = c(0, 3, 0),
    age_max = c(2, Inf, Inf),
    sex = c("F", "F", "M"),
    p_surv = c(0.8, 0.9, 0.7)
  )
}

test_that("survival tables enforce structure, bounds and non-overlap", {
  expect_error(validate_survival_table(survival_table()), NA)

  overlapping <- survival_table()
  overlapping$age_min[[2L]] <- 2
  expect_error(validate_survival_table(overlapping), "Overlapping age ranges")

  out_of_bounds <- survival_table()
  out_of_bounds$p_surv[[1L]] <- 1.1
  expect_error(validate_survival_table(out_of_bounds), "p_surv")

  negative_age <- survival_table()
  negative_age$age_min[[1L]] <- -1
  expect_error(validate_survival_table(negative_age), "non-negative")

  non_numeric <- survival_table()
  non_numeric$p_surv <- as.character(non_numeric$p_surv)
  expect_error(validate_survival_table(non_numeric), "p_surv must be numeric")
})

test_that("survival table builders return explicit matched values", {
  survival <- build_survival_fun_from_table(survival_table())

  expect_equal(survival(create_individual(1L, "F", age = 1L)), 0.8)
  expect_equal(survival(create_individual(2L, "F", age = 8L)), 0.9)
  expect_equal(survival(create_individual(3L, "M", age = 8L)), 0.7)
})

test_that("survival table builders reject missing coverage and malformed input", {
  survival <- build_survival_fun_from_table(survival_table())
  gap_table <- survival_table()
  gap_table$age_min[[2L]] <- 4
  survival_with_gap <- build_survival_fun_from_table(gap_table)

  expect_error(
    survival(create_individual(1L, "U", age = 2L)),
    "No survival rows found for sex"
  )
  expect_error(
    survival_with_gap(create_individual(2L, "F", age = 3L)),
    "No survival row matches age"
  )
  expect_error(survival(list(age = 2L)), "individual\\$sex")
  expect_error(survival(list(sex = "F", age = NA_real_)), "individual\\$age")
  expect_error(survival("not an individual"), "individual must be a list")
})
