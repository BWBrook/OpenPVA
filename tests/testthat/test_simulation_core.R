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

  result <- run_basic_simulation(
    initial_population = initial_population,
    n_years = 1L,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 2,
    lifecycle_steps = c("age", "survival", "breeding_births")
  )

  summary_tbl <- result$summary
  expect_s3_class(summary_tbl, "tbl_df")
  expect_equal(nrow(summary_tbl), 1L)
  expect_equal(summary_tbl$year, 1L)
  expect_true(summary_tbl$n_births >= 0L)
  expect_true(summary_tbl$n_births <= 6L)
  expect_equal(summary_tbl$n_alive, length(result$population))
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
      create_individual(2L, "F", 5L),
      create_individual(3L, "M", 4L)
    )
  }

  result <- run_basic_simulation_replicates(
    n_runs = 3L,
    n_years = 1L,
    init_fun = init_fun,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 2,
    lifecycle_steps = c("age", "survival", "breeding_births")
  )

  expect_equal(length(result$runs), 3L)
  expect_equal(nrow(result$summary), 3L)
  expect_true(all(result$summary$n_alive == 5L))
  expect_true(all(result$summary$n_births == 2L))
  expect_true(all(result$extinction$went_extinct == FALSE))
  expect_true(all(is.na(result$extinction$time_to_extinction)))
})

test_that("run_basic_simulation_replicates records extinction metrics", {
  init_fun <- function() {
    list(
      create_individual(1L, "F", 2L),
      create_individual(2L, "M", 3L)
    )
  }

  result <- run_basic_simulation_replicates(
    n_runs = 5L,
    n_years = 3L,
    init_fun = init_fun,
    survival_fun = function(ind) 0,
    breeding_prob_fun = function(ind) 0,
    fecundity_lambda_fun = function(ind) 0,
    lifecycle_steps = c("age", "survival", "breeding_births")
  )

  expect_equal(nrow(result$summary), 15L)
  expect_true(all(result$summary$n_alive == 0L))
  expect_true(all(result$extinction$went_extinct))
  expect_true(all(result$extinction$time_to_extinction == 1L))
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
})

test_that("density dependence reduces survival when above carrying capacity", {
  spec <- density_spec(
    survival_fun = make_ceiling_density_fun(K = 20)
  )

  set.seed(123)
  res_no_density <- run_basic_simulation(
    initial_population = initialize_population(100),
    n_years = 1,
    survival_fun = function(ind) 0.8,
    breeding_prob_fun = function(ind) 0,
    fecundity_lambda_fun = function(ind) 0,
    lifecycle_steps = c("age", "survival")
  )

  set.seed(123)
  res_with_density <- run_basic_simulation(
    initial_population = initialize_population(100),
    n_years = 1,
    survival_fun = function(ind) 0.8,
    breeding_prob_fun = function(ind) 0,
    fecundity_lambda_fun = function(ind) 0,
    lifecycle_steps = c("age", "survival"),
    density_spec = spec
  )

  expect_true(res_no_density$summary$n_alive[1] >= res_with_density$summary$n_alive[1])
  expect_equal(res_no_density$summary$survival_scale[1], 1)
  expect_equal(res_with_density$summary$survival_scale[1], 1)
})

test_that("harvest quota reduces abundance after survival and reproduction", {
  res <- run_basic_simulation(
    initial_population = initialize_population(5),
    n_years = 1,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 0,
    fecundity_lambda_fun = function(ind) 0,
    lifecycle_steps = default_lifecycle_steps(),
    harvest_quota = 2
  )

  expect_equal(res$summary$n_births[1], 0L)
  expect_equal(res$summary$n_harvested[1], 2L)
  expect_equal(res$summary$n_alive[1], 3L)
})

test_that("default_lifecycle_steps returns expected labels", {
  expect_identical(default_lifecycle_steps(), c("age", "survival", "breeding_births", "harvest"))
})

test_that("invalid lifecycle steps trigger errors", {
  expect_error(
    run_basic_simulation(
      initial_population = list(),
      n_years = 0,
      lifecycle_steps = c("age", "foo")
    ),
    "foo"
  )
})

test_that("reordering harvest and births changes outcomes", {
  make_population <- function() {
    list(
      create_individual(1L, "F", 3L),
      create_individual(2L, "F", 3L),
      create_individual(3L, "F", 3L),
      create_individual(4L, "F", 3L),
      create_individual(5L, "M", 3L)
    )
  }

  set.seed(123)
  res_default <- run_basic_simulation(
    initial_population = make_population(),
    n_years = 1,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 1,
    harvest_quota = 2,
    lifecycle_steps = c("age", "survival", "breeding_births", "harvest")
  )

  set.seed(123)
  res_harvest_first <- run_basic_simulation(
    initial_population = make_population(),
    n_years = 1,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 1,
    harvest_quota = 2,
    lifecycle_steps = c("age", "survival", "harvest", "breeding_births")
  )

  expect_true(res_default$summary$n_births[1] >= res_harvest_first$summary$n_births[1])
  expect_true(res_default$summary$n_alive[1] >= res_harvest_first$summary$n_alive[1])
})

