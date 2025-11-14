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
  expect_equal(summary_tbl$n_harvested, 0L)
  expect_equal(summary_tbl$survival_scale, 1)
})

test_that("run_basic_simulation_replicates produces consistent summaries", {
  init_fun <- function() {
    list(
      create_individual(1L, "F", 4L),
      create_individual(2L, "F", 5L)
    )
  }
  always_survive <- function(ind) 1
  always_breed <- function(ind) TRUE
  constant_fecundity <- function(ind) 2L

  result <- run_basic_simulation_replicates(
    n_runs = 3L,
    n_years = 1L,
    init_fun = init_fun,
    survival_fun = always_survive,
    breeding_fun = always_breed,
    fecundity_fun = constant_fecundity
  )

  expect_type(result, "list")
  expect_equal(length(result$runs), 3L)
  expect_equal(nrow(result$summary), 3L)
  expect_true(all(result$summary$n_alive == 6L))
  expect_true(all(result$summary$n_births == 4L))
  expect_true(all(result$extinction$went_extinct == FALSE))
  expect_true(all(is.na(result$extinction$time_to_extinction)))
  expect_true(all(result$summary$survival_scale == 1))
  expect_true(all(result$summary$n_harvested == 0L))
})

test_that("run_basic_simulation_replicates records extinction metrics", {
  init_fun <- function() {
    list(
      create_individual(1L, "F", 2L),
      create_individual(2L, "M", 3L)
    )
  }
  never_survive <- function(ind) 0
  never_breed <- function(ind) FALSE
  zero_fecundity <- function(ind) 0L

  result <- run_basic_simulation_replicates(
    n_runs = 5L,
    n_years = 3L,
    init_fun = init_fun,
    survival_fun = never_survive,
    breeding_fun = never_breed,
    fecundity_fun = zero_fecundity
  )

  expect_equal(nrow(result$summary), 15L)
  expect_true(all(result$summary$n_alive == 0L))
  expect_true(all(result$extinction$went_extinct))
  expect_true(all(result$extinction$time_to_extinction == 1L))
  expect_true(all(result$summary$n_harvested == 0L))
  expect_true(all(result$summary$survival_scale == 1))
})

test_that("apply_harvest_quota removes only living individuals", {
  population <- lapply(1:5, function(id) create_individual(id, ifelse(id %% 2, "F", "M"), age = id))
  alive_counts <- sum(vapply(population, function(ind) isTRUE(ind$alive), logical(1)))
  result <- apply_harvest_quota(population, 2)
  expect_equal(result$n_harvested, 2L)
  expect_equal(
    sum(vapply(result$population, function(ind) isTRUE(ind$alive), logical(1))),
    alive_counts - 2L
  )

  result_zero <- apply_harvest_quota(population, 0)
  expect_equal(result_zero$n_harvested, 0L)

  result_all <- apply_harvest_quota(population, 100)
  expect_equal(result_all$n_harvested, alive_counts)
  expect_true(all(vapply(result_all$population, function(ind) !isTRUE(ind$alive), logical(1))))
})

test_that("density dependence reduces survival when above K", {
  survival_fun <- function(ind) 0.8

  set.seed(123)
  res_no_density <- run_basic_simulation(
    initial_population = initialize_population(100),
    n_years = 1,
    survival_fun = survival_fun
  )

  set.seed(123)
  res_with_density <- run_basic_simulation(
    initial_population = initialize_population(100),
    n_years = 1,
    survival_fun = survival_fun,
    K = 20
  )

  expect_equal(nrow(res_no_density$summary), 1L)
  expect_equal(nrow(res_with_density$summary), 1L)
  expect_true(res_no_density$summary$n_alive[1] >= res_with_density$summary$n_alive[1])
  expect_equal(res_no_density$summary$survival_scale[1], 1)
  expect_lt(res_with_density$summary$survival_scale[1], 1)
})

test_that("harvest quota reduces abundance after survival and reproduction", {
  survival_fun <- function(ind) 1
  breeding_fun <- function(ind) FALSE
  fecundity_fun <- function(ind) 0L

  res <- run_basic_simulation(
    initial_population = initialize_population(5),
    n_years = 1,
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun,
    harvest_quota = 2
  )

  expect_equal(res$summary$n_births[1], 0L)
  expect_equal(res$summary$n_harvested[1], 2L)
  expect_equal(res$summary$n_alive[1], 3L)
})
