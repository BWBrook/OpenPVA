#' Summarise PRCC sensitivity diagnostics
#'
#' Computes parameter-wise partial rank correlations between draw-level inputs
#' and a selected response metric.
#'
#' @param ensemble_data Draw-level data frame with response and parameter
#'   columns, or a list containing that table as `per_draw`.
#' @param response_col Response column name in draw-level data.
#' @param parameter_cols Optional character vector of parameter column names.
#'   When `NULL`, numeric draw columns are used after excluding `draw_id`, the
#'   response, and standard per-draw summary metric columns.
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

.as_sensitivity_draw_table <- function(ensemble_data) {
  if (is.data.frame(ensemble_data)) {
    return(tibble::as_tibble(ensemble_data))
  }
  if (is.list(ensemble_data) && is.data.frame(ensemble_data$per_draw)) {
    return(tibble::as_tibble(ensemble_data$per_draw))
  }
  stop(
    "ensemble_data must be a draw-level data frame or list containing per_draw",
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
