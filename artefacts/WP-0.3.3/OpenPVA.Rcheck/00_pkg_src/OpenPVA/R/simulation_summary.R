#' Summarise extinction outcomes across replicates
#'
#' Computes high-level extinction or quasi-extinction statistics from
#' `run_basic_simulation_replicates()` output.
#'
#' @param sim_output A list returned by `run_basic_simulation_replicates()`.
#' @param threshold Population size threshold at or below which a run is
#'   considered (quasi-)extinct. Defaults to `0`, which matches the previous
#'   behaviour of treating only true extinction as failure.
#'
#' @return A tibble with columns `n_runs`, `p_extinct`, `mean_time_to_extinction`,
#'   and `median_time_to_extinction`.
#' @export
summarise_extinction <- function(sim_output, threshold = 0) {
  threshold <- as.numeric(threshold)
  if (length(threshold) != 1L || is.na(threshold) || threshold < 0) {
    stop("threshold must be a single non-negative numeric value", call. = FALSE)
  }

  summary_tbl <- sim_output$summary
  can_use_summary <- !is.null(summary_tbl) && all(c("run", "year", "n_alive") %in% names(summary_tbl))
  if (can_use_summary) {
    return(.summarise_extinction_from_summary(summary_tbl, threshold))
  }

  if (threshold > 0) {
    stop("sim_output$summary with columns run, year, n_alive is required when threshold > 0", call. = FALSE)
  }

  extinction_tbl <- sim_output$extinction
  if (is.null(extinction_tbl)) {
    stop("sim_output$extinction is missing")
  }
  if (!nrow(extinction_tbl)) {
    return(tibble::tibble(
      n_runs = 0L,
      p_extinct = NA_real_,
      mean_time_to_extinction = NA_real_,
      median_time_to_extinction = NA_real_
    ))
  }
  n_runs <- nrow(extinction_tbl)
  went_extinct <- extinction_tbl$went_extinct
  if (is.null(went_extinct)) {
    stop("extinction table must contain `went_extinct`")
  }
  p_extinct <- mean(went_extinct)
  extinct_times <- extinction_tbl$time_to_extinction[went_extinct]
  if (length(extinct_times)) {
    mean_time <- mean(extinct_times)
    median_time <- stats::median(extinct_times)
  } else {
    mean_time <- NA_real_
    median_time <- NA_real_
  }
  tibble::tibble(
    n_runs = n_runs,
    p_extinct = p_extinct,
    mean_time_to_extinction = mean_time,
    median_time_to_extinction = median_time
  )
}

.summarise_extinction_from_summary <- function(summary_tbl, threshold) {
  if (!nrow(summary_tbl)) {
    return(tibble::tibble(
      n_runs = 0L,
      p_extinct = NA_real_,
      mean_time_to_extinction = NA_real_,
      median_time_to_extinction = NA_real_
    ))
  }
  runs <- sort(unique(summary_tbl$run))
  if (!length(runs)) {
    return(tibble::tibble(
      n_runs = 0L,
      p_extinct = NA_real_,
      mean_time_to_extinction = NA_real_,
      median_time_to_extinction = NA_real_
    ))
  }
  per_run <- summary_tbl |>
    dplyr::group_by(.data$run) |>
    dplyr::summarise(
      went_extinct = any(.data$n_alive <= threshold),
      time_to_extinction = {
        ext_years <- .data$year[.data$n_alive <= threshold]
        if (length(ext_years)) min(ext_years) else NA_integer_
      },
      .groups = "drop"
    )
  n_runs <- nrow(per_run)
  p_extinct <- mean(per_run$went_extinct)
  extinct_times <- per_run$time_to_extinction[per_run$went_extinct]
  if (length(extinct_times)) {
    mean_time <- mean(extinct_times)
    median_time <- stats::median(extinct_times)
  } else {
    mean_time <- NA_real_
    median_time <- NA_real_
  }
  tibble::tibble(
    n_runs = n_runs,
    p_extinct = p_extinct,
    mean_time_to_extinction = mean_time,
    median_time_to_extinction = median_time
  )
}

#' Compute mean trajectory statistics across runs
#'
#' Aggregates the combined per-run summaries from `run_basic_simulation_replicates()`.
#'
#' @param sim_output A list returned by `run_basic_simulation_replicates()`.
#'
#' @return A tibble with columns `year`, `mean_n_alive`, `sd_n_alive`, and `p_extant`.
#' @export
compute_mean_trajectory <- function(sim_output) {
  if (is.null(sim_output$summary)) {
    stop("sim_output$summary is missing")
  }
  summary_tbl <- sim_output$summary
  if (!nrow(summary_tbl)) {
    return(tibble::tibble(
      year = integer(),
      mean_n_alive = double(),
      sd_n_alive = double(),
      p_extant = double()
    ))
  }
  summary_tbl |>
    dplyr::group_by(.data$year) |>
    dplyr::summarise(
      mean_n_alive = mean(.data$n_alive),
      sd_n_alive = stats::sd(.data$n_alive),
      p_extant = mean(.data$n_alive > 0),
      .groups = "drop"
    ) |>
    tibble::as_tibble()
}

#' Summarise harvest yields across replicates
#'
#' Aggregates harvest information from the per-run/year summaries produced by
#' `run_basic_simulation_replicates()`.
#'
#' @param sim_output A list returned by `run_basic_simulation_replicates()`.
#'
#' @return A list with two tibbles: `per_run` (one row per run) and `overall`
#'   (across-run averages).
#' @export
summarise_harvest_yield <- function(sim_output) {
  summary_tbl <- sim_output$summary
  if (is.null(summary_tbl)) {
    stop("sim_output$summary is missing")
  }
  if (!all(c("run", "n_harvested") %in% names(summary_tbl))) {
    stop("sim_output$summary must contain columns `run` and `n_harvested`", call. = FALSE)
  }
  if (!nrow(summary_tbl)) {
    per_run <- tibble::tibble(
      run = integer(),
      total_harvest = double(),
      mean_annual_harvest = double()
    )
    overall <- tibble::tibble(
      mean_total_harvest = NA_real_,
      sd_total_harvest = NA_real_,
      mean_mean_annual_harvest = NA_real_,
      n_runs = 0L
    )
    return(list(per_run = per_run, overall = overall))
  }

  per_run <- summary_tbl |>
    dplyr::group_by(.data$run) |>
    dplyr::summarise(
      total_harvest = sum(.data$n_harvested, na.rm = TRUE),
      mean_annual_harvest = mean(.data$n_harvested, na.rm = TRUE),
      .groups = "drop"
    )

  overall <- per_run |>
    dplyr::summarise(
      mean_total_harvest = mean(.data$total_harvest),
      sd_total_harvest = stats::sd(.data$total_harvest),
      mean_mean_annual_harvest = mean(.data$mean_annual_harvest),
      n_runs = dplyr::n()
    )

  list(per_run = per_run, overall = overall)
}
