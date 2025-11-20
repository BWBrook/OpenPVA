#' Validate a survival table specification
#'
#' Checks that a data frame describing age- and sex-specific survival
#' probabilities is complete and non-overlapping.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and `p_surv`.
#'
#' @return Invisibly returns the validated table; stops with an informative
#'   error if the input is invalid.
#' @export
validate_survival_table <- function(tbl) {
  if (!is.data.frame(tbl)) {
    stop("tbl must be a data.frame", call. = FALSE)
  }

  required_cols <- c("age_min", "age_max", "sex", "p_surv")
  missing_cols <- setdiff(required_cols, names(tbl))
  if (length(missing_cols)) {
    stop(
      "survival table is missing required columns: ",
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

  tbl$p_surv <- as.numeric(tbl$p_surv)
  if (any(is.na(tbl$p_surv))) {
    stop("p_surv must be numeric and non-missing", call. = FALSE)
  }
  if (any(tbl$p_surv < 0 | tbl$p_surv > 1)) {
    stop("p_surv must lie within [0, 1]", call. = FALSE)
  }

  for (sex_level in unique(tbl$sex)) {
    tbl_sex <- tbl[tbl$sex == sex_level, , drop = FALSE]
    tbl_sex <- tbl_sex[order(tbl_sex$age_min), , drop = FALSE]
    if (nrow(tbl_sex) > 1) {
      prev_max <- tbl_sex$age_max[1]
      for (idx in seq(2, nrow(tbl_sex))) {
        if (tbl_sex$age_min[idx] <= prev_max) {
          stop(
            "Overlapping age ranges detected for sex '", sex_level, "'",
            call. = FALSE
          )
        }
        prev_max <- tbl_sex$age_max[idx]
      }
    }
  }

  invisible(tbl)
}

#' Create the default age- and sex-specific survival table
#'
#' Returns the baseline survival schedule used by `default_survival_fun()`
#' as an explicit table.
#'
#' @return A data frame with columns `age_min`, `age_max`, `sex`, and `p_surv`.
#' @export
make_default_survival_table <- function() {
  tbl <- tibble::tibble(
    age_min = c(0, 1, 5, 0, 1, 5),
    age_max = c(0, 4, Inf, 0, 4, Inf),
    sex = c("F", "F", "F", "M", "M", "M"),
    p_surv = c(0.85, 0.92, 0.70, 0.85, 0.92, 0.70)
  )

  validate_survival_table(tbl)
  tbl
}

#' Build a survival function from a table specification
#'
#' Converts an age- and sex-specific survival table into a function that can be
#' supplied to simulation controllers.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and `p_surv`.
#'   See `validate_survival_table()` for requirements.
#'
#' @return A function with signature `function(ind)` that returns a survival
#'   probability for an individual.
#' @export
build_survival_fun_from_table <- function(tbl) {
  tbl_validated <- validate_survival_table(tbl)
  tbl_sorted <- tbl_validated[order(tbl_validated$sex, tbl_validated$age_min), , drop = FALSE]

  function(ind) {
    sex <- ind$sex
    age <- ind$age

    if (is.null(sex) || is.na(sex) || identical(sex, "")) {
      stop("Individual must have a non-missing sex", call. = FALSE)
    }
    if (is.null(age) || is.na(age)) {
      stop("Individual must have a non-missing age", call. = FALSE)
    }

    sex_chr <- as.character(sex)
    age_num <- as.numeric(age)

    tbl_sex <- tbl_sorted[tbl_sorted$sex == sex_chr, , drop = FALSE]
    if (nrow(tbl_sex) == 0) {
      stop("No survival rows found for sex '", sex_chr, "'", call. = FALSE)
    }

    matches <- tbl_sex[tbl_sex$age_min <= age_num & age_num <= tbl_sex$age_max, , drop = FALSE]
    if (nrow(matches) == 1) {
      return(matches$p_surv[[1]])
    }
    if (nrow(matches) > 1) {
      stop(
        "Multiple survival rows match age ", age_num, " for sex '", sex_chr, "'",
        call. = FALSE
      )
    }

    max_age_max <- max(tbl_sex$age_max)
    fallback <- tbl_sex[tbl_sex$age_max == max_age_max, , drop = FALSE]
    fallback <- fallback[order(fallback$age_min), , drop = FALSE]
    fallback$p_surv[[1]]
  }
}
