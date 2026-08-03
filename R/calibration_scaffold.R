#' Score observed-vs-simulated hindcast targets
#'
#' Computes bounded, transparent error metrics for calibration scaffolds.
#'
#' @param observed Numeric vector of observed target values. Names are optional.
#' @param simulated Numeric vector of simulated target values. If both vectors
#'   are named, values are aligned by `observed` names.
#' @param weights Optional non-negative numeric weights of the same length.
#'
#' @return One-row tibble with columns:
#'   `n_targets`, `rmse`, `mae`, `bias`, `mape`.
#' @export
score_hindcast_fit <- function(observed, simulated, weights = NULL) {
  observed <- .normalize_named_numeric(observed, "observed")
  simulated <- .normalize_named_numeric(simulated, "simulated")

  if (length(observed) != length(simulated)) {
    stop("observed and simulated must have the same length", call. = FALSE)
  }

  obs_names <- names(observed)
  sim_names <- names(simulated)
  if (!is.null(obs_names) && any(nzchar(obs_names))) {
    if (is.null(sim_names) || !all(nzchar(sim_names))) {
      stop("simulated must be named when observed is named", call. = FALSE)
    }
    missing_sim <- setdiff(obs_names, sim_names)
    if (length(missing_sim)) {
      stop(
        "simulated is missing observed target(s): ",
        paste(missing_sim, collapse = ", "),
        call. = FALSE
      )
    }
    simulated <- simulated[obs_names]
  }

  if (is.null(weights)) {
    weights <- rep(1, length(observed))
  } else {
    if (!is.numeric(weights) || length(weights) != length(observed) ||
        any(!is.finite(weights)) || any(weights < 0)) {
      stop("weights must be NULL or a non-negative numeric vector matching target length", call. = FALSE)
    }
    if (all(weights == 0)) {
      stop("weights must include at least one positive value", call. = FALSE)
    }
  }
  weights <- as.numeric(weights)

  errors <- as.numeric(simulated) - as.numeric(observed)
  w_denom <- sum(weights)
  rmse <- sqrt(sum(weights * (errors^2)) / w_denom)
  mae <- sum(weights * abs(errors)) / w_denom
  bias <- sum(weights * errors) / w_denom
  mape <- NA_real_
  if (all(observed != 0)) {
    mape <- sum(weights * abs(errors / observed)) / w_denom
  }

  tibble::tibble(
    n_targets = as.integer(length(observed)),
    rmse = rmse,
    mae = mae,
    bias = bias,
    mape = mape
  )
}

#' Generate bounded calibration candidates
#'
#' Creates candidate parameter tables for calibration using either grid or
#' random sampling within explicit bounds.
#'
#' @param parameter_space Named list of parameter bounds/specs. Each parameter
#'   entry must include numeric `lower` and `upper` (`lower <= upper`) and may
#'   include:
#'   \itemize{
#'     \item `integer` (logical; default `FALSE`)
#'     \item `grid_values` (numeric vector for `method = "grid"`)
#'     \item `n_grid` (positive integer for evenly spaced grid fallback)
#'   }
#' @param method Candidate generation method: `"grid"` or `"random"`.
#' @param n_candidates Positive integer random candidate count when
#'   `method = "random"`. Ignored for grid generation.
#' @param seed Optional integer seed for reproducible random candidate draws.
#'
#' @return Tibble with required column `candidate_id` and one column per
#'   parameter.
#' @export
generate_calibration_candidates <- function(
    parameter_space,
    method = c("grid", "random"),
    n_candidates = 50,
    seed = NULL) {
  parameter_space <- .validate_parameter_space(parameter_space)
  method <- match.arg(method)
  seed <- .normalize_optional_seed(seed)

  if (method == "grid") {
    per_param_values <- lapply(names(parameter_space), function(param) {
      spec <- parameter_space[[param]]
      values <- spec$grid_values
      if (is.null(values)) {
        n_grid <- spec$n_grid %||% 5L
        n_grid <- .normalize_positive_count(n_grid, "n_grid")
        if (n_grid < 2L && spec$lower != spec$upper) {
          stop("n_grid must be at least 2 when lower != upper for `", param, "`", call. = FALSE)
        }
        values <- seq(spec$lower, spec$upper, length.out = n_grid)
      }
      values <- as.numeric(values)
      if (spec$integer) {
        values <- as.integer(round(values))
      }
      values <- values[is.finite(values)]
      values <- values[values >= spec$lower & values <= spec$upper]
      values <- sort(unique(values))
      if (!length(values)) {
        stop("No valid grid values produced for parameter `", param, "`", call. = FALSE)
      }
      values
    })
    names(per_param_values) <- names(parameter_space)
    grid_df <- do.call(expand.grid, c(per_param_values, stringsAsFactors = FALSE))
    out <- tibble::as_tibble(grid_df)
  } else {
    n_candidates <- .normalize_positive_count(n_candidates, "n_candidates")
    draw_list <- .with_optional_seed(seed, {
      draw_list <- vector("list", length(parameter_space))
      names(draw_list) <- names(parameter_space)
      for (param in names(parameter_space)) {
        spec <- parameter_space[[param]]
        draws <- stats::runif(n_candidates, min = spec$lower, max = spec$upper)
        if (spec$integer) {
          draws <- as.integer(round(draws))
        }
        draw_list[[param]] <- draws
      }
      draw_list
    })
    out <- tibble::as_tibble(draw_list)
  }

  out$candidate_id <- seq_len(nrow(out))
  out <- dplyr::select(out, "candidate_id", dplyr::everything())
  out
}

