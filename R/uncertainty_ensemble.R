#' Sample uncertainty parameter draws
#'
#' Draws a reproducible table of uncertainty parameters from a named
#' specification list.
#'
#' @param uncertainty_spec Named list of parameter draw specifications.
#'   Each element must be a list with:
#'   \itemize{
#'     \item `dist`: one of `"fixed"`, `"uniform"`, `"normal"`, `"lognormal"`.
#'   }
#'   Distribution-specific fields:
#'   \itemize{
#'     \item `"fixed"`: `value`.
#'     \item `"uniform"`: `min`, `max`.
#'     \item `"normal"`: `mean`, `sd`.
#'     \item `"lognormal"`: `meanlog`, `sdlog`.
#'   }
#'   Optional common fields:
#'   \itemize{
#'     \item `lower`: numeric lower bound (clamp).
#'     \item `upper`: numeric upper bound (clamp).
#'     \item `integer`: logical; if `TRUE`, rounds to nearest integer.
#'   }
#' @param n_draws Number of uncertainty draws (positive integer).
#' @param seed Optional integer seed for reproducible sampling. Caller RNG state
#'   is restored on exit.
#'
#' @return Tibble with one row per draw and required column `draw_id`, plus one
#'   column per uncertainty parameter.
#' @export
sample_uncertainty_parameters <- function(uncertainty_spec, n_draws, seed = NULL) {
  uncertainty_spec <- .validate_uncertainty_spec(uncertainty_spec)
  n_draws <- .normalize_positive_count(n_draws, "n_draws")
  seed <- .normalize_optional_seed(seed)

  if (!is.null(seed)) {
    had_rng <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    if (had_rng) {
      old_rng <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    }
    on.exit({
      if (had_rng) {
        assign(".Random.seed", old_rng, envir = .GlobalEnv)
      } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    }, add = TRUE)
    set.seed(seed)
  }

  draws <- lapply(uncertainty_spec, .draw_uncertainty_values, n_draws = n_draws)
  out <- tibble::tibble(draw_id = seq_len(n_draws))
  for (param in names(draws)) {
    out[[param]] <- draws[[param]]
  }
  out
}

#' Run a scenario ensemble under sampled uncertainty draws
#'
#' Executes a scenario repeatedly across sampled uncertainty draws while
#' preserving reproducibility and draw-level provenance.
#'
#' @param scenario Scenario object created by [scenario_spec()].
#' @param uncertainty_spec Optional named uncertainty draw specification list
#'   passed to [sample_uncertainty_parameters()]. Parameter names must match
#'   writable fields on `scenario`. If `NULL`, uses
#'   `scenario$uncertainty_spec`.
#' @param n_draws Number of uncertainty draws (positive integer).
#' @param seed Optional integer seed controlling draw sampling and all stochastic
#'   simulation paths. Caller RNG state is restored on exit.
#'
#' @return A list of class `openpva_ensemble_output` with elements:
#'   \itemize{
#'     \item `scenario`: input scenario template.
#'     \item `uncertainty_spec`: normalized uncertainty specification.
#'     \item `sampled_parameters`: tibble from
#'       [sample_uncertainty_parameters()].
#'     \item `draw_results`: list of per-draw results with `draw_id`,
#'       `scenario`, and `sim_output`.
#'     \item `seed`: normalized seed or `NULL`.
#'   }
#' @export
run_scenario_ensemble <- function(scenario, uncertainty_spec = NULL, n_draws, seed = NULL) {
  if (!inherits(scenario, "openpva_scenario")) {
    stop("`scenario` must be created by scenario_spec().", call. = FALSE)
  }
  uncertainty_spec <- uncertainty_spec %||% scenario$uncertainty_spec %||% NULL
  if (is.null(uncertainty_spec)) {
    stop(
      "uncertainty_spec must be supplied either as a function argument or scenario field",
      call. = FALSE
    )
  }
  uncertainty_spec <- .validate_uncertainty_spec(uncertainty_spec)
  n_draws <- .normalize_positive_count(n_draws, "n_draws")

  unknown_params <- setdiff(names(uncertainty_spec), names(scenario))
  if (length(unknown_params)) {
    stop(
      "Unknown uncertainty parameter(s) in uncertainty_spec: ",
      paste(unknown_params, collapse = ", "),
      call. = FALSE
    )
  }

  seed <- .normalize_optional_seed(seed)
  if (!is.null(seed)) {
    had_rng <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    if (had_rng) {
      old_rng <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    }
    on.exit({
      if (had_rng) {
        assign(".Random.seed", old_rng, envir = .GlobalEnv)
      } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    }, add = TRUE)
    set.seed(seed)
  }

  sampled_parameters <- sample_uncertainty_parameters(
    uncertainty_spec = uncertainty_spec,
    n_draws = n_draws,
    seed = NULL
  )

  draw_results <- vector("list", n_draws)
  for (i in seq_len(n_draws)) {
    scenario_draw <- scenario
    for (param in names(uncertainty_spec)) {
      scenario_draw[[param]] <- sampled_parameters[[param]][[i]]
    }
    scenario_draw <- .validate_scenario(scenario_draw)
    out <- run_scenario(scenario_draw)
    draw_results[[i]] <- list(
      draw_id = as.integer(i),
      scenario = out$scenario,
      sim_output = out$sim_output
    )
  }

  structure(
    list(
      scenario = scenario,
      uncertainty_spec = uncertainty_spec,
      sampled_parameters = sampled_parameters,
      draw_results = draw_results,
      seed = seed
    ),
    class = c("openpva_ensemble_output", "list")
  )
}

