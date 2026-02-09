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

test_that("seeded spatial-genetic output snapshots remain stable", {
  testthat::local_edition(3)

  out <- run_basic_simulation_replicates(
    n_runs = 3,
    n_years = 4,
    init_fun = function() {
      pop <- initialize_population(16)
      pop <- initialize_patches(pop, patch_ids = rep(c(1L, 2L), each = 8))
      initialize_genotypes(pop, n_loci = 4, n_alleles = 2L)
    },
    survival_fun = function(ind) 1,
    breeding_fun = function(ind) FALSE,
    fecundity_fun = function(ind) 0L,
    lifecycle_steps = c("age", "survival", "dispersal"),
    dispersal_fun = make_markov_dispersal_fun(
      matrix(c(0.85, 0.15, 0.2, 0.8), nrow = 2, byrow = TRUE)
    ),
    record_population_history = TRUE,
    seed = 20260209L
  )

  occ_slice <- summarise_patch_occupancy_timeseries(out, n_patches = 2)$overall |>
    dplyr::filter(.data$year <= 3) |>
    dplyr::arrange(.data$year, .data$patch_id) |>
    round_numeric_columns(digits = 6L)

  conn_slice <- summarise_patch_connectivity_timeseries(out, n_patches = 2)$transitions_overall |>
    dplyr::arrange(.data$origin_patch, .data$destination_patch) |>
    round_numeric_columns(digits = 6L)

  expect_snapshot_value(
    list(
      occupancy_overall = occ_slice,
      transitions_overall = conn_slice
    ),
    style = "json2"
  )
})
