census_fixture <- function() {
  values <- rbind(c(5, 3, 1, 0), c(5, 4, 4, 6), c(2, 1, 3, 3), c(6, 6, 5, 4))
  data.frame(
    run = rep(1:4, each = 5L),
    time = rep(c(0L, 0:3), 4L),
    phase = rep(c("initial", rep("interval", 4L)), 4L),
    process_name = "census",
    n_alive = as.vector(t(cbind(8, values)))
  )
}

test_that("viability summaries follow their definitions", {
  summary <- summarise_pva(census_fixture(), threshold = 2)
  expect_identical(summary$n_runs, 4L)
  expect_identical(summary$horizon, 4L)
  expect_equal(summary$p_below_at_horizon, 0.25)
  expect_equal(summary$p_ever_below, 0.5)
  expect_equal(summary$p_ever_below_mcse, sqrt(0.25 / 4))
  expect_equal(summary$time_to_threshold_mean, 2.5)
  expect_equal(summary$time_to_threshold_restricted_mean, (3 + 4 + 2 + 4) / 4)
  expect_equal(summary$final_mean, 3.25)
  expect_equal(summary$final_median, 3.5)
  expect_true(summary$p_ever_below_lower < 0.5 && summary$p_ever_below_upper > 0.5)
  expect_true(summary$p_ever_below_lower > 0 && summary$p_ever_below_upper < 1)

  never <- summarise_pva(census_fixture(), threshold = 0.5)
  expect_equal(never$p_ever_below, 0.25)
  expect_true(is.na(summarise_pva(census_fixture(), threshold = -1)$time_to_threshold_mean))
  with_initial <- summarise_pva(census_fixture(), threshold = 9, include_initial = TRUE)
  expect_equal(with_initial$time_to_threshold_mean, 0)

  trajectory <- summarise_trajectory(census_fixture(), threshold = 2)
  expect_identical(trajectory$year, 0:4)
  expect_equal(trajectory$mean, c(8, 4.5, 3.5, 3.25, 3.25))
  expect_equal(trajectory$p_below, c(0, 0, 0.25, 0.25, 0.25))
  expect_equal(trajectory$p_ever_below, c(0, 0, 0.25, 0.5, 0.5))
  expect_error(summarise_pva(census_fixture(), metric = "absent"), "census column")
  expect_error(summarise_pva(census_fixture()[-3L, ]), "exactly once per interval")
})

test_that("interval accounting reconciles by cohort", {
  result <- run_scenario(pedigree_scenario(n_runs = 3L, n_steps = 6L, seed = 1L))
  accounting <- summarise_accounting(result)
  expect_identical(summarise_accounting(result$accounting), accounting)
  expect_identical(nrow(accounting), 18L)
  expect_true(all(accounting$reconciled))
  expect_identical(sum(accounting$introductions), 6L)
  census <- result$census[result$census$phase == "interval", ]
  expect_identical(accounting$n_end, as.integer(census$n_alive))
  births <- result$events[result$events$event_type == "birth", ]
  expect_identical(sum(accounting$births), as.integer(sum(births$value)))
  expect_error(summarise_accounting(run_scenario(
    pedigree_scenario(1L, 1L, 1L), keep = "census"
  )), "accounting rows")
})

test_that("initial observations agree across summaries and full runs enforce their design", {
  s <- scenario_spec(
    "recovery", 3L, 2L, function() pva_population("F", 1L),
    list(introduction_process(1L, function(...) list(sex = "M", age = 2L)), census_process()), seed = 3L
  )
  for (initial in c(FALSE, TRUE)) {
    if (initial) s$initial_census <- census_process()
    result <- run_scenario(s)
    endpoint <- summarise_pva(result, threshold = 2)
    trajectory <- summarise_trajectory(result, threshold = 2)
    expect_identical(trajectory$year, if (initial) 0:2 else 1:2)
    expect_equal(endpoint$p_ever_below, as.integer(initial))
    expect_equal(tail(trajectory$p_ever_below, 1), endpoint$p_ever_below)
  }
  missing_run <- result
  missing_run$census <- subset(missing_run$census, run != 3L)
  expect_error(summarise_pva(missing_run), "exactly once per interval and run")
  missing_step <- result
  missing_step$census <- subset(missing_step$census, time != 1L)
  expect_error(summarise_trajectory(missing_step), "exactly once per interval and run")
  duplicate <- result
  rows <- which(duplicate$census$phase == "interval")
  duplicate$census[rows[1L], ] <- duplicate$census[rows[2L], ]
  expect_error(summarise_pva(duplicate), "exactly once per interval and run")
  result$census <- subset(result$census, phase == "interval")
  expect_error(summarise_trajectory(result), "one initial census row per run")
})

test_that("the selected census has an explicit process and scheduled occurrence", {
  s <- scenario_spec(
    "before-after", 2L, 1L, function() adult_population(2L, 1L),
    list(census_process(), removal_process(1L), census_process(), census_process(name = "final")),
    seed = 3L
  )
  result <- run_scenario(s)
  expect_error(summarise_pva(result), "select one with process_name")
  expect_error(summarise_trajectory(result, process_name = "census"), "select an occurrence")
  expect_equal(summarise_pva(result, process_name = "census", occurrence = 1L)$final_mean, 3)
  expect_equal(summarise_trajectory(result, process_name = "census", occurrence = 2L)$mean, 2)
  expect_equal(summarise_trajectory(result, process_name = "final")$mean, 2)
})

