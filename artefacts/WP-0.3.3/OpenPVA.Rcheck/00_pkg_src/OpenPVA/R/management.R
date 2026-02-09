#' Compare multiple scenarios on key management metrics
#'
#' Runs each scenario, summarises extinction risk and harvest yield, and
#' collates the results into a single tibble for decision support.
#'
#' @param scenarios Named list of objects created by `scenario_spec()` or its
#'   helpers.
#' @param extinction_threshold Threshold passed to `summarise_extinction()` to
#'   compute quasi-extinction probabilities.
#'
#' @return A tibble with one row per scenario containing the selected metrics.
#' @export
compare_scenarios <- function(scenarios, extinction_threshold = 0) {
  if (!is.list(scenarios) || !length(scenarios)) {
    stop("scenarios must be a non-empty list", call. = FALSE)
  }
  scenario_names <- names(scenarios)
  if (is.null(scenario_names) || any(!nzchar(scenario_names))) {
    stop("scenarios list must have non-empty names", call. = FALSE)
  }
  purrr::imap_dfr(scenarios, function(sc, name) {
    if (!inherits(sc, "openpva_scenario")) {
      stop("All elements of `scenarios` must inherit from 'openpva_scenario'", call. = FALSE)
    }
    out <- run_scenario(sc)
    sim_output <- out$sim_output
    ext_summary <- summarise_extinction(sim_output, threshold = extinction_threshold)
    harvest_summary <- summarise_harvest_yield(sim_output)
    tibble::tibble(
      scenario_name = name,
      extinction_threshold = extinction_threshold,
      p_extinction = ext_summary$p_extinct,
      mean_time_to_extinction = ext_summary$mean_time_to_extinction,
      mean_total_harvest = harvest_summary$overall$mean_total_harvest,
      sd_total_harvest = harvest_summary$overall$sd_total_harvest,
      mean_mean_annual_harvest = harvest_summary$overall$mean_mean_annual_harvest
    )
  })
}
