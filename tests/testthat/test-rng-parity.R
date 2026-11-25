parity_scenario <- function(n_runs = 6L, seed = 99L) {
  pedigree_scenario(n_runs = n_runs, n_steps = 8L, seed = seed)
}

comparable <- function(result) {
  result[c("census", "events", "accounting", "states", "ledgers")]
}

test_that("a fixed seed reproduces a run and different seeds differ", {
  first <- run_scenario(parity_scenario(), keep = c("census", "events", "accounting", "state", "ledger"))
  second <- run_scenario(parity_scenario(), keep = c("census", "events", "accounting", "state", "ledger"))
  expect_identical(comparable(first), comparable(second))
  other <- run_scenario(parity_scenario(seed = 100L))
  expect_false(identical(first$census, other$census))
  expect_identical(first$provenance$root_seed, 99L)
  expect_identical(length(first$provenance$streams), 6L)
})

test_that("seeded runners restore the caller's RNG on success and failure", {
  set.seed(5L, kind = "Mersenne-Twister")
  before_kind <- RNGkind()
  before_seed <- .Random.seed
  invisible(run_scenario(parity_scenario(n_runs = 2L)))
  expect_identical(RNGkind(), before_kind)
  expect_identical(.Random.seed, before_seed)
  failing <- scenario_spec(
    "fails", n_runs = 1L, n_steps = 1L, seed = 1L,
    init_fun = function() adult_population(),
    processes = list(custom_process(function(state, context, params) stop("boom")))
  )
  expect_error(run_scenario(failing), "boom")
  expect_identical(.Random.seed, before_seed)
})

test_that("unseeded scenarios and ensembles consume exactly their root-seed draws", {
  scenario <- scenario_spec("unseeded", 1L, 1L, function() adult_population(), list(census_process()))
  build <- function(row) list(init_fun = scenario$init_fun, processes = scenario$processes, n_steps = 1L)
  set.seed(108L)
  expected <- replicate(4L, sample.int(.Machine$integer.max, 1L))
  after <- .Random.seed
  set.seed(108L)
  actual <- c(replicate(2L, run_scenario(scenario)$provenance$root_seed),
              replicate(2L, attr(run_pva_ensemble(data.frame(x = 1), build, 1L), "provenance")$root_seed))
  expect_identical(actual, expected)
  expect_identical(.Random.seed, after)
  expect_identical(anyDuplicated(actual), 0L)
})

test_that("serial, fork and PSOCK execution are bit-identical", {
  keep <- c("census", "events", "accounting", "state", "ledger")
  serial <- run_scenario(parity_scenario(), keep = keep)

  if (.Platform$OS.type != "windows") {
    forked <- run_scenario(
      parity_scenario(), parallel = TRUE, workers = 2L, backend = "fork", keep = keep
    )
    expect_identical(comparable(forked), comparable(serial))
  }
  socket <- run_scenario(parity_scenario(), parallel = TRUE, backend = "psock", keep = keep)
  expect_identical(comparable(socket), comparable(serial))
})

test_that("fresh installed-package PSOCK workers receive library paths and callback globals", {
  cluster <- parallel::makePSOCKcluster(2L, rscript_args = "--vanilla")
  on.exit(parallel::stopCluster(cluster), add = TRUE)
  clean <- parallel::clusterEvalQ(cluster, {
    vars <- c("R_LIBS", "R_LIBS_USER", "R_LIBS_SITE")
    Sys.unsetenv(vars)
    .libPaths(.Library, include.site = FALSE)
    all(is.na(Sys.getenv(vars, unset = NA_character_))) && !("OpenPVA" %in% loadedNamespaces())
  })
  expect_true(all(unlist(clean)))
  assign(".openpva_socket_rates", c(0.5, 0.85), envir = .GlobalEnv)
  assign(".openpva_socket_rate", evalq(function() .openpva_socket_rates[2L], .GlobalEnv),
         envir = .GlobalEnv)
  on.exit(rm(".openpva_socket_rate", ".openpva_socket_rates", envir = .GlobalEnv), add = TRUE)
  scenario <- scenario_spec(
    "socket", 4L, 3L, init_fun = function() pva_population(rep(c("F", "M"), 10L), 2L),
    processes = list(survival_process(function(...) .openpva_socket_rate()), census_process()), seed = 7L
  )
  serial <- run_scenario(scenario)
  expect_identical(comparable(run_scenario(scenario, parallel = TRUE, cluster = cluster)), comparable(serial))
  paths <- parallel::clusterEvalQ(cluster, getNamespaceInfo(asNamespace("OpenPVA"), "path"))
  expect_identical(unlist(paths), rep(getNamespaceInfo(asNamespace("OpenPVA"), "path"), 2L))

  assign(".openpva_socket_summary", evalq(function(x) mean(x) * .openpva_socket_rate(), .GlobalEnv),
         envir = .GlobalEnv)
  on.exit(rm(".openpva_socket_summary", envir = .GlobalEnv), add = TRUE)
  build <- function(row) {
    list(n_steps = 2L, init_fun = function() pva_population(c("F", "M"), 2L),
         processes = list(census_process()))
  }
  summarise <- function(result, row) data.frame(rate = .openpva_socket_summary(result$census$n_alive))
  design <- data.frame(x = 1:2)
  expect_identical(
    run_pva_ensemble(design, build, 2L, summarise, seed = 5L, cluster = cluster),
    run_pva_ensemble(design, build, 2L, summarise, seed = 5L)
  )
})

test_that("fast validation gives bit-identical output to strict validation", {
  keep <- c("census", "events", "accounting", "state", "ledger")
  strict <- run_scenario(parity_scenario(), validation = "strict", keep = keep)
  fast <- run_scenario(parity_scenario(), validation = "fast", keep = keep)
  expect_identical(comparable(fast), comparable(strict))
  expect_identical(fast$provenance$validation, "fast")

  # Retaining less output does not change what is retained.
  lean <- run_scenario(parity_scenario(), validation = "fast", keep = "census")
  expect_identical(lean$census, strict$census)
  expect_null(lean$events)
  expect_null(lean$states)
})

test_that("scenario inputs are validated", {
  ok <- list(survival_process(0.9))
  init <- function() adult_population()
  expect_error(scenario_spec("s", 0, 1, init, ok), "n_runs")
  expect_error(scenario_spec("s", 1, 1, function(x) x, ok), "no arguments")
  expect_error(scenario_spec("s", 1, 1, init, ok, seed = -1), "seed")
  expect_error(scenario_spec("s", 1, 1, init, ok, dt = 0), "dt")
  expect_error(
    scenario_spec("s", 1, 1, init, ok, initial_census = survival_process(0.5)),
    "non-mutating"
  )
  scenario <- scenario_spec("s", 2, 3, init, ok, seed = 1)
  expect_output(print(scenario), "runs: 2")
  expect_error(run_scenario(scenario, keep = "everything"), "keep must be")
  expect_error(run_scenario(list()), "scenario_spec")
  expect_output(print(run_scenario(scenario)), "root seed: 1")
  expect_null(run_scenario(scenario)$states)
})