test_that("replicates accept custom lifecycle steps", {
  init_fun <- function() {
    list(
      create_individual(1L, "F", 4L),
      create_individual(2L, "F", 5L),
      create_individual(3L, "M", 5L)
    )
  }

  res <- run_basic_simulation_replicates(
    n_runs = 2,
    n_years = 1,
    init_fun = init_fun,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 1,
    harvest_quota = 5,
    lifecycle_steps = c("age", "survival", "breeding_births")
  )

  expect_equal(nrow(res$summary), 2L)
  expect_true(all(res$summary$n_harvested == 0L))
})

test_that("apply_reproduction records parent ids when mates exist", {
  population <- list(
    create_individual(1L, "F", 5L),
    create_individual(2L, "M", 4L),
    create_individual(3L, "M", 6L)
  )
  breeders <- list(population[[1]])
  result <- apply_reproduction(population, breeders, function(ind) 1L)
  newborns <- result[(length(population) + 1L):length(result)]
  male_ids <- c(2L, 3L)

  expect_equal(length(newborns), 1L)
  expect_equal(newborns[[1]]$mother_id, 1L)
  expect_true(newborns[[1]]$father_id %in% male_ids)
})

test_that("apply_reproduction leaves father ids NA when no males", {
  population <- list(
    create_individual(1L, "F", 5L),
    create_individual(2L, "F", 4L)
  )
  breeders <- population
  result <- apply_reproduction(population, breeders, function(ind) 1L)
  newborns <- result[(length(population) + 1L):length(result)]

  expect_equal(length(newborns), length(breeders))
  expect_true(all(vapply(newborns, function(ind) ind$mother_id %in% c(1L, 2L), logical(1))))
  expect_true(all(vapply(newborns, function(ind) is.na(ind$father_id), logical(1))))
})

test_that("apply_reproduction can require mates before producing offspring", {
  population <- list(
    create_individual(1L, "F", 5L),
    create_individual(2L, "F", 4L)
  )

  result <- apply_reproduction(
    population = population,
    breeders = population,
    fecundity_fun = function(ind) 1L,
    require_mate = TRUE
  )

  expect_equal(length(result), length(population))
})

test_that("mate-limited mating function reduces births when mates are required", {
  initial_population <- list(
    create_individual(1L, "F", 5L),
    create_individual(2L, "F", 5L),
    create_individual(3L, "M", 5L)
  )

  set.seed(321)
  res_required <- run_basic_simulation(
    initial_population = initial_population,
    n_years = 1L,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 1,
    mating_fun = make_mate_limited_mating_fun(max_mates_per_male = 1L),
    require_mate = TRUE,
    lifecycle_steps = c("age", "survival", "breeding_births")
  )

  set.seed(321)
  res_not_required <- run_basic_simulation(
    initial_population = initial_population,
    n_years = 1L,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 1,
    mating_fun = make_mate_limited_mating_fun(max_mates_per_male = 1L),
    require_mate = FALSE,
    lifecycle_steps = c("age", "survival", "breeding_births")
  )

  expect_true(res_required$summary$n_births[1] <= res_not_required$summary$n_births[1])
})

test_that("make_mate_limited_mating_fun validates quota input", {
  expect_error(
    make_mate_limited_mating_fun(max_mates_per_male = 0),
    "max_mates_per_male"
  )
})

test_that("run_basic_simulation can record per-year population history", {
  res <- run_basic_simulation(
    initial_population = initialize_population(6),
    n_years = 3,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 0,
    fecundity_lambda_fun = function(ind) 0,
    lifecycle_steps = c("age", "survival"),
    record_population_history = TRUE
  )

  expect_true("population_history" %in% names(res))
  expect_equal(length(res$population_history), 3L)
  expect_true(all(vapply(res$population_history, is.list, logical(1))))
})

test_that("replicates propagate record_population_history", {
  res <- run_basic_simulation_replicates(
    n_runs = 2,
    n_years = 2,
    init_fun = function() initialize_population(6),
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 0,
    fecundity_lambda_fun = function(ind) 0,
    lifecycle_steps = c("age", "survival"),
    record_population_history = TRUE
  )

  expect_equal(length(res$runs), 2L)
  expect_true(all(vapply(res$runs, function(run) "population_history" %in% names(run), logical(1))))
  expect_true(all(vapply(res$runs, function(run) length(run$population_history), integer(1)) == 2L))
})
