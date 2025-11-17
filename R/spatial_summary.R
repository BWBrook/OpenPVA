#' Summarise final-time patch occupancy across replicates
#'
#' Computes per-patch occupancy metrics at the final simulation time using the
#' outputs from `run_basic_simulation_replicates()` or `run_scenario()`.
#'
#' @param sim_output List returned by `run_basic_simulation_replicates()` (or
#'   `run_scenario()`), containing a `runs` element with per-run outputs.
#' @param n_patches Positive integer giving the number of patches. Patches are
#'   assumed to be indexed from 1 to `n_patches`; patches with zero individuals
#'   are still represented in the summary.
#' @param alive_only Logical; if `TRUE`, only living individuals contribute to
#'   patch counts. If `FALSE`, all individuals (alive or dead) are counted.
#'
#' @return A tibble with columns `patch_id`, `n_runs`, `mean_n_alive`,
#'   `p_occupied`, `n_extinct`, and `alive_only`.
#' @export
summarise_patch_occupancy_final <- function(sim_output, n_patches, alive_only = TRUE) {
  if (is.null(sim_output$runs) || !length(sim_output$runs)) {
    stop("sim_output must contain a non-empty 'runs' element", call. = FALSE)
  }
  if (!is.numeric(n_patches) || length(n_patches) != 1L || n_patches <= 0) {
    stop("n_patches must be a positive integer", call. = FALSE)
  }
  n_patches <- as.integer(n_patches)
  if (!is.logical(alive_only) || length(alive_only) != 1L || is.na(alive_only)) {
    stop("alive_only must be a single logical value", call. = FALSE)
  }

  run_counts <- purrr::map2_dfr(
    sim_output$runs,
    seq_along(sim_output$runs),
    function(run_output, run_id) {
      pop <- run_output$population
      counts <- integer(n_patches)
      if (length(pop)) {
        for (ind in pop) {
          if (alive_only && !isTRUE(ind$alive)) {
            next
          }
          pid <- ind$patch_id
          if (is.null(pid) || is.na(pid)) {
            next
          }
          pid <- as.integer(pid)
          if (pid >= 1L && pid <= n_patches) {
            counts[pid] <- counts[pid] + 1L
          }
        }
      }
      tibble::tibble(
        run = as.integer(run_id),
        patch_id = seq_len(n_patches),
        n_alive = counts
      )
    }
  )

  summary <- run_counts |>
    dplyr::group_by(.data$patch_id) |>
    dplyr::summarise(
      n_runs = dplyr::n(),
      mean_n_alive = mean(.data$n_alive),
      p_occupied = mean(.data$n_alive > 0),
      n_extinct = sum(.data$n_alive == 0),
      .groups = "drop"
    )
  summary$alive_only <- alive_only
  summary
}
