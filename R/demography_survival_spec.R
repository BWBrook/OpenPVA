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

  if (nrow(tbl) == 0L) {
    stop(table_label, " table must contain at least one row", call. = FALSE)
  }
  if (!is.numeric(tbl$age_min) || !is.numeric(tbl$age_max)) {
    stop("age_min and age_max must be numeric", call. = FALSE)
  }
  if (any(!is.finite(tbl$age_min) | is.na(tbl$age_max) | tbl$age_max == -Inf)) {
    stop("age_min and age_max must be numeric and non-missing", call. = FALSE)
  }
  if (any(tbl$age_min < 0 | tbl$age_min > tbl$age_max)) {
    stop("age ranges must be non-negative with age_min <= age_max", call. = FALSE)
  }

  if (!is.character(tbl$sex)) {
    stop("sex must be character", call. = FALSE)
  }
  if (any(is.na(tbl$sex) | tbl$sex == "")) {
    stop("sex must be non-missing character values", call. = FALSE)
  }

  tbl
}

.assert_non_overlapping_by_sex <- function(tbl, table_label) {
  for (sex_level in unique(tbl$sex)) {
    tbl_sex <- tbl[tbl$sex == sex_level, , drop = FALSE]
    tbl_sex <- tbl_sex[order(tbl_sex$age_min), , drop = FALSE]
    if (nrow(tbl_sex) <= 1L) {
      next
    }
    previous_max <- tbl_sex$age_max[[1L]]
    for (index in seq.int(2L, nrow(tbl_sex))) {
      if (tbl_sex$age_min[[index]] <= previous_max) {
        stop(
          "Overlapping age ranges detected for sex '", sex_level,
          "' in ", table_label, " table",
          call. = FALSE
        )
      }
      previous_max <- tbl_sex$age_max[[index]]
    }
  }
}

.split_age_sex_table <- function(tbl) {
  lapply(split(tbl, tbl$sex), function(rows) {
    rows[order(rows$age_min), , drop = FALSE]
  })
}

.lookup_age_sex_value <- function(tbl_split, individual, value_col, table_label) {
  if (!is.list(individual)) {
    stop("individual must be a list", call. = FALSE)
  }

  sex <- individual$sex
  if (!is.character(sex) || length(sex) != 1L || is.na(sex) || !nzchar(sex)) {
    stop("individual$sex must be one non-missing character value", call. = FALSE)
  }

  age <- individual$age
  if (!is.numeric(age) || length(age) != 1L || !is.finite(age) || age < 0) {
    stop("individual$age must be one finite non-negative number", call. = FALSE)
  }

  table_for_sex <- tbl_split[[sex]]
  if (is.null(table_for_sex) || nrow(table_for_sex) == 0L) {
    stop("No ", table_label, " rows found for sex '", sex, "'", call. = FALSE)
  }

  matches <- table_for_sex[
    table_for_sex$age_min <= age & age <= table_for_sex$age_max,
    ,
    drop = FALSE
  ]
  if (nrow(matches) == 0L) {
    stop(
      "No ", table_label, " row matches age ", age,
      " for sex '", sex, "'",
      call. = FALSE
    )
  }
  if (nrow(matches) > 1L) {
    stop(
      "Multiple ", table_label, " rows match age ", age,
      " for sex '", sex, "'",
      call. = FALSE
    )
  }

  matches[[value_col]][[1L]]
}

#' Validate a survival table specification
#'
#' Checks that a data frame describing age- and sex-specific survival
#' probabilities is well formed and non-overlapping.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and `p_surv`.
#'
#' @return Invisibly returns the validated table; stops with an informative
#'   error if the input is invalid.
#' @export
validate_survival_table <- function(tbl) {
  tbl <- .validate_age_sex_table_core(
    tbl = tbl,
    required_cols = c("age_min", "age_max", "sex", "p_surv"),
    table_label = "survival"
  )

  if (!is.numeric(tbl$p_surv) || any(is.na(tbl$p_surv))) {
    stop("p_surv must be numeric and non-missing", call. = FALSE)
  }
  if (any(tbl$p_surv < 0 | tbl$p_surv > 1)) {
    stop("p_surv must lie within [0, 1]", call. = FALSE)
  }

  .assert_non_overlapping_by_sex(tbl, "survival")

  invisible(tbl)
}

#' Build a survival function from a table specification
#'
#' Converts an age- and sex-specific survival table into a function that can be
#' used inside a modeller-supplied process callback. Every individual must
#' match exactly one row; the package does not extrapolate or choose a default.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and `p_surv`.
#'   See `validate_survival_table()` for requirements.
#'
#' @return A function with signature `function(ind)` that returns a survival
#'   probability for an individual.
#' @export
build_survival_fun_from_table <- function(tbl) {
  tbl_validated <- validate_survival_table(tbl)
  tbl_split <- .split_age_sex_table(tbl_validated)

  function(individual) {
    .lookup_age_sex_value(
      tbl_split = tbl_split,
      individual = individual,
      value_col = "p_surv",
      table_label = "survival"
    )
  }
}
