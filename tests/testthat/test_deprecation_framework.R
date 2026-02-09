test_that("soft-deprecated legacy wrappers warn once per session", {
  old <- options(openpva.deprecation_warnings = TRUE)
  on.exit(options(old), add = TRUE)

  .reset_deprecation_registry()
  tbl_b <- data.frame(
    age_min = c(0, 2),
    age_max = c(1, 10),
    sex = c("F", "F"),
    can_breed = c(FALSE, TRUE)
  )
  expect_warning(
    validate_breeding_table(tbl_b),
    "soft-deprecated for OpenPVA 2.0"
  )
  expect_warning(validate_breeding_table(tbl_b), NA)

  .reset_deprecation_registry()
  tbl_f <- data.frame(
    age_min = c(0, 0),
    age_max = c(10, 10),
    sex = c("F", "M"),
    lambda = c(1.2, 0)
  )
  expect_warning(
    validate_fecundity_table(tbl_f),
    "soft-deprecated for OpenPVA 2.0"
  )
  expect_warning(validate_fecundity_table(tbl_f), NA)
})

test_that("deprecation warnings can be suppressed with option", {
  old <- options(openpva.deprecation_warnings = FALSE)
  on.exit(options(old), add = TRUE)
  .reset_deprecation_registry()

  tbl <- data.frame(
    age_min = c(0, 2),
    age_max = c(1, 10),
    sex = c("F", "F"),
    can_breed = c(FALSE, TRUE)
  )
  expect_warning(validate_breeding_table(tbl), NA)
})

test_that("legacy wrappers remain runtime-compatible", {
  old <- options(openpva.deprecation_warnings = FALSE)
  on.exit(options(old), add = TRUE)

  breeding_tbl <- data.frame(
    age_min = c(0, 2),
    age_max = c(1, 10),
    sex = c("F", "F"),
    can_breed = c(FALSE, TRUE)
  )
  fec_tbl <- data.frame(
    age_min = c(0, 0),
    age_max = c(10, 10),
    sex = c("F", "M"),
    lambda = c(2, 0)
  )

  breeding_fun <- build_breeding_fun_from_table(breeding_tbl)
  fec_fun <- build_fecundity_fun_from_table(fec_tbl)
  ind <- create_individual(id = 1L, sex = "F", age = 3L)

  expect_true(isTRUE(breeding_fun(ind)))
  expect_type(fec_fun(ind), "integer")
})
