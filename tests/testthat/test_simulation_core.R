test_that("apply_reproduction adds sequential newborns", {
  population <- list(
    create_individual(1L, "F", 5L),
    create_individual(2L, "M", 6L),
    create_individual(3L, "F", 3L)
  )
  breeders <- population[c(1, 3)]
  fecundity_fun <- function(ind) 2L
  original_n <- length(population)
  original_max_id <- max(vapply(population, function(ind) ind$id, integer(1)))

  updated <- apply_reproduction(population, breeders, fecundity_fun)
  expect_length(updated, original_n + length(breeders) * 2L)

  newborns <- updated[(original_n + 1L):length(updated)]
  expect_true(all(vapply(newborns, function(ind) ind$age == 0L, logical(1))))
  expect_true(all(vapply(newborns, function(ind) ind$id > original_max_id, logical(1))))
  expect_equal(
    length(unique(vapply(newborns, function(ind) ind$id, integer(1)))),
    length(newborns)
  )
})

test_that("run_basic_simulation tracks births and survivors", {
  initial_population <- list(
    create_individual(1L, "F", 3L),
    create_individual(2L, "F", 5L),
    create_individual(3L, "M", 4L)
  )

  always_survive <- function(ind) 1
  constant_fecundity <- function(ind) 2L
  breeder_fun <- function(ind) ind$sex == "F" && ind$age >= 4L

  result <- run_basic_simulation(
    initial_population = initial_population,
    n_years = 1L,
    survival_fun = always_survive,
    breeding_fun = breeder_fun,
    fecundity_fun = constant_fecundity
  )

  expect_type(result, "list")
  expect_true("population" %in% names(result))
  expect_true("summary" %in% names(result))

  summary_tbl <- result$summary
  expect_s3_class(summary_tbl, "tbl_df")
  expect_equal(nrow(summary_tbl), 1L)
  expect_equal(summary_tbl$year, 1L)

  expect_equal(summary_tbl$n_births, 4L)
  expect_equal(summary_tbl$n_alive, length(result$population))
  expect_equal(summary_tbl$n_alive, 7L)
  expect_equal(
    summary_tbl$n_alive,
    summary_tbl$n_female_alive + summary_tbl$n_male_alive
  )
})
