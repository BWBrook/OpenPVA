test_that("the woodhen example composes through exported functions and reconciles", {
  example_dir <- system.file("examples", "woodhen", package = "OpenPVA")
  skip_if(!nzchar(example_dir), "example directory is not installed")
  model <- new.env()
  for (file in c("parameters.R", "model.R", "analyse.R")) {
    sys.source(file.path(example_dir, file), envir = model)
  }
  parameters <- model$woodhen_parameters()
  expect_silent(model$woodhen_validate_parameters(parameters))
  results <- model$woodhen_run_all(n_runs = 4L, parameters = parameters, workers = 1L, pedigree = TRUE)
  expect_identical(names(results), parameters$scenarios$scenario_id)
  bundle <- model$woodhen_prepare_bundle(results, parameters)
  expect_true(all(bundle$accounting$reconciled))
  expect_identical(nrow(bundle$scenario_summary), 3L)
  captive <- bundle$accounting[bundle$accounting$scenario_id == "pig_control_captive", ]
  totals <- aggregate(cbind(introductions, removals) ~ run, data = captive, FUN = sum)
  expect_identical(unique(totals$introductions), 78L)
  expect_identical(unique(totals$removals), 8L)
  expect_true(all(bundle$pedigree$mean_inbreeding >= 0, na.rm = TRUE))
  none <- bundle$scenario_summary[bundle$scenario_summary$scenario_id == "no_intervention", ]
  pig <- bundle$scenario_summary[bundle$scenario_summary$scenario_id == "pig_control", ]
  expect_gt(pig$final_mean, none$final_mean)

  output_dir <- tempfile("woodhen")
  model$woodhen_write_bundle(bundle, output_dir)
  expect_true(all(file.exists(file.path(
    output_dir, c("scenario_summary.csv", "accounting.csv", "pedigree.csv", "result.rds")
  ))))
})

test_that("woodhen survival uses both sexes' rates even when table rows are reordered", {
  model <- new.env()
  directory <- system.file("examples", "woodhen", package = "OpenPVA")
  for (file in c("parameters.R", "model.R")) sys.source(file.path(directory, file), model)
  parameters <- model$woodhen_parameters()
  rates <- parameters$vital_rates
  rates$p_surv <- as.numeric(rates$sex == "F")
  parameters$vital_rates <- rates[rev(seq_len(nrow(rates))), ]
  parameters$annual_environment$survival_sd <- 0
  parameters$annual_environment$cyclone_probability <- 0
  scenario <- as.list(parameters$scenarios[1L, ])
  initial <- model$woodhen_initial_state(parameters, scenario)
  survived <- execute_processes(initial, list(
    model$woodhen_conditions_process(parameters, scenario),
    model$woodhen_survival_process(parameters)
  ))$state$population
  expect_identical(survived$id, initial$population$id[initial$population$sex == "F"])
})