ensemble_build <- function(row) {
  list(
    n_steps = 6L,
    init_fun = function() adult_population(8L, 8L),
    processes = list(
      survival_process(row$survival),
      removal_process(count = row$harvest),
      census_process()
    )
  )
}

test_that("ensembles are reproducible, worker-independent and resumable", {
  design <- expand.grid(survival = c(0.6, 0.9), harvest = c(0, 1))
  summarise <- function(result, row) summarise_pva(result, threshold = 4)
  serial <- run_pva_ensemble(design, ensemble_build, n_runs = 30L, summarise = summarise, seed = 3L)
  expect_identical(nrow(serial), 4L)
  expect_identical(serial$survival, design$survival)
  expect_identical(anyDuplicated(serial$member_seed), 0L)
  expect_gt(serial$p_ever_below[[1L]], serial$p_ever_below[[2L]])
  expect_identical(attr(serial, "provenance")$root_seed, 3L)

  again <- run_pva_ensemble(design, ensemble_build, n_runs = 30L, summarise = summarise, seed = 3L)
  expect_identical(again, serial)

  if (.Platform$OS.type != "windows") {
    forked <- run_pva_ensemble(
      design, ensemble_build, n_runs = 30L, summarise = summarise, seed = 3L,
      workers = 2L, backend = "fork"
    )
    expect_identical(forked, serial)
  }

  cache <- tempfile("ensemble-cache")
  first <- run_pva_ensemble(
    design, ensemble_build, n_runs = 30L, summarise = summarise, seed = 3L, cache_dir = cache
  )
  expect_identical(first, serial)
  expect_identical(length(list.files(cache)), 4L)
  resumed <- run_pva_ensemble(
    design, ensemble_build, n_runs = 30L, summarise = summarise, seed = 3L, cache_dir = cache
  )
  expect_identical(resumed, serial)
  poisoned <- function(row) stop("changed builder was evaluated")
  expect_error(
    run_pva_ensemble(design, poisoned, n_runs = 30L, summarise = summarise, seed = 3L, cache_dir = cache),
    "changed builder was evaluated"
  )
})

test_that("cache receipts include callbacks, their captured inputs and run revisions", {
  cache <- tempfile()
  receipt <- tempfile()
  scale <- 1
  build <- function(row) {
    cat("built\n", file = receipt, append = TRUE)
    list(n_steps = 1L, init_fun = function() adult_population(1L, 1L), processes = list(census_process()))
  }
  summary <- function(result, row) data.frame(value = scale * result$census$n_alive[1L])
  run <- function(f = summary, ...) {
    run_pva_ensemble(data.frame(x = 1), build, 1L, f, seed = 22L, cache_dir = cache, ...)
  }
  expect_equal(run()$value, 2)
  expect_equal(run()$value, 2)
  expect_length(readLines(receipt), 1L)
  scale <- 2
  expect_equal(run()$value, 4)
  expect_equal(run(function(result, row) data.frame(value = 17L))$value, 17)
  expect_equal(run(validation = "fast")$value, 4)
  expect_equal(run(validation = "fast", cache_key = "updated field data")$value, 4)
  expect_length(readLines(receipt), 5L)
  key <- readRDS(list.files(cache, full.names = TRUE))$key
  expect_identical(key$revision$package_version, as.character(packageVersion("OpenPVA")))
  expect_identical(key$revision$validation, "fast")
})

test_that("stochastic builders and summaries use a reproducible member substream", {
  build <- function(row) {
    individuals <- sample.int(100L, 1L)
    list(n_steps = 1L, init_fun = function() pva_population(rep("F", individuals), 2L),
         processes = list(census_process()))
  }
  summary <- function(result, row) data.frame(n = result$census$n_alive[1L], draw = runif(1L))
  design <- data.frame(x = 1:4)
  set.seed(101L)
  initial <- .Random.seed
  serial <- run_pva_ensemble(design, build, 2L, summary, seed = 6L)
  expect_identical(.Random.seed, initial)
  expect_identical(run_pva_ensemble(design, build, 2L, summary, seed = 6L,
                                    workers = 2L, backend = "psock"), serial)
  expect_identical(.Random.seed, initial)
  expect_gt(length(unique(serial$draw)), 1L)
  if (.Platform$OS.type != "windows") {
    expect_identical(run_pva_ensemble(design, build, 2L, summary, seed = 6L,
                                      workers = 2L, backend = "fork"), serial)
  }
  expect_error(run_pva_ensemble(design, function(row) { runif(1); stop("builder error") },
                                1L, seed = 6L), "builder error")
  expect_identical(.Random.seed, initial)
})

test_that("seed blocks give management options common random numbers", {
  design <- expand.grid(survival = c(0.6, 0.9), harvest = c(0, 1))
  paired <- run_pva_ensemble(
    design, ensemble_build, n_runs = 10L, seed = 3L, seed_by = "survival"
  )
  expect_identical(paired$member_seed[1:2], paired$member_seed[3:4])
  expect_false(identical(paired$member_seed[[1L]], paired$member_seed[[2L]]))
  expect_error(run_pva_ensemble(design, ensemble_build, 5L, seed_by = "absent"), "design columns")
  expect_error(
    run_pva_ensemble(design, function(row) list(), 5L),
    "init_fun, processes and n_steps"
  )
})
