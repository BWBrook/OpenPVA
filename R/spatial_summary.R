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

.validate_spatial_summary_inputs <- function(sim_output, n_patches, alive_only) {
  if (is.null(sim_output$runs) || !length(sim_output$runs)) {
    stop("sim_output must contain a non-empty 'runs' element", call. = FALSE)
  }
  if (!is.numeric(n_patches) || length(n_patches) != 1L || n_patches <= 0) {
    stop("n_patches must be a positive integer", call. = FALSE)
  }
  if (!is.logical(alive_only) || length(alive_only) != 1L || is.na(alive_only)) {
    stop("alive_only must be a single logical value", call. = FALSE)
  }
  as.integer(n_patches)
}

.extract_population_histories <- function(sim_output) {
  histories <- lapply(
    sim_output$runs,
    function(run_output) {
      if (!is.null(run_output$population_history)) run_output$population_history else NULL
    }
  )
  has_history <- vapply(histories, function(h) is.list(h) && length(h) > 0L, logical(1))
  if (!all(has_history)) {
    stop(
      "All runs must include `population_history`; rerun simulations with ",
      "`record_population_history = TRUE`.",
      call. = FALSE
    )
  }
  n_years <- vapply(histories, length, integer(1))
  if (length(unique(n_years)) != 1L) {
    stop("All runs must have the same population_history length", call. = FALSE)
  }
  histories
}

.count_patch_alive <- function(pop, n_patches, alive_only) {
  counts <- integer(n_patches)
  if (!length(pop)) {
    return(counts)
  }
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
  counts
}

.id_patch_lookup <- function(pop, n_patches, alive_only) {
  lookup <- integer()
  if (!length(pop)) {
    return(lookup)
  }
  for (ind in pop) {
    if (alive_only && !isTRUE(ind$alive)) {
      next
    }
    id <- ind$id
    pid <- ind$patch_id
    if (is.null(id) || is.na(id) || is.null(pid) || is.na(pid)) {
      next
    }
    pid <- as.integer(pid)
    if (pid < 1L || pid > n_patches) {
      next
    }
    lookup[[as.character(id)]] <- pid
  }
  lookup
}

#' Summarise time-series patch occupancy across replicates
#'
#' Computes per-run/year patch occupancy from `population_history` snapshots and
#' returns both per-run and across-run summaries.
#'
#' @param sim_output List returned by `run_basic_simulation_replicates()` (or
#'   `run_scenario()`), containing `runs` with `population_history`.
#' @param n_patches Positive integer giving the number of patches.
#' @param alive_only Logical; if `TRUE`, only living individuals contribute to
#'   occupancy.
#'
#' @return A list with:
#'   - `per_run`: tibble with columns `run`, `year`, `patch_id`, `n_alive`,
#'     `occupied`, `alive_only`.
#'   - `overall`: tibble with columns `year`, `patch_id`, `n_runs`,
#'     `mean_n_alive`, `p_occupied`, `n_extinct`, `alive_only`.
summarise_patch_occupancy_timeseries <- function(sim_output, n_patches, alive_only = TRUE) {
  n_patches <- .validate_spatial_summary_inputs(sim_output, n_patches, alive_only)
  histories <- .extract_population_histories(sim_output)

  per_run <- purrr::map2_dfr(
    histories,
    seq_along(histories),
    function(history, run_id) {
      purrr::map2_dfr(
        history,
        seq_along(history),
        function(pop, year) {
          counts <- .count_patch_alive(pop, n_patches = n_patches, alive_only = alive_only)
          tibble::tibble(
            run = as.integer(run_id),
            year = as.integer(year),
            patch_id = seq_len(n_patches),
            n_alive = as.integer(counts),
            occupied = counts > 0
          )
        }
      )
    }
  )
  per_run$alive_only <- alive_only

  overall <- per_run |>
    dplyr::group_by(.data$year, .data$patch_id) |>
    dplyr::summarise(
      n_runs = dplyr::n(),
      mean_n_alive = mean(.data$n_alive),
      p_occupied = mean(.data$occupied),
      n_extinct = sum(!.data$occupied),
      .groups = "drop"
    )
  overall$alive_only <- alive_only

  list(per_run = per_run, overall = overall)
}

