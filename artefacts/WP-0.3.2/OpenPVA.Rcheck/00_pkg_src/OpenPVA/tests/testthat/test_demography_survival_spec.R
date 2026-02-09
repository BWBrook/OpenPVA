test_that("validate_survival_table accepts a basic valid table", {
  tbl <- data.frame(
    age_min = c(0, 1, 5),
    age_max = c(0, 4, Inf),
    sex = c("F", "F", "F"),
    p_surv = c(0.85, 0.92, 0.70)
  )

  expect_error(validate_survival_table(tbl), NA)
})

test_that("validate_survival_table detects overlapping ranges per sex", {
  tbl_bad <- data.frame(
    age_min = c(0, 0),
    age_max = c(5, 10),
    sex = c("F", "F"),
    p_surv = c(0.8, 0.9)
  )

  expect_error(validate_survival_table(tbl_bad))
})

test_that("validate_survival_table checks p_surv bounds", {
  tbl_bad <- data.frame(
    age_min = c(0, 1),
    age_max = c(0, 2),
    sex = c("F", "F"),
    p_surv = c(-0.1, 1.1)
  )

  expect_error(validate_survival_table(tbl_bad))
})

test_that("make_default_survival_table returns expected structure", {
  tbl_default <- make_default_survival_table()

  expect_true(all(c("age_min", "age_max", "sex", "p_surv") %in% names(tbl_default)))
  expect_equal(sort(unique(tbl_default$sex)), c("F", "M"))
  expect_equal(nrow(tbl_default), 6)
  expect_error(validate_survival_table(tbl_default), NA)
})

test_that("table-built survival matches default_survival_fun", {
  tbl_default <- make_default_survival_table()
  surv_tbl_fun <- build_survival_fun_from_table(tbl_default)

  ages <- c(0L, 1L, 3L, 5L, 10L)
  sexes <- c("F", "M")

  for (age in ages) {
    for (sex in sexes) {
      ind <- create_individual(id = 1L, sex = sex, age = age)
      p_default <- default_survival_fun(ind)
      p_table <- surv_tbl_fun(ind)
      expect_equal(p_default, p_table)
    }
  }

  ind_old <- create_individual(id = 2L, sex = "F", age = 50L)
  expect_equal(surv_tbl_fun(ind_old), 0.70)
})

test_that("build_survival_fun_from_table errors when sex is missing from table", {
  tbl <- data.frame(
    age_min = c(0, 2),
    age_max = c(1, 5),
    sex = c("F", "F"),
    p_surv = c(0.9, 0.8)
  )

  surv_fun <- build_survival_fun_from_table(tbl)
  ind_male <- create_individual(id = 1L, sex = "M", age = 3L)
  expect_error(surv_fun(ind_male))
})
