test_that("packaged schema-v3 documentation example runs", {
  yaml_path <- system.file(
    "extdata",
    "demo_reproduction_v2.yaml",
    package = "OpenPVA"
  )
  if (!nzchar(yaml_path)) {
    yaml_path <- file.path("inst", "extdata", "demo_reproduction_v2.yaml")
  }

  expect_true(file.exists(yaml_path))

  scenario <- read_scenario_yaml(yaml_path)
  expect_s3_class(scenario, "openpva_scenario")
  expect_identical(attr(scenario, "yaml_schema_version"), 3L)
  expect_true(is.function(scenario$breeding_prob_fun))
  expect_true(is.function(scenario$fecundity_lambda_fun))

  result <- run_scenario(scenario)
  expect_true(is.list(result$sim_output))
  expect_true(all(c("runs", "summary", "extinction") %in% names(result$sim_output)))
  expect_gt(nrow(result$sim_output$summary), 0L)
  expect_true(all(c(
    "n_births",
    "env_repro_p_mult",
    "env_repro_lambda_mult"
  ) %in% names(result$sim_output$summary)))
})
