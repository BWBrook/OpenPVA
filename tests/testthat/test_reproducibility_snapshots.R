round_numeric_columns <- function(tbl, digits = 6L) {
  out <- tbl
  num_cols <- vapply(out, is.double, logical(1))
  if (any(num_cols)) {
    out[num_cols] <- lapply(out[num_cols], round, digits = digits)
  }
  out
}

test_that("seeded replicate output snapshots remain stable", {
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

  out_repeat <- run_basic_simulation_replicates(
    n_runs = 3,
    n_years = 6,
    init_fun = function() initialize_population(25),
    env_surv_sd = 0.2,
    cat_surv_prob = 0.15,
    cat_surv_mult = 0.5,
    seed = 20260209L
  )

  expect_equal(
    summary_slice,
    out_repeat$summary |>
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
  )
  expect_equal(extinction_tbl, out_repeat$extinction |> dplyr::arrange(.data$run))
})

test_that("canonical YAML parser remains deterministic under seed", {
  yaml_text <- "
name: 'snapshot_yaml'
schema_version: 3
n_runs: 2
n_years: 3
seed: 606
initializer:
  fun: 'initialize_population'
  args:
    'n': 12
reproduction_ev:
  env_repro_p_sd: 0.1
  env_repro_lambda_sd: 0.1
  cat_repro_prob: 0.25
  cat_repro_mult: 0.7
"
  tmp <- tempfile(fileext = '.yaml')
  writeLines(yaml_text, tmp)
  on.exit(unlink(tmp), add = TRUE)

  sc_a <- read_scenario_yaml(tmp)
  sc_b <- read_scenario_yaml(tmp)
  out_a <- run_scenario(sc_a)
  out_b <- run_scenario(sc_b)

  expect_identical(out_a$sim_output$summary, out_b$sim_output$summary)
})

test_that("seeded spatial-genetic output snapshots remain stable", {
  out <- run_basic_simulation_replicates(
    n_runs = 3,
    n_years = 4,
    init_fun = function() {
      pop <- initialize_population(16)
      pop <- initialize_patches(pop, patch_ids = rep(c(1L, 2L), each = 8))
      initialize_genotypes(pop, n_loci = 4, n_alleles = 2L)
    },
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 0,
    fecundity_lambda_fun = function(ind) 0,
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

  out_repeat <- run_basic_simulation_replicates(
    n_runs = 3,
    n_years = 4,
    init_fun = function() {
      pop <- initialize_population(16)
      pop <- initialize_patches(pop, patch_ids = rep(c(1L, 2L), each = 8))
      initialize_genotypes(pop, n_loci = 4, n_alleles = 2L)
    },
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 0,
    fecundity_lambda_fun = function(ind) 0,
    lifecycle_steps = c("age", "survival", "dispersal"),
    dispersal_fun = make_markov_dispersal_fun(
      matrix(c(0.85, 0.15, 0.2, 0.8), nrow = 2, byrow = TRUE)
    ),
    record_population_history = TRUE,
    seed = 20260209L
  )

  expect_equal(
    occ_slice,
    summarise_patch_occupancy_timeseries(out_repeat, n_patches = 2)$overall |>
      dplyr::filter(.data$year <= 3) |>
      dplyr::arrange(.data$year, .data$patch_id) |>
      round_numeric_columns(digits = 6L)
  )
  expect_equal(
    conn_slice,
    summarise_patch_connectivity_timeseries(out_repeat, n_patches = 2)$transitions_overall |>
      dplyr::arrange(.data$origin_patch, .data$destination_patch) |>
      round_numeric_columns(digits = 6L)
  )
})