#' Summarise ensemble outputs
#'
#' Computes per-draw and overall uncertainty summaries from
#' [run_scenario_ensemble()] output.
#'
#' @param ensemble_output Object returned by [run_scenario_ensemble()].
#' @param extinction_threshold Non-negative threshold passed to
#'   [summarise_extinction()].
#' @param final_n_floor Non-negative final-abundance floor passed to
#'   [summarise_final_abundance()]. Defaults to `extinction_threshold`.
#'
#' @return List with:
#'   \itemize{
#'     \item `per_draw`: tibble containing draw-level metrics joined to sampled
#'       parameter columns.
#'     \item `overall`: one-row tibble with aggregate uncertainty summary
#'       statistics.
#'   }
#' @export
summarise_ensemble_outputs <- function(
    ensemble_output,
    extinction_threshold = 0,
    final_n_floor = extinction_threshold) {
  if (!inherits(ensemble_output, "openpva_ensemble_output")) {
    stop("ensemble_output must be returned by run_scenario_ensemble()", call. = FALSE)
  }
  if (!is.list(ensemble_output$draw_results) || !length(ensemble_output$draw_results)) {
    stop("ensemble_output$draw_results must be a non-empty list", call. = FALSE)
  }
  if (!is.data.frame(ensemble_output$sampled_parameters) ||
      !"draw_id" %in% names(ensemble_output$sampled_parameters)) {
    stop("ensemble_output$sampled_parameters must include draw_id", call. = FALSE)
  }

  extinction_threshold <- as.numeric(extinction_threshold)
  if (length(extinction_threshold) != 1L || is.na(extinction_threshold) ||
      extinction_threshold < 0) {
    stop("extinction_threshold must be a single non-negative numeric value", call. = FALSE)
  }
  final_n_floor <- as.numeric(final_n_floor)
  if (length(final_n_floor) != 1L || is.na(final_n_floor) || final_n_floor < 0) {
    stop("final_n_floor must be a single non-negative numeric value", call. = FALSE)
  }

  per_draw_metrics <- purrr::map_dfr(ensemble_output$draw_results, function(draw) {
    ext <- summarise_extinction(
      draw$sim_output,
      threshold = extinction_threshold
    )
    final <- summarise_final_abundance(
      draw$sim_output,
      floor = final_n_floor
    )
    tibble::tibble(
      draw_id = as.integer(draw$draw_id),
      p_extinction = ext$p_extinct,
      mean_time_to_extinction = ext$mean_time_to_extinction,
      median_time_to_extinction = ext$median_time_to_extinction,
      mean_final_n_alive = final$overall$mean_final_n_alive,
      median_final_n_alive = final$overall$median_final_n_alive,
      p_final_below_floor = final$overall$p_final_below_floor,
      p_any_below_floor = final$overall$p_any_below_floor
    )
  })

  sampled <- tibble::as_tibble(ensemble_output$sampled_parameters)
  per_draw <- dplyr::left_join(per_draw_metrics, sampled, by = "draw_id")

  overall <- tibble::tibble(
    n_draws = nrow(per_draw),
    extinction_threshold = extinction_threshold,
    final_n_floor = final_n_floor,
    mean_p_extinction = mean(per_draw$p_extinction),
    sd_p_extinction = stats::sd(per_draw$p_extinction),
    mean_mean_final_n_alive = mean(per_draw$mean_final_n_alive),
    sd_mean_final_n_alive = stats::sd(per_draw$mean_final_n_alive),
    mean_p_final_below_floor = mean(per_draw$p_final_below_floor),
    sd_p_final_below_floor = stats::sd(per_draw$p_final_below_floor),
    mean_p_any_below_floor = mean(per_draw$p_any_below_floor),
    sd_p_any_below_floor = stats::sd(per_draw$p_any_below_floor)
  )

  list(per_draw = per_draw, overall = overall)
}