#' Run bounded calibration search
#'
#' Evaluates candidate parameter sets against observed hindcast targets using a
#' transparent objective score (`rmse`) plus companion diagnostics.
#'
#' @param scenario Scenario object created by [scenario_spec()].
#' @param candidates Candidate table from [generate_calibration_candidates()].
#'   Must include `candidate_id` and one or more scenario-parameter columns.
#' @param observed_targets Named numeric vector of observed target values.
#' @param simulate_targets_fun Function taking `sim_output` from
#'   [run_scenario()] and returning named numeric target values.
#' @param seed Optional integer seed applied to every candidate simulation run.
#'
#' @return List of class `openpva_calibration_result` with:
#'   \itemize{
#'     \item `scores`: candidate table with objective/error columns.
#'     \item `best_fit`: one-row tibble for the minimum objective score.
#'     \item `observed_targets`: one-row tibble of observed targets used.
#'   }
#' @export
run_calibration_search <- function(
    scenario,
    candidates,
    observed_targets,
    simulate_targets_fun = NULL,
    seed = NULL) {
  if (!inherits(scenario, "openpva_scenario")) {
    stop("scenario must be created by scenario_spec()", call. = FALSE)
  }
  if (!is.data.frame(candidates) || !nrow(candidates)) {
    stop("candidates must be a non-empty data frame", call. = FALSE)
  }
  if (!"candidate_id" %in% names(candidates)) {
    stop("candidates must include candidate_id", call. = FALSE)
  }

  observed_targets <- .normalize_named_numeric(observed_targets, "observed_targets")
  if (is.null(names(observed_targets)) || !all(nzchar(names(observed_targets)))) {
    stop("observed_targets must be a named numeric vector", call. = FALSE)
  }

  if (is.null(simulate_targets_fun)) {
    simulate_targets_fun <- function(sim_output) {
      c(
        p_extinction = summarise_extinction(sim_output, threshold = 0)$p_extinct,
        mean_final_n_alive = summarise_final_abundance(sim_output)$overall$mean_final_n_alive
      )
    }
  }
  if (!is.function(simulate_targets_fun)) {
    stop("simulate_targets_fun must be NULL or a function", call. = FALSE)
  }

  seed <- .normalize_optional_seed(seed)

  candidate_params <- setdiff(names(candidates), "candidate_id")
  if (!length(candidate_params)) {
    stop("candidates must include at least one parameter column", call. = FALSE)
  }
  unknown <- setdiff(candidate_params, names(scenario))
  if (length(unknown)) {
    stop(
      "candidates include unknown scenario parameter(s): ",
      paste(unknown, collapse = ", "),
      call. = FALSE
    )
  }

  score_tbl <- purrr::map_dfr(seq_len(nrow(candidates)), function(i) {
    row <- candidates[i, , drop = FALSE]
    scenario_i <- scenario
    for (param in candidate_params) {
      scenario_i[[param]] <- row[[param]][[1]]
    }
    if (!is.null(seed)) {
      scenario_i$seed <- seed
    }
    scenario_i <- .validate_scenario(scenario_i)
    class(scenario_i) <- c("openpva_scenario", "list")

    sim_output <- run_scenario(scenario_i)$sim_output
    simulated_targets <- .normalize_named_numeric(simulate_targets_fun(sim_output), "simulated_targets")
    if (is.null(names(simulated_targets)) || !all(nzchar(names(simulated_targets)))) {
      stop("simulate_targets_fun must return a named numeric vector", call. = FALSE)
    }
    missing_targets <- setdiff(names(observed_targets), names(simulated_targets))
    if (length(missing_targets)) {
      stop(
        "simulate_targets_fun output is missing observed target(s): ",
        paste(missing_targets, collapse = ", "),
        call. = FALSE
      )
    }
    simulated_aligned <- simulated_targets[names(observed_targets)]
    fit <- score_hindcast_fit(observed_targets, simulated_aligned)

    err_tbl <- as.list(simulated_aligned - observed_targets)
    names(err_tbl) <- paste0("error_", names(observed_targets))
    sim_tbl <- as.list(simulated_aligned)
    names(sim_tbl) <- paste0("sim_", names(observed_targets))

    tibble::as_tibble(c(
      list(candidate_id = as.integer(row$candidate_id[[1]])),
      as.list(fit[1, , drop = TRUE]),
      list(objective_score = as.numeric(fit$rmse)),
      sim_tbl,
      err_tbl
    ))
  })

  candidates_tbl <- tibble::as_tibble(candidates)
  scores <- dplyr::left_join(candidates_tbl, score_tbl, by = "candidate_id")
  scores <- dplyr::arrange(scores, .data$objective_score, abs(.data$bias))
  best_fit <- dplyr::slice(scores, 1L)
  observed_tbl <- tibble::as_tibble_row(as.list(observed_targets))

  structure(
    list(
      scores = scores,
      best_fit = best_fit,
      observed_targets = observed_tbl
    ),
    class = c("openpva_calibration_result", "list")
  )
}

