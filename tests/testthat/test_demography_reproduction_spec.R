test_that("validate_breeding_table accepts a basic valid table", {
  tbl <- data.frame(
    age_min = c(0, 4, 0),
    age_max = c(3, Inf, Inf),
    sex = c("F", "F", "M"),
    can_breed = c(FALSE, TRUE, FALSE)
  )

  expect_error(validate_breeding_table(tbl), NA)
})

test_that("validate_breeding_table detects overlapping ranges", {
  tbl_bad <- data.frame(
    age_min = c(0, 2),
    age_max = c(5, 6),
    sex = c("F", "F"),
    can_breed = c(TRUE, TRUE)
  )

  expect_error(validate_breeding_table(tbl_bad))
})

test_that("validate_breeding_table coerces numeric can_breed", {
  tbl_num <- data.frame(
    age_min = 0,
    age_max = 10,
    sex = "F",
    can_breed = 1
  )

  tbl_valid <- validate_breeding_table(tbl_num)
  expect_true(is.logical(tbl_valid$can_breed))
  expect_true(tbl_valid$can_breed[1])
})

test_that("validate_fecundity_table accepts a basic valid table", {
  tbl <- data.frame(
    age_min = c(0, 4),
    age_max = c(3, Inf),
    sex = c("F", "F"),
    lambda = c(1, 0.5)
  )

  expect_error(validate_fecundity_table(tbl), NA)
})

test_that("validate_fecundity_table rejects negative lambda", {
  tbl_bad <- data.frame(
    age_min = c(0, 2),
    age_max = c(1, 3),
    sex = c("F", "F"),
    lambda = c(1, -1)
  )

  expect_error(validate_fecundity_table(tbl_bad))
})

test_that("make_default_breeding_table reproduces default_breeding_fun", {
  tbl_def <- make_default_breeding_table()

  expect_true(all(c("age_min", "age_max", "sex", "can_breed") %in% names(tbl_def)))
  expect_equal(sort(unique(tbl_def$sex)), c("F", "M"))
  expect_error(validate_breeding_table(tbl_def), NA)

  bf <- build_breeding_fun_from_table(tbl_def)

  ages <- c(0L, 3L, 4L, 7L)
  sexes <- c("F", "M")

  for (age in ages) {
    for (sex in sexes) {
      ind <- create_individual(id = 1L, sex = sex, age = age)
      expect_equal(bf(ind), default_breeding_fun(ind))
    }
  }
})

test_that("default probability/lambda tables are valid", {
  tbl_prob <- make_default_breeding_prob_table()
  expect_true(all(c("age_min", "age_max", "sex", "p_breed") %in% names(tbl_prob)))
  expect_error(validate_breeding_prob_table(tbl_prob), NA)

  tbl_lambda <- make_default_fecundity_lambda_table()
  expect_true(all(c("age_min", "age_max", "sex", "lambda") %in% names(tbl_lambda)))
  expect_error(validate_fecundity_lambda_table(tbl_lambda), NA)
})

test_that("build_fecundity_fun_from_table returns expected counts", {
  tbl <- data.frame(
    age_min = c(0, 4),
    age_max = c(3, Inf),
    sex = c("F", "F"),
    lambda = c(0, 2)
  )

  ff <- build_fecundity_fun_from_table(tbl)

  set.seed(123)
  offs_young <- replicate(10, ff(create_individual(1L, "F", age = 1L)))
  expect_true(all(offs_young == 0L))

  set.seed(123)
  offs_adult <- replicate(20, ff(create_individual(1L, "F", age = 5L)))
  expect_true(all(offs_adult >= 0L))
  expect_true(any(offs_adult > 0L))

  set.seed(123)
  offs_male <- replicate(5, ff(create_individual(1L, "M", age = 5L)))
  expect_true(all(offs_male == 0L))
})