#' Summarise time-series patch genetic diversity across replicates
#'
#' Computes per-run/year patch-level genotype counts and diversity metrics from
#' `population_history` snapshots and returns per-run and across-run summaries.
#'
#' @param sim_output List returned by `run_basic_simulation_replicates()` (or
#'   `run_scenario()`), containing `runs` with `population_history`.
#' @param n_patches Positive integer giving the number of patches.
#' @param alive_only Logical; if `TRUE`, only living individuals are included.
#'
#' @return A list with:
#'   - `per_run`: tibble with columns `run`, `year`, `patch_id`, `n_genotyped`,
#'     `mean_heterozygosity`, `mean_Fhat`, `alive_only`.
#'   - `overall`: tibble with columns `year`, `patch_id`, `n_runs`,
#'     `mean_n_genotyped`, `p_patch_genotyped`, `mean_heterozygosity`,
#'     `mean_Fhat`, `alive_only`.
summarise_patch_genetic_diversity_timeseries <- function(sim_output, n_patches, alive_only = TRUE) {
  n_patches <- .validate_spatial_summary_inputs(sim_output, n_patches, alive_only)
  histories <- .extract_population_histories(sim_output)

  per_run <- purrr::map2_dfr(
    histories,
    seq_along(histories),
    function(history, run_id) {
      purrr::map2_dfr(
        history,
        seq_along(history),
        function(pop, year) {
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
                year = as.integer(year),
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
              year = as.integer(year),
              patch_id = as.integer(pid),
              n_genotyped = as.integer(length(patch_inds)),
              mean_heterozygosity = mean_H,
              mean_Fhat = mean_F
            )
          })
        }
      )
    }
  )
  per_run$alive_only <- alive_only

  overall <- per_run |>
    dplyr::group_by(.data$year, .data$patch_id) |>
    dplyr::summarise(
      n_runs = dplyr::n(),
      mean_n_genotyped = mean(.data$n_genotyped),
      p_patch_genotyped = mean(.data$n_genotyped > 0),
      mean_heterozygosity = mean(.data$mean_heterozygosity, na.rm = TRUE),
      mean_Fhat = mean(.data$mean_Fhat, na.rm = TRUE),
      .groups = "drop"
    )
  overall$mean_heterozygosity[is.nan(overall$mean_heterozygosity)] <- NA_real_
  overall$mean_Fhat[is.nan(overall$mean_Fhat)] <- NA_real_
  overall$alive_only <- alive_only

  list(per_run = per_run, overall = overall)
}