.normalize_positive_count <- function(value, label) {
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value)) {
    stop(label, " must be a single positive integer", call. = FALSE)
  }
  value_int <- suppressWarnings(as.integer(value))
  if (is.na(value_int) || value_int != value || value_int < 1L) {
    stop(label, " must be a single positive integer", call. = FALSE)
  }
  value_int
}

.validate_uncertainty_spec <- function(uncertainty_spec) {
  if (!is.list(uncertainty_spec) || !length(uncertainty_spec)) {
    stop("uncertainty_spec must be a non-empty named list", call. = FALSE)
  }
  param_names <- names(uncertainty_spec)
  if (is.null(param_names) || any(!nzchar(param_names))) {
    stop("uncertainty_spec must be a named list with non-empty parameter names", call. = FALSE)
  }

  allowed_dist <- c("fixed", "uniform", "normal", "lognormal")
  normalized <- vector("list", length(uncertainty_spec))
  names(normalized) <- param_names

  for (param in param_names) {
    spec <- uncertainty_spec[[param]]
    if (!is.list(spec) || is.null(spec$dist) || length(spec$dist) != 1L) {
      stop("Each uncertainty_spec entry must be a list with scalar `dist`", call. = FALSE)
    }
    dist <- as.character(spec$dist)
    if (!dist %in% allowed_dist) {
      stop(
        "Unsupported dist `", dist, "` for parameter `", param,
        "`. Allowed: ", paste(allowed_dist, collapse = ", "),
        call. = FALSE
      )
    }

    normalized_spec <- list(dist = dist)
    if (dist == "fixed") {
      normalized_spec$value <- .validate_scalar_numeric(spec$value, param, "value")
    } else if (dist == "uniform") {
      normalized_spec$min <- .validate_scalar_numeric(spec$min, param, "min")
      normalized_spec$max <- .validate_scalar_numeric(spec$max, param, "max")
      if (normalized_spec$min > normalized_spec$max) {
        stop("uniform spec `min` must be <= `max` for parameter `", param, "`", call. = FALSE)
      }
    } else if (dist == "normal") {
      normalized_spec$mean <- .validate_scalar_numeric(spec$mean, param, "mean")
      normalized_spec$sd <- .validate_scalar_numeric(spec$sd, param, "sd")
      if (normalized_spec$sd < 0) {
        stop("normal spec `sd` must be >= 0 for parameter `", param, "`", call. = FALSE)
      }
    } else if (dist == "lognormal") {
      normalized_spec$meanlog <- .validate_scalar_numeric(spec$meanlog, param, "meanlog")
      normalized_spec$sdlog <- .validate_scalar_numeric(spec$sdlog, param, "sdlog")
      if (normalized_spec$sdlog < 0) {
        stop("lognormal spec `sdlog` must be >= 0 for parameter `", param, "`", call. = FALSE)
      }
    }

    if (!is.null(spec$lower)) {
      normalized_spec$lower <- .validate_scalar_numeric(spec$lower, param, "lower")
    }
    if (!is.null(spec$upper)) {
      normalized_spec$upper <- .validate_scalar_numeric(spec$upper, param, "upper")
    }
    if (!is.null(normalized_spec$lower) && !is.null(normalized_spec$upper) &&
        normalized_spec$lower > normalized_spec$upper) {
      stop("`lower` must be <= `upper` for parameter `", param, "`", call. = FALSE)
    }

    integer_flag <- spec$integer %||% FALSE
    if (!is.logical(integer_flag) || length(integer_flag) != 1L || is.na(integer_flag)) {
      stop("`integer` must be a single logical value for parameter `", param, "`", call. = FALSE)
    }
    normalized_spec$integer <- integer_flag

    normalized[[param]] <- normalized_spec
  }

  normalized
}

.validate_scalar_numeric <- function(value, param, field) {
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value)) {
    stop(
      "Field `", field, "` must be a finite numeric scalar for parameter `",
      param, "`",
      call. = FALSE
    )
  }
  as.numeric(value)
}

.draw_uncertainty_values <- function(spec, n_draws) {
  draws <- switch(
    spec$dist,
    fixed = rep(spec$value, n_draws),
    uniform = stats::runif(n_draws, min = spec$min, max = spec$max),
    normal = stats::rnorm(n_draws, mean = spec$mean, sd = spec$sd),
    lognormal = stats::rlnorm(n_draws, meanlog = spec$meanlog, sdlog = spec$sdlog)
  )

  if (!is.null(spec$lower)) {
    draws <- pmax(draws, spec$lower)
  }
  if (!is.null(spec$upper)) {
    draws <- pmin(draws, spec$upper)
  }
  if (isTRUE(spec$integer)) {
    draws <- as.integer(round(draws))
  }

  if (any(!is.finite(draws))) {
    stop("Non-finite draws encountered in uncertainty sampling", call. = FALSE)
  }
  draws
}