test_that("table-built breeding and fecundity plug into reproduction", {
  tbl_b <- data.frame(
    age_min = c(0, 2),
    age_max = c(1, Inf),
    sex = c("F", "F"),
    can_breed = c(FALSE, TRUE)
  )

  tbl_f <- data.frame(
    age_min = c(0, 2),
    age_max = c(1, Inf),
    sex = c("F", "F"),
    lambda = c(1, 3)
  )

  bf <- build_breeding_fun_from_table(tbl_b)
  ff <- build_fecundity_fun_from_table(tbl_f)

  pop <- list(
    create_individual(1L, "F", age = 1L),
    create_individual(2L, "F", age = 3L),
    create_individual(3L, "M", age = 4L)
  )

  pop[[1]]$alive <- TRUE
  pop[[2]]$alive <- TRUE
  pop[[3]]$alive <- TRUE

  breeders <- determine_breeding(pop, bf)
  expect_equal(length(breeders), 1L)
  expect_equal(breeders[[1]]$id, 2L)

  set.seed(123)
  pop_after <- apply_reproduction(
    population = pop,
    breeders = breeders,
    fecundity_fun = ff,
    mating_fun = default_mating_fun,
    inherit_fun = NULL
  )

  expect_true(length(pop_after) > length(pop))
  newborns <- pop_after[(length(pop) + 1):length(pop_after)]
  expect_true(all(vapply(newborns, function(ind) ind$age, integer(1)) == 0L))
  expect_true(all(vapply(newborns, function(ind) ind$mother_id, integer(1)) == 2L))
  expect_true(all(vapply(newborns, function(ind) ind$father_id, integer(1)) == 3L))
})

test_that("validate_breeding_prob_table enforces [0, 1] probabilities", {
  tbl_ok <- data.frame(
    age_min = c(0, 4),
    age_max = c(3, Inf),
    sex = c("F", "F"),
    p_breed = c(0, 0.8)
  )
  expect_error(validate_breeding_prob_table(tbl_ok), NA)

  tbl_bad <- tbl_ok
  tbl_bad$p_breed[2] <- 1.1
  expect_error(validate_breeding_prob_table(tbl_bad), "p_breed")
})

test_that("build_breeding_prob_fun_from_table returns expected probabilities", {
  tbl <- data.frame(
    age_min = c(0, 3),
    age_max = c(2, Inf),
    sex = c("F", "F"),
    p_breed = c(0.1, 0.7)
  )
  pf <- build_breeding_prob_fun_from_table(tbl)

  expect_equal(pf(create_individual(1L, "F", age = 1L)), 0.1)
  expect_equal(pf(create_individual(2L, "F", age = 5L)), 0.7)
  expect_equal(pf(create_individual(3L, "M", age = 5L)), 0)
})

test_that("breeding adapters preserve legacy compatibility", {
  legacy_bf <- function(ind) ind$sex == "F" && ind$age >= 4
  prob_fun <- as_breeding_prob_fun(legacy_bf)

  expect_equal(prob_fun(create_individual(1L, "F", age = 3L)), 0)
  expect_equal(prob_fun(create_individual(2L, "F", age = 4L)), 1)

  elig_fun <- as_breeding_fun(function(ind) 0.25)
  expect_true(elig_fun(create_individual(3L, "F", age = 5L)))
})

test_that("validate_fecundity_lambda_table and lambda builder work", {
  tbl <- data.frame(
    age_min = c(0, 4),
    age_max = c(3, Inf),
    sex = c("F", "F"),
    lambda = c(0, 2.5)
  )
  expect_error(validate_fecundity_lambda_table(tbl), NA)

  lf <- build_fecundity_lambda_fun_from_table(tbl)
  expect_equal(lf(create_individual(1L, "F", age = 1L)), 0)
  expect_equal(lf(create_individual(2L, "F", age = 5L)), 2.5)
  expect_equal(lf(create_individual(3L, "M", age = 5L)), 0)
})

test_that("fecundity adapters preserve legacy compatibility", {
  lambda_fun <- function(ind) if (ind$sex == "F") 1.5 else 0
  legacy_f <- as_fecundity_fun(lambda_fun)

  set.seed(123)
  draws_f <- replicate(20, legacy_f(create_individual(1L, "F", age = 5L)))
  draws_m <- replicate(10, legacy_f(create_individual(2L, "M", age = 5L)))

  expect_true(all(draws_f >= 0L))
  expect_true(any(draws_f > 0L))
  expect_true(all(draws_m == 0L))

  legacy_fun <- function(ind) if (ind$age >= 4) 2 else 0
  lambda_from_legacy <- as_fecundity_lambda_fun(legacy_fun)
  expect_equal(lambda_from_legacy(create_individual(3L, "F", age = 5L)), 2)
  expect_equal(lambda_from_legacy(create_individual(4L, "F", age = 2L)), 0)
})
