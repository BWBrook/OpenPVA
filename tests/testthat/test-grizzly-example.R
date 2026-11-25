test_that("maternal care delays the next litter until surviving cubs reach independence", {
  model <- new.env()
  sys.source(system.file("examples", "grizzly", "model.R", package = "OpenPVA"), model)
  init <- function() pva_state(pva_population(c("F", "M"), 6L, mate_id = NA_integer_),
                               pedigree = TRUE)
  parameters <- model$grizzly_parameters()
  parameters$dependent_survival <- parameters$independent_survival <- 1
  parameters$breeding_probability <- parameters$litter_mean <- 1
  scenario <- model$grizzly_scenario(parameters, n_runs = 1L, n_steps = 4L, init_fun = init)
  run <- run_scenario(scenario, keep = c("census", "events", "ledger"))
  expect_equal(run$events$value[run$events$event_type == "birth"], c(1, 0, 0, 1))
  expect_equal(run$census$n_dependent[run$census$phase == "interval"], c(1, 1, 1, 1))
  ledger <- run$ledgers[[1L]]
  expect_identical(ledger$mother_id[ledger$origin == "birth"], c(1L, 1L))

  parameters$dependent_survival <- 0
  replacement <- run_scenario(model$grizzly_scenario(parameters, 1L, 4L, init_fun = init))
  expect_equal(replacement$events$value[replacement$events$event_type == "birth"], rep(1, 4L))
})

test_that("autumn harvest preserves a dead sire's kinship and exposes maternal loss", {
  model <- new.env()
  sys.source(system.file("examples", "grizzly", "model.R", package = "OpenPVA"), model)
  parents <- function() pva_state(
    pva_population(c("F", "M"), 6L, mate_id = NA_integer_), pedigree = TRUE,
    kinship = matrix(c(0.5, 0.25, 0.25, 0.5), 2L)
  )
  parameters <- model$grizzly_parameters(adult_male_mortality = 1)
  parameters$dependent_survival <- parameters$independent_survival <- 1
  parameters$breeding_probability <- parameters$litter_mean <- 1
  scenario <- model$grizzly_scenario(parameters, 1L, 1L, init_fun = parents)
  for (mode in c("strict", "fast")) {
    run <- run_scenario(scenario, validation = mode, keep = c("state", "ledger"))
    living <- run$states[[1L]]$population
    born <- living$origin == "birth"
    expect_identical(living$id, c(1L, 3L))
    expect_identical(living$father_id[born], 2L)
    expect_equal(living$pedigree_F[born], 0.25, tolerance = 1e-14)
    expect_equal(kinship_matrix(run$states[[1L]])[1L, 2L], 0.375, tolerance = 1e-14)
    expect_identical(run$ledgers[[1L]]$exit_process[[2L]], "autumn_harvest")
  }

  parameters$adult_male_mortality <- 0
  parameters$adult_female_mortality <- 1
  run <- run_scenario(model$grizzly_scenario(parameters, 1L, 1L))
  expect_equal(run$events$value[run$events$label %in% "harvest"], 6)
  expect_equal(run$events$value[run$events$label %in% "loss_of_mother"], 2)
  expect_equal(run$census$n_alive[run$census$phase == "interval"], 4)
})
