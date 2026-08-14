#' Validate a breeding probability table
#'
#' Checks that an age- and sex-specific breeding probability table is well formed,
#' non-overlapping, and bounded within `[0, 1]`.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and
#'   `p_breed`.
#'
#' @return Invisibly returns the validated table.
#' @export
validate_breeding_prob_table <- function(tbl) {
  tbl <- .validate_age_sex_table_core(
    tbl = tbl,
    required_cols = c("age_min", "age_max", "sex", "p_breed"),
    table_label = "breeding probability"
  )

  if (!is.numeric(tbl$p_breed) || any(is.na(tbl$p_breed))) {
    stop("p_breed must be numeric and non-missing", call. = FALSE)
  }
  if (any(tbl$p_breed < 0 | tbl$p_breed > 1)) {
    stop("p_breed values must lie within [0, 1]", call. = FALSE)
  }

  .assert_non_overlapping_by_sex(tbl, "breeding probability")
  invisible(tbl)
}

#' Build a breeding probability function from a table specification
#'
#' Converts an age- and sex-specific breeding probability table into a function
#' returning `p_breed` in `[0, 1]`. Every individual must match exactly one
#' row; the package does not choose a default.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and
#'   `p_breed`. See `validate_breeding_prob_table()`.
#'
#' @return A function with signature `function(ind)` returning breeding
#'   probability in `[0, 1]`.
#' @export
build_breeding_prob_fun_from_table <- function(tbl) {
  tbl_validated <- validate_breeding_prob_table(tbl)
  tbl_split <- .split_age_sex_table(tbl_validated)

  function(ind) {
    .lookup_age_sex_value(
      tbl_split = tbl_split,
      individual = ind,
      value_col = "p_breed",
      table_label = "breeding probability"
    )
  }
}

#' Validate a fecundity lambda table
#'
#' Checks that an age- and sex-specific fecundity-lambda table is well formed and
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

  if (!is.numeric(tbl$lambda) || any(!is.finite(tbl$lambda))) {
    stop("lambda must be numeric, finite, and non-missing", call. = FALSE)
  }
  if (any(tbl$lambda < 0)) {
    stop("lambda must be non-negative", call. = FALSE)
  }

  .assert_non_overlapping_by_sex(tbl, "fecundity lambda")
  invisible(tbl)
}

#' Build a fecundity lambda function from a table specification
#'
#' Converts an age- and sex-specific fecundity table into a function returning
#' `lambda` values. Every individual must match exactly one row; the package
#' does not choose a default.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and
#'   `lambda`. See `validate_fecundity_lambda_table()`.
#'
#' @return A function with signature `function(ind)` returning non-negative
#'   `lambda`.
#' @export
build_fecundity_lambda_fun_from_table <- function(tbl) {
  tbl_validated <- validate_fecundity_lambda_table(tbl)
  tbl_split <- .split_age_sex_table(tbl_validated)

  function(ind) {
    .lookup_age_sex_value(
      tbl_split = tbl_split,
      individual = ind,
      value_col = "lambda",
      table_label = "fecundity lambda"
    )
  }
}