.validate_parameter_space <- function(parameter_space) {
  if (!is.list(parameter_space) || !length(parameter_space)) {
    stop("parameter_space must be a non-empty named list", call. = FALSE)
  }
  params <- names(parameter_space)
  if (is.null(params) || any(!nzchar(params))) {
    stop("parameter_space entries must be named", call. = FALSE)
  }

  normalized <- vector("list", length(parameter_space))
  names(normalized) <- params
  for (param in params) {
    spec <- parameter_space[[param]]
    if (!is.list(spec)) {
      stop("parameter_space entry for `", param, "` must be a list", call. = FALSE)
    }
    lower <- .validate_scalar_numeric(spec$lower, param, "lower")
    upper <- .validate_scalar_numeric(spec$upper, param, "upper")
    if (lower > upper) {
      stop("parameter_space lower must be <= upper for `", param, "`", call. = FALSE)
    }
    integer <- spec$integer %||% FALSE
    if (!is.logical(integer) || length(integer) != 1L || is.na(integer)) {
      stop("parameter_space integer must be logical scalar for `", param, "`", call. = FALSE)
    }

    grid_values <- spec$grid_values %||% NULL
    if (!is.null(grid_values)) {
      if (!is.numeric(grid_values) || !length(grid_values) || any(!is.finite(grid_values))) {
        stop("grid_values must be finite numeric vector for `", param, "`", call. = FALSE)
      }
    }
    n_grid <- spec$n_grid %||% NULL
    if (!is.null(n_grid)) {
      n_grid <- .normalize_positive_count(n_grid, paste0("n_grid for ", param))
    }

    normalized[[param]] <- list(
      lower = lower,
      upper = upper,
      integer = as.logical(integer),
      grid_values = grid_values,
      n_grid = n_grid
    )
  }

  normalized
}

.normalize_named_numeric <- function(x, label) {
  if (!is.numeric(x) || !length(x) || any(!is.finite(x))) {
    stop(label, " must be a non-empty finite numeric vector", call. = FALSE)
  }
  nms <- names(x)
  x <- as.numeric(x)
  if (!is.null(nms)) {
    names(x) <- nms
  }
  x
}
