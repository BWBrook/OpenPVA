#' Summarise extinction outcomes across replicates
#'
#' Computes high-level extinction statistics from `run_basic_simulation_replicates()` output.
#'
#' @param sim_output A list returned by `run_basic_simulation_replicates()`.
#'
#' @return A tibble with columns `n_runs`, `p_extinct`, `mean_time_to_extinction`,
#'   and `median_time_to_extinction`.
#' @export
summarise_extinction <- function(sim_output) {
  if (is.null(sim_output$extinction)) {
    stop("sim_output$extinction is missing")
  }
  extinction_tbl <- sim_output$extinction
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
