.validate_age_sex_table_core <- function(tbl, required_cols, table_label) {
  if (!is.data.frame(tbl)) {
    stop("tbl must be a data.frame", call. = FALSE)
  }

  missing_cols <- setdiff(required_cols, names(tbl))
  if (length(missing_cols)) {
    stop(
      table_label, " table is missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  tbl$age_min <- as.numeric(tbl$age_min)
  tbl$age_max <- as.numeric(tbl$age_max)
  if (any(is.na(tbl$age_min) | is.na(tbl$age_max))) {
    stop("age_min and age_max must be numeric and non-missing", call. = FALSE)
  }
  if (any(tbl$age_min > tbl$age_max)) {
    stop("age_min cannot exceed age_max", call. = FALSE)
  }

  tbl$sex <- as.character(tbl$sex)
  if (any(is.na(tbl$sex) | tbl$sex == "")) {
    stop("sex must be non-missing character values", call. = FALSE)
  }

  tbl
}

.assert_non_overlapping_by_sex <- function(tbl, table_label) {
  for (sex_level in unique(tbl$sex)) {
    tbl_sex <- tbl[tbl$sex == sex_level, , drop = FALSE]
    tbl_sex <- tbl_sex[order(tbl_sex$age_min), , drop = FALSE]
    if (nrow(tbl_sex) <= 1) {
      next
    }
    prev_max <- tbl_sex$age_max[1]
    for (idx in seq(2, nrow(tbl_sex))) {
      if (tbl_sex$age_min[idx] <= prev_max) {
        stop(
          "Overlapping age ranges detected for sex '", sex_level,
          "' in ", table_label, " table",
          call. = FALSE
        )
      }
      prev_max <- tbl_sex$age_max[idx]
    }
  }
}

.split_age_sex_table <- function(tbl) {
  lapply(split(tbl, tbl$sex), function(x) x[order(x$age_min), , drop = FALSE])
}

.lookup_age_sex_value <- function(tbl_split, ind, value_col, default_value, table_label) {
  sex_chr <- as.character(ind$sex)
  age_num <- suppressWarnings(as.numeric(ind$age))
  if (length(sex_chr) != 1L || is.na(sex_chr) || identical(sex_chr, "")) {
    return(default_value)
  }
  if (length(age_num) != 1L || is.na(age_num)) {
    return(default_value)
  }

  tbl_sex <- tbl_split[[sex_chr]]
  if (is.null(tbl_sex) || nrow(tbl_sex) == 0L) {
    return(default_value)
  }

  matches <- tbl_sex[
    tbl_sex$age_min <= age_num & age_num <= tbl_sex$age_max,
    ,
    drop = FALSE
  ]
  if (nrow(matches) > 1L) {
    stop(
      "Multiple ", table_label, " rows match age ", age_num,
      " for sex '", sex_chr, "'",
      call. = FALSE
    )
  }
  if (nrow(matches) == 0L) {
    return(default_value)
  }
  matches[[value_col]][[1L]]
}

#' Validate a breeding probability table
#'
#' Checks that an age- and sex-specific breeding probability table is complete,
#' non-overlapping, and bounded within `[0, 1]`.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and
#'   `p_breed`.
#'
#' @return Invisibly returns the validated table with `p_breed` coerced to
#'   numeric.
#' @export
validate_breeding_prob_table <- function(tbl) {
  tbl <- .validate_age_sex_table_core(
    tbl = tbl,
    required_cols = c("age_min", "age_max", "sex", "p_breed"),
    table_label = "breeding probability"
  )

  tbl$p_breed <- as.numeric(tbl$p_breed)
  if (any(is.na(tbl$p_breed))) {
    stop("p_breed must be numeric and non-missing", call. = FALSE)
  }
  if (any(tbl$p_breed < 0 | tbl$p_breed > 1)) {
    stop("p_breed values must lie within [0, 1]", call. = FALSE)
  }

  .assert_non_overlapping_by_sex(tbl, "breeding probability")
  invisible(tbl)
}

#' Validate a breeding eligibility table
#'
#' Legacy validation wrapper for breeding eligibility tables with `can_breed`.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and
#'   `can_breed` (logical or numeric treated as 0/1).
#'
#' @return Invisibly returns the validated table with `can_breed` coerced to
#'   logical.
#' @export
validate_breeding_table <- function(tbl) {
  .soft_deprecate_once(
    "validate_breeding_table",
    paste(
      "`validate_breeding_table()` is soft-deprecated for OpenPVA 2.0.",
      "Use `validate_breeding_prob_table()` with a `p_breed` column instead."
    )
  )

  tbl <- .validate_age_sex_table_core(
    tbl = tbl,
    required_cols = c("age_min", "age_max", "sex", "can_breed"),
    table_label = "breeding"
  )

  cb <- tbl$can_breed
  if (is.logical(cb)) {
    tbl$can_breed <- cb
  } else if (is.numeric(cb)) {
    tbl$can_breed <- cb != 0
  } else {
    stop("can_breed must be logical or numeric (0/1)", call. = FALSE)
  }
  if (any(is.na(tbl$can_breed))) {
    stop("can_breed must be non-missing", call. = FALSE)
  }

  .assert_non_overlapping_by_sex(tbl, "breeding")
  invisible(tbl)
}

#' Create the default breeding probability table
#'
#' Returns the baseline breeding schedule as an explicit probability table.
#'
#' @return A data frame with columns `age_min`, `age_max`, `sex`, and
#'   `p_breed`.
#' @export
make_default_breeding_prob_table <- function() {
  tbl <- tibble::tibble(
    age_min = c(0, 4, 0, 4),
    age_max = c(3, Inf, 3, Inf),
    sex = c("F", "F", "M", "M"),
    p_breed = c(0, 1, 0, 1)
  )
  validate_breeding_prob_table(tbl)
  tbl
}

#' Create the default breeding eligibility table
#'
#' Legacy compatibility wrapper that maps default breeding probabilities to
#' `can_breed`.
#'
#' @return A data frame with columns `age_min`, `age_max`, `sex`, and
#'   `can_breed`.
#' @export
make_default_breeding_table <- function() {
  .soft_deprecate_once(
    "make_default_breeding_table",
    paste(
      "`make_default_breeding_table()` is soft-deprecated for OpenPVA 2.0.",
      "Use `make_default_breeding_prob_table()` instead."
    )
  )

  prob_tbl <- make_default_breeding_prob_table()
  tbl <- dplyr::transmute(
    prob_tbl,
    age_min = .data$age_min,
    age_max = .data$age_max,
    sex = .data$sex,
    can_breed = .data$p_breed > 0
  )
  validate_breeding_table(tbl)
  tbl
}

#' Build a breeding probability function from a table specification
#'
#' Converts an age- and sex-specific breeding probability table into a function
#' returning `p_breed` in `[0, 1]`.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and
#'   `p_breed`. See `validate_breeding_prob_table()`.
#'
#' @return A function with signature `function(ind)` returning baseline
#'   breeding probability in `[0, 1]`.
#' @export
build_breeding_prob_fun_from_table <- function(tbl) {
  tbl_validated <- validate_breeding_prob_table(tbl)
  tbl_split <- .split_age_sex_table(tbl_validated)

  function(ind) {
    .lookup_age_sex_value(
      tbl_split = tbl_split,
      ind = ind,
      value_col = "p_breed",
      default_value = 0,
      table_label = "breeding probability"
    )
  }
}

#' Adapt a breeding probability function to a legacy eligibility function
#'
#' Converts a `p_breed` function into a logical breeding eligibility function.
#'
#' @param breeding_prob_fun Function with signature `function(ind)` returning a
#'   numeric probability in `[0, 1]`.
#'
#' @return A function with signature `function(ind)` returning `TRUE` when
#'   `p_breed > 0`, else `FALSE`.
#' @export
as_breeding_fun <- function(breeding_prob_fun) {
  if (!is.function(breeding_prob_fun)) {
    stop("breeding_prob_fun must be a function", call. = FALSE)
  }

  function(ind) {
    p <- breeding_prob_fun(ind)
    if (!is.numeric(p) || length(p) != 1L || is.na(p) || p < 0 || p > 1) {
      stop("breeding_prob_fun must return a single numeric value in [0, 1]", call. = FALSE)
    }
    p > 0
  }
}

#' Adapt a legacy breeding function to a breeding probability function
#'
#' Wraps legacy `breeding_fun` semantics as numeric `p_breed` output.
#'
#' @param breeding_fun Function with signature `function(ind)` returning logical
#'   eligibility (or numeric probabilities in `[0, 1]`).
#'
#' @return A function with signature `function(ind)` returning `p_breed` in
#'   `[0, 1]`.
#' @export
as_breeding_prob_fun <- function(breeding_fun) {
  if (!is.function(breeding_fun)) {
    stop("breeding_fun must be a function", call. = FALSE)
  }

  function(ind) {
    out <- breeding_fun(ind)
    if (is.logical(out)) {
      if (length(out) != 1L || is.na(out)) {
        stop("breeding_fun must return a single non-missing logical value", call. = FALSE)
      }
      return(as.numeric(out))
    }

    out <- as.numeric(out)
    if (length(out) != 1L || is.na(out) || out < 0 || out > 1) {
      stop("breeding_fun adaptation requires outputs in [0, 1] or logical", call. = FALSE)
    }
    out
  }
}

#' Build a breeding function from a table specification
#'
#' Legacy compatibility wrapper that maps `can_breed` to `p_breed` and returns
#' logical breeding eligibility.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and
#'   `can_breed`. See `validate_breeding_table()` for requirements.
#'
#' @return A function with signature `function(ind)` returning `TRUE`/`FALSE`.
#' @export
build_breeding_fun_from_table <- function(tbl) {
  .soft_deprecate_once(
    "build_breeding_fun_from_table",
    paste(
      "`build_breeding_fun_from_table()` is soft-deprecated for OpenPVA 2.0.",
      "Use `build_breeding_prob_fun_from_table()` (and adapt only when needed)."
    )
  )

  tbl_validated <- validate_breeding_table(tbl)
  prob_tbl <- dplyr::transmute(
    tbl_validated,
    age_min = .data$age_min,
    age_max = .data$age_max,
    sex = .data$sex,
    p_breed = as.numeric(.data$can_breed)
  )
  prob_fun <- build_breeding_prob_fun_from_table(prob_tbl)
  as_breeding_fun(prob_fun)
}

#' Validate a fecundity lambda table
#'
#' Checks that an age- and sex-specific fecundity-lambda table is complete and
#' non-overlapping.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and `lambda`
#'   (mean offspring count).
#'
#' @return Invisibly returns the validated table.
#' @export
validate_fecundity_lambda_table <- function(tbl) {
  tbl <- .validate_age_sex_table_core(
    tbl = tbl,
    required_cols = c("age_min", "age_max", "sex", "lambda"),
    table_label = "fecundity lambda"
  )

  tbl$lambda <- as.numeric(tbl$lambda)
  if (any(is.na(tbl$lambda))) {
    stop("lambda must be numeric and non-missing", call. = FALSE)
  }
  if (any(tbl$lambda < 0)) {
    stop("lambda must be non-negative", call. = FALSE)
  }

  .assert_non_overlapping_by_sex(tbl, "fecundity lambda")
  invisible(tbl)
}

#' Validate a fecundity table
#'
#' Legacy compatibility wrapper for fecundity tables with `lambda`.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and `lambda`.
#'
#' @return Invisibly returns the validated table.
#' @export
validate_fecundity_table <- function(tbl) {
  .soft_deprecate_once(
    "validate_fecundity_table",
    paste(
      "`validate_fecundity_table()` is soft-deprecated for OpenPVA 2.0.",
      "Use `validate_fecundity_lambda_table()` instead."
    )
  )

  validate_fecundity_lambda_table(tbl)
}

#' Create the default fecundity lambda table
#'
#' Returns an explicit baseline fecundity-lambda schedule.
#'
#' @return A data frame with columns `age_min`, `age_max`, `sex`, and `lambda`.
#' @export
make_default_fecundity_lambda_table <- function() {
  tbl <- tibble::tibble(
    age_min = c(0, 0),
    age_max = c(Inf, Inf),
    sex = c("F", "M"),
    lambda = c(1.5, 0)
  )
  validate_fecundity_lambda_table(tbl)
  tbl
}

#' Build a fecundity lambda function from a table specification
#'
#' Converts an age- and sex-specific fecundity table into a function returning
#' baseline `lambda` values.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and
#'   `lambda`. See `validate_fecundity_lambda_table()`.
#'
#' @return A function with signature `function(ind)` returning non-negative
#'   `lambda`, defaulting to `0` when no row matches.
#' @export
build_fecundity_lambda_fun_from_table <- function(tbl) {
  tbl_validated <- validate_fecundity_lambda_table(tbl)
  tbl_split <- .split_age_sex_table(tbl_validated)

  function(ind) {
    .lookup_age_sex_value(
      tbl_split = tbl_split,
      ind = ind,
      value_col = "lambda",
      default_value = 0,
      table_label = "fecundity lambda"
    )
  }
}

#' Adapt a fecundity lambda function to a legacy realised-count fecundity function
#'
#' Converts baseline `lambda` output to realized counts via `Poisson(lambda)`.
#'
#' @param fecundity_lambda_fun Function with signature `function(ind)` returning
#'   non-negative lambda.
#'
#' @return A function with signature `function(ind)` returning non-negative
#'   integer offspring counts.
#' @export
as_fecundity_fun <- function(fecundity_lambda_fun) {
  if (!is.function(fecundity_lambda_fun)) {
    stop("fecundity_lambda_fun must be a function", call. = FALSE)
  }

  function(ind) {
    lambda <- fecundity_lambda_fun(ind)
    if (!is.numeric(lambda) || length(lambda) != 1L || is.na(lambda) || lambda < 0) {
      stop("fecundity_lambda_fun must return a single non-negative numeric value", call. = FALSE)
    }
    stats::rpois(1L, lambda)
  }
}

#' Adapt a legacy realised-count fecundity function to a lambda function
#'
#' Wraps legacy fecundity functions as non-negative numeric outputs. If the
#' legacy function is stochastic, the adapted lambda inherits that stochasticity.
#'
#' @param fecundity_fun Function with signature `function(ind)` returning a
#'   non-negative scalar count.
#'
#' @return A function with signature `function(ind)` returning non-negative
#'   numeric values.
#' @export
as_fecundity_lambda_fun <- function(fecundity_fun) {
  if (!is.function(fecundity_fun)) {
    stop("fecundity_fun must be a function", call. = FALSE)
  }

  function(ind) {
    out <- fecundity_fun(ind)
    out <- as.numeric(out)
    if (length(out) != 1L || is.na(out) || out < 0) {
      stop("fecundity_fun adaptation requires a single non-negative numeric value", call. = FALSE)
    }
    out
  }
}

#' Build a fecundity function from a table specification
#'
#' Legacy compatibility wrapper that returns realized counts from a `lambda`
#' table via `Poisson(lambda)` draws.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and
#'   `lambda`. See `validate_fecundity_table()` for requirements.
#'
#' @return A function with signature `function(ind)` returning non-negative
#'   integer offspring counts.
#' @export
build_fecundity_fun_from_table <- function(tbl) {
  .soft_deprecate_once(
    "build_fecundity_fun_from_table",
    paste(
      "`build_fecundity_fun_from_table()` is soft-deprecated for OpenPVA 2.0.",
      "Use `build_fecundity_lambda_fun_from_table()` (and adapt only when needed)."
    )
  )

  lambda_fun <- build_fecundity_lambda_fun_from_table(tbl)
  as_fecundity_fun(lambda_fun)
}
