.validate_yaml_keys <- function(x, allowed, label) {
  unknown <- setdiff(names(x), allowed)
  if (length(unknown)) {
    stop(
      label, " has unknown field(s): ",
      paste(unknown, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(x)
}

.resolve_function_reference <- function(ref) {
  if (is.function(ref)) {
    return(ref)
  }
  if (!is.character(ref) || length(ref) != 1L || !nzchar(ref)) {
    stop("Function reference must be a non-empty character scalar or function", call. = FALSE)
  }

  if (grepl("::", ref, fixed = TRUE)) {
    parts <- strsplit(ref, "::", fixed = TRUE)[[1L]]
    if (length(parts) != 2L || any(!nzchar(parts))) {
      stop("Invalid namespaced function reference `", ref, "`", call. = FALSE)
    }
    package_name <- parts[[1L]]
    function_name <- parts[[2L]]
    if (!requireNamespace(package_name, quietly = TRUE)) {
      stop("Package `", package_name, "` is required for `", ref, "`", call. = FALSE)
    }
    return(getExportedValue(package_name, function_name))
  }

  if (exists(ref, where = asNamespace("OpenPVA"), inherits = FALSE)) {
    return(utils::getFromNamespace(ref, "OpenPVA"))
  }

  stop(
    "Unknown unnamespaced function reference `", ref,
    "`. Use an OpenPVA function or an explicit pkg::fun reference.",
    call. = FALSE
  )
}

.coerce_yaml_table <- function(tbl, label) {
  if (is.null(tbl)) {
    return(NULL)
  }
  if (is.data.frame(tbl)) {
    return(tbl)
  }
  if (is.list(tbl)) {
    return(dplyr::bind_rows(tbl))
  }
  stop(label, " must be a data frame or list of rows", call. = FALSE)
}

.parse_density_channel_yaml <- function(channel_cfg, channel_label) {
  if (is.null(channel_cfg)) {
    return(NULL)
  }
  if (!is.list(channel_cfg)) {
    stop("density.", channel_label, " must be a mapping/list", call. = FALSE)
  }

  .validate_yaml_keys(
    channel_cfg,
    allowed = c("fun", "model", "multiplier", "K", "K_patches"),
    label = paste0("density.", channel_label)
  )

  fun_ref <- channel_cfg$fun %||% NULL
  model <- channel_cfg$model %||% NULL

  if (!is.null(fun_ref)) {
    if (!is.null(model) ||
        !is.null(channel_cfg$multiplier) ||
        !is.null(channel_cfg$K) ||
        !is.null(channel_cfg$K_patches)) {
      stop(
        "density.", channel_label,
        " with `fun` cannot also define model/multiplier/K/K_patches",
        call. = FALSE
      )
    }
    return(.resolve_function_reference(fun_ref))
  }

  if (!is.character(model) || length(model) != 1L) {
    stop("density.", channel_label, ".model must be a character scalar", call. = FALSE)
  }
  model <- tolower(trimws(model))

  if (model == "constant") {
    multiplier <- channel_cfg$multiplier
    if (!is.numeric(multiplier) || length(multiplier) != 1L ||
        is.na(multiplier) || !is.finite(multiplier) || multiplier < 0) {
      stop(
        "density.", channel_label,
        ".multiplier must be a finite numeric scalar >= 0",
        call. = FALSE
      )
    }
    multiplier <- as.numeric(multiplier)
    return(function(population, ind) multiplier)
  }

  if (model == "ceiling") {
    return(make_ceiling_density_fun(
      K = channel_cfg$K %||% NULL,
      K_patches = channel_cfg$K_patches %||% NULL
    ))
  }

  stop(
    "density.", channel_label,
    ".model must be one of 'constant' or 'ceiling'",
    call. = FALSE
  )
}

.build_density_spec_from_yaml <- function(density_cfg) {
  if (is.null(density_cfg)) {
    return(NULL)
  }
  if (!is.list(density_cfg)) {
    stop("density must be a mapping/list", call. = FALSE)
  }

  .validate_yaml_keys(
    density_cfg,
    allowed = c("survival", "breeding", "fecundity"),
    label = "density"
  )

  survival_fun <- .parse_density_channel_yaml(density_cfg$survival %||% NULL, "survival")
  breeding_fun <- .parse_density_channel_yaml(density_cfg$breeding %||% NULL, "breeding")
  fecundity_fun <- .parse_density_channel_yaml(density_cfg$fecundity %||% NULL, "fecundity")

  if (is.null(survival_fun) && is.null(breeding_fun) && is.null(fecundity_fun)) {
    stop("density must define at least one channel", call. = FALSE)
  }

  density_spec(
    survival_fun = survival_fun,
    breeding_fun = breeding_fun,
    fecundity_fun = fecundity_fun
  )
}

.parse_uncertainty_yaml <- function(uncertainty_cfg) {
  if (is.null(uncertainty_cfg)) {
    return(NULL)
  }
  if (!is.list(uncertainty_cfg)) {
    stop("uncertainty must be a mapping/list", call. = FALSE)
  }

  uncertainty_params <- uncertainty_cfg$params %||% uncertainty_cfg
  if (!is.list(uncertainty_params) || !length(uncertainty_params)) {
    stop("uncertainty must define at least one parameter mapping", call. = FALSE)
  }
  .validate_uncertainty_spec(uncertainty_params)
}

.validate_yaml_cfg_v3 <- function(cfg) {
  if (!is.list(cfg)) {
    stop("YAML scenario file must parse to a named list.", call. = FALSE)
  }

  .validate_yaml_keys(
    cfg,
    allowed = c(
      "schema_version", "name", "n_runs", "n_years", "initializer",
      "survival_fun", "breeding_prob_fun", "fecundity_lambda_fun",
      "demography", "management", "lifecycle_steps", "mating_fun",
      "dispersal_fun", "inherit_fun", "env_surv_sd", "cat_surv_prob",
      "cat_surv_mult", "reproduction_ev", "density", "uncertainty",
      "seed", "require_mate", "record_population_history"
    ),
    label = "scenario"
  )

  if (is.null(cfg$schema_version) || !identical(as.integer(cfg$schema_version), 3L)) {
    stop("OpenPVA now requires schema_version: 3 in YAML scenarios.", call. = FALSE)
  }

  required <- c("name", "n_runs", "n_years", "initializer")
  missing_required <- required[vapply(required, function(key) is.null(cfg[[key]]), logical(1))]
  if (length(missing_required)) {
    stop(
      "YAML schema_version 3 requires fields: ",
      paste(missing_required, collapse = ", "),
      call. = FALSE
    )
  }

  if (!is.list(cfg$initializer) || is.null(cfg$initializer$fun)) {
    stop("initializer.fun must be provided in YAML.", call. = FALSE)
  }

  if (!is.null(cfg$management) && !is.list(cfg$management)) {
    stop("management must be a mapping/list", call. = FALSE)
  }
  if (!is.null(cfg$demography) && !is.list(cfg$demography)) {
    stop("demography must be a mapping/list", call. = FALSE)
  }
  if (!is.null(cfg$reproduction_ev) && !is.list(cfg$reproduction_ev)) {
    stop("reproduction_ev must be a mapping/list", call. = FALSE)
  }
  if (!is.null(cfg$density) && !is.list(cfg$density)) {
    stop("density must be a mapping/list", call. = FALSE)
  }
  if (!is.null(cfg$uncertainty) && !is.list(cfg$uncertainty)) {
    stop("uncertainty must be a mapping/list", call. = FALSE)
  }

  cfg
}

#' Read a scenario specification from YAML
#'
#' Parses a canonical schema v3 YAML file and returns an `openpva_scenario`
#' object.
#'
#' @param path Path to a YAML file.
#'
#' @return An `openpva_scenario` object.
#' @export
read_scenario_yaml <- function(path) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required to read scenario YAML files. Please install it.", call. = FALSE)
  }

  cfg <- yaml::read_yaml(path)
  cfg <- .validate_yaml_cfg_v3(cfg)

  init_fun <- function() {
    init_ref <- .resolve_function_reference(cfg$initializer$fun)
    init_args <- cfg$initializer$args %||% list()
    if (!is.list(init_args)) {
      stop("initializer.args must be a named mapping/list", call. = FALSE)
    }
    do.call(init_ref, as.list(init_args))
  }

  survival_fun <- .resolve_function_reference(cfg$survival_fun %||% "default_survival_fun")
  breeding_prob_fun <- .resolve_function_reference(cfg$breeding_prob_fun %||% "default_breeding_prob_fun")
  fecundity_lambda_fun <- .resolve_function_reference(cfg$fecundity_lambda_fun %||% "default_fecundity_lambda_fun")
  mating_fun <- .resolve_function_reference(cfg$mating_fun %||% "default_mating_fun")
  dispersal_fun <- .resolve_function_reference(cfg$dispersal_fun %||% "default_dispersal_fun")
  inherit_fun <- if (is.null(cfg$inherit_fun)) NULL else .resolve_function_reference(cfg$inherit_fun)

  demography <- cfg$demography %||% list()
  .validate_yaml_keys(
    demography,
    allowed = c("survival", "breeding_prob", "fecundity_lambda"),
    label = "demography"
  )

  if (!is.null(demography$survival) && !is.null(demography$survival$table)) {
    survival_tbl <- .coerce_yaml_table(demography$survival$table, "demography.survival.table")
    survival_fun <- build_survival_fun_from_table(validate_survival_table(survival_tbl))
  }
  if (!is.null(demography$breeding_prob) && !is.null(demography$breeding_prob$table)) {
    breeding_tbl <- .coerce_yaml_table(demography$breeding_prob$table, "demography.breeding_prob.table")
    breeding_prob_fun <- build_breeding_prob_fun_from_table(
      validate_breeding_prob_table(breeding_tbl)
    )
  }
  if (!is.null(demography$fecundity_lambda) && !is.null(demography$fecundity_lambda$table)) {
    fecundity_tbl <- .coerce_yaml_table(
      demography$fecundity_lambda$table,
      "demography.fecundity_lambda.table"
    )
    fecundity_lambda_fun <- build_fecundity_lambda_fun_from_table(
      validate_fecundity_lambda_table(fecundity_tbl)
    )
  }

  management <- cfg$management %||% list()
  .validate_yaml_keys(
    management,
    allowed = c("harvest_quota", "supplement_quota", "supplement_patch"),
    label = "management"
  )

  reproduction_ev <- cfg$reproduction_ev %||% list()
  .validate_yaml_keys(
    reproduction_ev,
    allowed = c(
      "env_repro_p_sd",
      "env_repro_lambda_sd",
      "cat_repro_prob",
      "cat_repro_mult"
    ),
    label = "reproduction_ev"
  )

  scenario <- scenario_spec(
    name = cfg$name,
    n_runs = cfg$n_runs,
    n_years = cfg$n_years,
    init_fun = init_fun,
    survival_fun = survival_fun,
    breeding_prob_fun = breeding_prob_fun,
    fecundity_lambda_fun = fecundity_lambda_fun,
    density_spec = .build_density_spec_from_yaml(cfg$density %||% NULL),
    harvest_quota = management$harvest_quota %||% NULL,
    lifecycle_steps = unlist(cfg$lifecycle_steps %||% default_lifecycle_steps()),
    mating_fun = mating_fun,
    require_mate = cfg$require_mate %||% FALSE,
    inherit_fun = inherit_fun,
    dispersal_fun = dispersal_fun,
    supplement_quota = management$supplement_quota %||% NULL,
    supplement_patch = management$supplement_patch %||% NULL,
    env_surv_sd = cfg$env_surv_sd %||% 0,
    cat_surv_prob = cfg$cat_surv_prob %||% 0,
    cat_surv_mult = cfg$cat_surv_mult %||% 1,
    env_repro_p_sd = reproduction_ev$env_repro_p_sd %||% 0,
    env_repro_lambda_sd = reproduction_ev$env_repro_lambda_sd %||% 0,
    cat_repro_prob = reproduction_ev$cat_repro_prob %||% 0,
    cat_repro_mult = reproduction_ev$cat_repro_mult %||% 1,
    record_population_history = cfg$record_population_history %||% FALSE,
    seed = cfg$seed %||% NULL,
    uncertainty_spec = .parse_uncertainty_yaml(cfg$uncertainty %||% NULL)
  )
  attr(scenario, "yaml_schema_version") <- 3L
  scenario
}
