round_numeric_columns <- function(tbl, digits = 6L) {
  out <- tbl
  num_cols <- vapply(out, is.double, logical(1))
  if (any(num_cols)) {
    out[num_cols] <- lapply(out[num_cols], round, digits = digits)
  }
  out
}

test_that("seeded replicate output snapshots remain stable", {
  testthat::local_edition(3)

  out <- run_basic_simulation_replicates(
    n_runs = 3,
    n_years = 6,
    init_fun = function() initialize_population(25),
    env_surv_sd = 0.2,
    cat_surv_prob = 0.15,
    cat_surv_mult = 0.5,
    seed = 20260209L
  )

  summary_slice <- out$summary |>
    dplyr::filter(.data$run <= 2, .data$year <= 4) |>
    dplyr::select(
      "run",
      "year",
      "n_alive",
      "n_births",
      "env_surv_mult",
      "cat_surv_mult",
      "catastrophe"
    ) |>
    round_numeric_columns(digits = 6L)

  extinction_tbl <- out$extinction |>
    dplyr::arrange(.data$run)

  expect_snapshot_value(
    list(
      summary_slice = summary_slice,
      extinction = extinction_tbl
    ),
    style = "json2"
  )
})

test_that("schema migration snapshot remains stable", {
  testthat::local_edition(3)

  cfg_v1 <- list(
    schema_version = 1L,
    name = "snapshot_cfg_v1",
    n_runs = 1L,
    n_years = 2L,
    initializer = list(fun = "initialize_population", args = list(n = 10L)),
    demography = list(
      breeding = list(table = list(
        list(sex = "F", age_min = 4, age_max = 100, can_breed = TRUE),
        list(sex = "M", age_min = 0, age_max = 100, can_breed = FALSE)
      )),
      fecundity = list(table = list(
        list(sex = "F", age_min = 4, age_max = 100, lambda = 1.4),
        list(sex = "M", age_min = 0, age_max = 100, lambda = 0)
      ))
    ),
    env_repro_p_sd = 0.1,
    env_repro_lambda_sd = 0.2,
    cat_repro_prob = 0.25,
    cat_repro_mult = 0.6
  )

  cfg_v2 <- OpenPVA:::.migrate_yaml_v1_to_v2(cfg_v1)

  migrated_subset <- list(
    schema_version = cfg_v2$schema_version,
    breeding_prob_table = cfg_v2$demography$breeding_prob$table,
    fecundity_lambda_table = cfg_v2$demography$fecundity_lambda$table,
    reproduction_ev = cfg_v2$reproduction_ev
  )

  expect_snapshot_value(migrated_subset, style = "json2")
})