#' Summarise time-series dispersal/connectivity diagnostics
#'
#' Computes patch-to-patch transition counts between consecutive years from
#' `population_history` snapshots, along with net patch abundance change and
#' occupancy turnover indicators.
#'
#' @param sim_output List returned by `run_basic_simulation_replicates()` (or
#'   `run_scenario()`), containing `runs` with `population_history`.
#' @param n_patches Positive integer giving the number of patches.
#' @param alive_only Logical; if `TRUE`, transitions/counts are computed from
#'   living individuals only.
#'
#' @return A list with:
#'   - `transitions`: tibble with `run`, `year_from`, `year_to`, `origin_patch`,
#'     `destination_patch`, `n_individuals`, `alive_only`.
#'   - `transitions_overall`: tibble with `origin_patch`, `destination_patch`,
#'     `mean_n_individuals`, `total_n_individuals`, `p_transition_given_origin`,
#'     `alive_only`.
#'   - `net_patch_change`: tibble with `run`, `year`, `patch_id`, `n_alive`,
#'     `delta_n_alive`, `alive_only`.
#'   - `turnover`: tibble with `run`, `year`, `patch_id`, `colonized`,
#'     `extirpated`, `alive_only`.
summarise_patch_connectivity_timeseries <- function(sim_output, n_patches, alive_only = TRUE) {
  n_patches <- .validate_spatial_summary_inputs(sim_output, n_patches, alive_only)
  histories <- .extract_population_histories(sim_output)

  transition_grid <- expand.grid(
    origin_patch = seq_len(n_patches),
    destination_patch = seq_len(n_patches),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )

  transitions <- purrr::map2_dfr(
    histories,
    seq_along(histories),
    function(history, run_id) {
      if (length(history) < 2L) {
        return(tibble::tibble(
          run = integer(),
          year_from = integer(),
          year_to = integer(),
          origin_patch = integer(),
          destination_patch = integer(),
          n_individuals = integer()
        ))
      }

      purrr::map_dfr(2:length(history), function(year_to) {
        prev_lookup <- .id_patch_lookup(history[[year_to - 1L]], n_patches, alive_only)
        curr_lookup <- .id_patch_lookup(history[[year_to]], n_patches, alive_only)
        common_ids <- intersect(names(prev_lookup), names(curr_lookup))

        counts <- matrix(0L, nrow = n_patches, ncol = n_patches)
        if (length(common_ids)) {
          origins <- as.integer(prev_lookup[common_ids])
          destinations <- as.integer(curr_lookup[common_ids])
          for (idx in seq_along(common_ids)) {
            counts[origins[[idx]], destinations[[idx]]] <-
              counts[origins[[idx]], destinations[[idx]]] + 1L
          }
        }

        tibble::tibble(
          run = as.integer(run_id),
          year_from = as.integer(year_to - 1L),
          year_to = as.integer(year_to),
          origin_patch = as.integer(transition_grid$origin_patch),
          destination_patch = as.integer(transition_grid$destination_patch),
          n_individuals = as.integer(
            counts[cbind(transition_grid$origin_patch, transition_grid$destination_patch)]
          )
        )
      })
    }
  )
  transitions$alive_only <- alive_only

  transitions_overall <- transitions |>
    dplyr::group_by(.data$origin_patch, .data$destination_patch) |>
    dplyr::summarise(
      mean_n_individuals = mean(.data$n_individuals),
      total_n_individuals = sum(.data$n_individuals),
      .groups = "drop"
    ) |>
    dplyr::group_by(.data$origin_patch) |>
    dplyr::mutate(
      p_transition_given_origin = {
        total_origin <- sum(.data$total_n_individuals)
        if (total_origin > 0) .data$total_n_individuals / total_origin else NA_real_
      }
    ) |>
    dplyr::ungroup()
  transitions_overall$alive_only <- alive_only

  occupancy <- summarise_patch_occupancy_timeseries(
    sim_output = sim_output,
    n_patches = n_patches,
    alive_only = alive_only
  )$per_run

  net_patch_change <- occupancy |>
    dplyr::select("run", "year", "patch_id", "n_alive", "alive_only") |>
    dplyr::group_by(.data$run, .data$patch_id) |>
    dplyr::arrange(.data$year, .by_group = TRUE) |>
    dplyr::mutate(
      delta_n_alive = .data$n_alive - dplyr::lag(.data$n_alive)
    ) |>
    dplyr::ungroup()

  turnover <- occupancy |>
    dplyr::group_by(.data$run, .data$patch_id) |>
    dplyr::arrange(.data$year, .by_group = TRUE) |>
    dplyr::mutate(
      prev_n_alive = dplyr::lag(.data$n_alive),
      colonized = !is.na(.data$prev_n_alive) & .data$prev_n_alive == 0L & .data$n_alive > 0L,
      extirpated = !is.na(.data$prev_n_alive) & .data$prev_n_alive > 0L & .data$n_alive == 0L
    ) |>
    dplyr::ungroup() |>
    dplyr::select("run", "year", "patch_id", "colonized", "extirpated", "alive_only")

  list(
    transitions = transitions,
    transitions_overall = transitions_overall,
    net_patch_change = net_patch_change,
    turnover = turnover
  )
}
