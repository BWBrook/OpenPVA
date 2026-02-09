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

#' Summarise final-time patch genetic diversity across replicates
#'
#' Computes per-patch diversity summaries at the final simulation time using
#' genotype data in the `population` element of each run.
#'
#' @param sim_output List returned by `run_basic_simulation_replicates()` (or
#'   `run_scenario()`), containing a `runs` element with per-run outputs.
#' @param n_patches Positive integer giving the number of patches. Patches are
#'   assumed to be indexed from 1 to `n_patches`.
#' @param alive_only Logical; if `TRUE`, include only living individuals.
#'
#' @return A tibble with columns `patch_id`, `n_runs`, `mean_n_genotyped`,
#'   `p_patch_genotyped`, `mean_heterozygosity`, `mean_Fhat`, and `alive_only`.
#' @export
summarise_patch_genetic_diversity_final <- function(sim_output, n_patches, alive_only = TRUE) {
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

  per_run_patch <- purrr::map2_dfr(
    sim_output$runs,
    seq_along(sim_output$runs),
    function(run_output, run_id) {
      pop <- run_output$population
      purrr::map_dfr(seq_len(n_patches), function(pid) {
        patch_inds <- Filter(function(ind) {
          if (alive_only && !isTRUE(ind$alive)) {
            return(FALSE)
          }
          !is.null(ind$patch_id) &&
            !is.na(ind$patch_id) &&
            as.integer(ind$patch_id) == pid &&
            !is.null(ind$alleles) &&
            is.matrix(ind$alleles)
        }, pop)

        if (!length(patch_inds)) {
          return(tibble::tibble(
            run = as.integer(run_id),
            patch_id = as.integer(pid),
            n_genotyped = 0L,
            mean_heterozygosity = NA_real_,
            mean_Fhat = NA_real_
          ))
        }

        heterozygosity <- vapply(
          patch_inds,
          function(ind) .heterozygosity_from_alleles(ind$alleles),
          numeric(1)
        )
        mean_H <- mean(heterozygosity, na.rm = TRUE)
        mean_F <- mean(1 - heterozygosity, na.rm = TRUE)
        if (is.nan(mean_H)) mean_H <- NA_real_
        if (is.nan(mean_F)) mean_F <- NA_real_

        tibble::tibble(
          run = as.integer(run_id),
          patch_id = as.integer(pid),
          n_genotyped = as.integer(length(patch_inds)),
          mean_heterozygosity = mean_H,
          mean_Fhat = mean_F
        )
      })
    }
  )

  summary <- per_run_patch |>
    dplyr::group_by(.data$patch_id) |>
    dplyr::summarise(
      n_runs = dplyr::n(),
      mean_n_genotyped = mean(.data$n_genotyped),
      p_patch_genotyped = mean(.data$n_genotyped > 0),
      mean_heterozygosity = mean(.data$mean_heterozygosity, na.rm = TRUE),
      mean_Fhat = mean(.data$mean_Fhat, na.rm = TRUE),
      .groups = "drop"
    )

  summary$mean_heterozygosity[is.nan(summary$mean_heterozygosity)] <- NA_real_
  summary$mean_Fhat[is.nan(summary$mean_Fhat)] <- NA_real_
  summary$alive_only <- alive_only
  summary
}
