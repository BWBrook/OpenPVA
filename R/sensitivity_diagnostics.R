#' Summarise PRCC sensitivity diagnostics
#'
#' Computes parameter-wise partial rank correlations between uncertainty inputs
#' and a selected response metric from ensemble outputs.
#'
#' @param ensemble_data One of:
#'   \itemize{
#'     \item list from [summarise_ensemble_outputs()] containing `per_draw`,
#'     \item object from [run_scenario_ensemble()],
#'     \item draw-level data frame with response and parameter columns.
#'   }
#' @param response_col Response column name in draw-level data.
#' @param parameter_cols Optional character vector of parameter column names.
#'   When `NULL`, defaults are inferred in order:
#'   \itemize{
#'     \item `names(uncertainty_spec)` when available from ensemble input,
#'     \item otherwise numeric draw columns excluding `draw_id` and standard
#'       per-draw summary metric columns.
#'   }
#'
#' @return Tibble with one row per parameter and columns:
#'   \itemize{
#'     \item `parameter`
#'     \item `prcc`
#'     \item `p_value`
#'     \item `n_obs`
#'     \item `n_controls`
#'     \item `abs_prcc`
#'   }
#' @export
summarise_sensitivity_prcc <- function(
    ensemble_data,
    response_col = "p_extinction",
    parameter_cols = NULL) {
  draw_tbl <- .as_sensitivity_draw_table(ensemble_data)
  if (!is.character(response_col) || length(response_col) != 1L || !nzchar(response_col)) {
    stop("response_col must be a non-empty character scalar", call. = FALSE)
  }
  if (!response_col %in% names(draw_tbl)) {
    stop("response_col `", response_col, "` not found in draw-level data", call. = FALSE)
  }
  if (!is.numeric(draw_tbl[[response_col]])) {
    stop("response_col `", response_col, "` must be numeric", call. = FALSE)
  }

  inferred_parameter_cols <- NULL
  if (is.null(parameter_cols) &&
      inherits(ensemble_data, "openpva_ensemble_output") &&
      !is.null(ensemble_data$uncertainty_spec)) {
    inferred_parameter_cols <- names(ensemble_data$uncertainty_spec)
  }
  if (is.null(parameter_cols) &&
      is.list(ensemble_data) &&
      !is.null(ensemble_data$uncertainty_spec)) {
    inferred_parameter_cols <- names(ensemble_data$uncertainty_spec)
  }
  if (!is.null(inferred_parameter_cols) && length(inferred_parameter_cols)) {
    parameter_cols <- inferred_parameter_cols
  }

  if (is.null(parameter_cols)) {
    numeric_cols <- names(draw_tbl)[vapply(draw_tbl, is.numeric, logical(1))]
    known_summary_cols <- c(
      "draw_id",
      "p_extinction",
      "mean_time_to_extinction",
      "median_time_to_extinction",
      "mean_final_n_alive",
      "median_final_n_alive",
      "p_final_below_floor",
      "p_any_below_floor"
    )
    parameter_cols <- setdiff(numeric_cols, c(known_summary_cols, response_col))
  }
  if (!is.character(parameter_cols) || !length(parameter_cols)) {
    stop("parameter_cols must resolve to at least one column name", call. = FALSE)
  }
  missing_cols <- setdiff(parameter_cols, names(draw_tbl))
  if (length(missing_cols)) {
    stop(
      "parameter_cols include unknown column(s): ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }
  bad_type <- parameter_cols[!vapply(draw_tbl[parameter_cols], is.numeric, logical(1))]
  if (length(bad_type)) {
    stop(
      "PRCC parameter columns must be numeric: ",
      paste(bad_type, collapse = ", "),
      call. = FALSE
    )
  }

  analysis_tbl <- draw_tbl[, c(response_col, parameter_cols), drop = FALSE]
  analysis_tbl <- analysis_tbl[stats::complete.cases(analysis_tbl), , drop = FALSE]
  if (nrow(analysis_tbl) < 5L) {
    stop("At least 5 complete draw rows are required for PRCC diagnostics", call. = FALSE)
  }

  response_rank <- rank(analysis_tbl[[response_col]], ties.method = "average")
  out <- purrr::map_dfr(parameter_cols, function(param) {
    param_rank <- rank(analysis_tbl[[param]], ties.method = "average")
    controls <- setdiff(parameter_cols, param)
    controls_rank <- NULL
    if (length(controls)) {
      controls_rank <- as.data.frame(lapply(analysis_tbl[controls], rank, ties.method = "average"))
    }
    stats_out <- .compute_partial_corr(
      x = param_rank,
      y = response_rank,
      controls = controls_rank
    )
    tibble::tibble(
      parameter = param,
      prcc = stats_out$correlation,
      p_value = stats_out$p_value,
      n_obs = nrow(analysis_tbl),
      n_controls = length(controls),
      abs_prcc = abs(stats_out$correlation)
    )
  })

  dplyr::arrange(out, dplyr::desc(.data$abs_prcc))
}

#' Summarise one-at-a-time elasticity diagnostics
#'
#' Runs bounded one-at-a-time perturbations around a baseline scenario and
#' computes local slope and elasticity of a scalar response metric.
#'
#' @param scenario Scenario object created by [scenario_spec()].
#' @param oat_spec Named list where each parameter entry contains:
#'   \itemize{
#'     \item `baseline`: baseline scalar value.
#'     \item `delta`: non-negative perturbation magnitude.
#'     \item optional `lower`: lower bound clamp.
#'     \item optional `upper`: upper bound clamp.
#'   }
#' @param metric_fun Function taking `sim_output` from [run_scenario()] and
#'   returning a finite numeric scalar. Defaults to extinction probability.
#' @param metric_name Label for the reported metric.
#' @param seed Optional integer seed applied to baseline and perturbation runs.
#'
#' @return Tibble with one row per parameter and columns:
#'   `parameter`, `metric_name`, `baseline_value`, `low_value`, `high_value`,
#'   `baseline_metric`, `low_metric`, `high_metric`, `local_slope`,
#'   `elasticity`, `pct_change_low`, `pct_change_high`.
#' @export
summarise_sensitivity_oat <- function(
    scenario,
    oat_spec,
    metric_fun = NULL,
    metric_name = "p_extinction",
    seed = NULL) {
  if (!inherits(scenario, "openpva_scenario")) {
    stop("scenario must be created by scenario_spec()", call. = FALSE)
  }
  oat_spec <- .validate_oat_spec(oat_spec, scenario)
  if (is.null(metric_fun)) {
    metric_fun <- function(sim_output) summarise_extinction(sim_output, threshold = 0)$p_extinct
  }
  if (!is.function(metric_fun)) {
    stop("metric_fun must be NULL or a function", call. = FALSE)
  }
  if (!is.character(metric_name) || length(metric_name) != 1L || !nzchar(metric_name)) {
    stop("metric_name must be a non-empty character scalar", call. = FALSE)
  }
  seed <- .normalize_optional_seed(seed)

  scenario_baseline <- .build_oat_scenario(
    scenario = scenario,
    oat_spec = oat_spec,
    seed = seed
  )
  baseline_metric <- .evaluate_oat_metric(
    scenario = scenario_baseline,
    metric_fun = metric_fun,
    label = metric_name
  )

  out <- purrr::map_dfr(names(oat_spec), function(param) {
    spec <- oat_spec[[param]]
    low_value <- spec$baseline - spec$delta
    high_value <- spec$baseline + spec$delta
    if (!is.null(spec$lower)) {
      low_value <- max(low_value, spec$lower)
      high_value <- max(high_value, spec$lower)
    }
    if (!is.null(spec$upper)) {
      low_value <- min(low_value, spec$upper)
      high_value <- min(high_value, spec$upper)
    }

    scenario_low <- .build_oat_scenario(
      scenario = scenario,
      oat_spec = oat_spec,
      seed = seed,
      param_override = param,
      override_value = low_value
    )
    scenario_high <- .build_oat_scenario(
      scenario = scenario,
      oat_spec = oat_spec,
      seed = seed,
      param_override = param,
      override_value = high_value
    )

    low_metric <- .evaluate_oat_metric(
      scenario = scenario_low,
      metric_fun = metric_fun,
      label = metric_name
    )
    high_metric <- .evaluate_oat_metric(
      scenario = scenario_high,
      metric_fun = metric_fun,
      label = metric_name
    )

    span <- high_value - low_value
    local_slope <- NA_real_
    if (is.finite(span) && span > 0) {
      local_slope <- (high_metric - low_metric) / span
    }
    elasticity <- NA_real_
    if (!is.na(local_slope) && baseline_metric != 0 && spec$baseline != 0) {
      elasticity <- local_slope * (spec$baseline / baseline_metric)
    }

    pct_change_low <- NA_real_
    pct_change_high <- NA_real_
    if (baseline_metric != 0) {
      denom <- abs(baseline_metric)
      pct_change_low <- (low_metric - baseline_metric) / denom
      pct_change_high <- (high_metric - baseline_metric) / denom
    }

    tibble::tibble(
      parameter = param,
      metric_name = metric_name,
      baseline_value = spec$baseline,
      low_value = low_value,
      high_value = high_value,
      baseline_metric = baseline_metric,
      low_metric = low_metric,
      high_metric = high_metric,
      local_slope = local_slope,
      elasticity = elasticity,
      pct_change_low = pct_change_low,
      pct_change_high = pct_change_high
    )
  })

  dplyr::arrange(out, dplyr::desc(abs(.data$elasticity)))
}

.as_sensitivity_draw_table <- function(ensemble_data) {
  if (is.data.frame(ensemble_data)) {
    return(tibble::as_tibble(ensemble_data))
  }
  if (inherits(ensemble_data, "openpva_ensemble_output")) {
    return(tibble::as_tibble(summarise_ensemble_outputs(ensemble_data)$per_draw))
  }
  if (is.list(ensemble_data) && is.data.frame(ensemble_data$per_draw)) {
    return(tibble::as_tibble(ensemble_data$per_draw))
  }
  stop(
    "ensemble_data must be a draw-level data frame, summarise_ensemble_outputs() list, ",
    "or run_scenario_ensemble() output",
    call. = FALSE
  )
}

.compute_partial_corr <- function(x, y, controls = NULL) {
  n <- length(x)
  if (!is.null(controls) && nrow(controls) != n) {
    stop("controls must have the same number of rows as x/y", call. = FALSE)
  }

  if (is.null(controls) || !ncol(as.data.frame(controls))) {
    r <- suppressWarnings(stats::cor(x, y))
    df <- n - 2L
  } else {
    controls_mat <- as.matrix(controls)
    x_res <- stats::lm.fit(
      x = cbind(1, controls_mat),
      y = x
    )$residuals
    y_res <- stats::lm.fit(
      x = cbind(1, controls_mat),
      y = y
    )$residuals
    r <- suppressWarnings(stats::cor(x_res, y_res))
    df <- n - ncol(controls_mat) - 2L
  }

  p_val <- NA_real_
  if (is.finite(r) && !is.na(r) && abs(r) < 1 && df > 0) {
    t_val <- r * sqrt(df / (1 - r^2))
    p_val <- 2 * stats::pt(abs(t_val), df = df, lower.tail = FALSE)
  } else if (is.finite(r) && abs(r) == 1 && df > 0) {
    p_val <- 0
  }

  list(correlation = as.numeric(r), p_value = as.numeric(p_val))
}

.validate_oat_spec <- function(oat_spec, scenario) {
  if (!is.list(oat_spec) || !length(oat_spec)) {
    stop("oat_spec must be a non-empty named list", call. = FALSE)
  }
  param_names <- names(oat_spec)
  if (is.null(param_names) || any(!nzchar(param_names))) {
    stop("oat_spec entries must be named with scenario parameter names", call. = FALSE)
  }

  unknown <- setdiff(param_names, names(scenario))
  if (length(unknown)) {
    stop(
      "oat_spec has unknown scenario parameter(s): ",
      paste(unknown, collapse = ", "),
      call. = FALSE
    )
  }

  normalized <- vector("list", length(oat_spec))
  names(normalized) <- param_names
  for (param in param_names) {
    spec <- oat_spec[[param]]
    if (!is.list(spec)) {
      stop("oat_spec entry for `", param, "` must be a list", call. = FALSE)
    }
    baseline <- .validate_scalar_numeric(spec$baseline, param, "baseline")
    delta <- .validate_scalar_numeric(spec$delta, param, "delta")
    if (delta < 0) {
      stop("oat_spec delta must be >= 0 for parameter `", param, "`", call. = FALSE)
    }

    lower <- NULL
    upper <- NULL
    if (!is.null(spec$lower)) {
      lower <- .validate_scalar_numeric(spec$lower, param, "lower")
    }
    if (!is.null(spec$upper)) {
      upper <- .validate_scalar_numeric(spec$upper, param, "upper")
    }
    if (!is.null(lower) && !is.null(upper) && lower > upper) {
      stop("oat_spec lower must be <= upper for parameter `", param, "`", call. = FALSE)
    }
    if (!is.null(lower) && baseline < lower) {
      stop("oat_spec baseline is below lower bound for parameter `", param, "`", call. = FALSE)
    }
    if (!is.null(upper) && baseline > upper) {
      stop("oat_spec baseline is above upper bound for parameter `", param, "`", call. = FALSE)
    }

    normalized[[param]] <- list(
      baseline = baseline,
      delta = delta,
      lower = lower,
      upper = upper
    )
  }

  normalized
}

.build_oat_scenario <- function(
    scenario,
    oat_spec,
    seed = NULL,
    param_override = NULL,
    override_value = NULL) {
  scenario_out <- scenario
  for (param in names(oat_spec)) {
    scenario_out[[param]] <- oat_spec[[param]]$baseline
  }
  if (!is.null(param_override)) {
    scenario_out[[param_override]] <- override_value
  }
  if (!is.null(seed)) {
    scenario_out$seed <- seed
  }
  scenario_out <- .validate_scenario(scenario_out)
  class(scenario_out) <- c("openpva_scenario", "list")
  scenario_out
}

.evaluate_oat_metric <- function(scenario, metric_fun, label) {
  sim_output <- run_scenario(scenario)$sim_output
  value <- metric_fun(sim_output)
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value)) {
    stop("metric_fun must return a finite numeric scalar for metric `", label, "`", call. = FALSE)
  }
  as.numeric(value)
}
