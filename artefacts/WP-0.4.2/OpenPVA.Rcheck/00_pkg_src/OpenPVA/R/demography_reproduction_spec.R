#' Validate a breeding eligibility table
#'
#' Checks that an age- and sex-specific breeding eligibility table is complete
#' and non-overlapping.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and
#'   `can_breed` (logical or numeric treated as 0/1).
#'
#' @return Invisibly returns the validated table with `can_breed` coerced to
#'   logical. Stops with an informative error if the input is invalid.
#' @export
validate_breeding_table <- function(tbl) {
  if (!is.data.frame(tbl)) {
    stop("tbl must be a data.frame", call. = FALSE)
  }

  required_cols <- c("age_min", "age_max", "sex", "can_breed")
  missing_cols <- setdiff(required_cols, names(tbl))
  if (length(missing_cols)) {
    stop(
      "breeding table is missing required columns: ",
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

#' Validate a fecundity table
#'
#' Checks that an age- and sex-specific fecundity table is complete and
#' non-overlapping.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and `lambda`
#'   (mean offspring per breeder).
#'
#' @return Invisibly returns the validated table. Stops with an informative
#'   error if the input is invalid.
#' @export
validate_fecundity_table <- function(tbl) {
  if (!is.data.frame(tbl)) {
    stop("tbl must be a data.frame", call. = FALSE)
  }

  required_cols <- c("age_min", "age_max", "sex", "lambda")
  missing_cols <- setdiff(required_cols, names(tbl))
  if (length(missing_cols)) {
    stop(
      "fecundity table is missing required columns: ",
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

  tbl$lambda <- as.numeric(tbl$lambda)
  if (any(is.na(tbl$lambda))) {
    stop("lambda must be numeric and non-missing", call. = FALSE)
  }
  if (any(tbl$lambda < 0)) {
    stop("lambda must be non-negative", call. = FALSE)
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

#' Create the default breeding eligibility table
#'
#' Returns the baseline breeding schedule used by `default_breeding_fun()` as
#' an explicit table.
#'
#' @return A data frame with columns `age_min`, `age_max`, `sex`, and
#'   `can_breed`.
#' @export
make_default_breeding_table <- function() {
  tbl <- tibble::tibble(
    age_min = c(0, 4, 0, 4),
    age_max = c(3, Inf, 3, Inf),
    sex = c("F", "F", "M", "M"),
    can_breed = c(FALSE, TRUE, FALSE, TRUE)
  )

  validate_breeding_table(tbl)
  tbl
}

#' Build a breeding function from a table specification
#'
#' Converts an age- and sex-specific breeding table into a function compatible
#' with `determine_breeding()`.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and
#'   `can_breed`. See `validate_breeding_table()` for requirements.
#'
#' @return A function with signature `function(ind)` that returns `TRUE` when a
#'   given individual is eligible to breed, otherwise `FALSE`.
#' @export
build_breeding_fun_from_table <- function(tbl) {
  tbl_validated <- validate_breeding_table(tbl)
  tbl_split <- lapply(split(tbl_validated, tbl_validated$sex), function(x) {
    x[order(x$age_min), , drop = FALSE]
  })

  function(ind) {
    sex_chr <- as.character(ind$sex)
    age_num <- as.numeric(ind$age)

    if (is.null(sex_chr) || is.na(sex_chr) || identical(sex_chr, "")) {
      return(FALSE)
    }
    if (is.null(age_num) || is.na(age_num)) {
      return(FALSE)
    }

    tbl_sex <- tbl_split[[sex_chr]]
    if (is.null(tbl_sex) || nrow(tbl_sex) == 0) {
      return(FALSE)
    }

    matches <- tbl_sex[
      tbl_sex$age_min <= age_num & age_num <= tbl_sex$age_max,
      ,
      drop = FALSE
    ]

    if (nrow(matches) == 1) {
      return(matches$can_breed[[1]])
    }
    if (nrow(matches) > 1) {
      stop(
        "Multiple breeding rows match age ", age_num, " for sex '", sex_chr, "'",
        call. = FALSE
      )
    }

    FALSE
  }
}

#' Build a fecundity function from a table specification
#'
#' Converts an age- and sex-specific fecundity table into a function compatible
#' with `apply_reproduction()`.
#'
#' @param tbl Data frame with columns `age_min`, `age_max`, `sex`, and
#'   `lambda`. See `validate_fecundity_table()` for requirements.
#'
#' @return A function with signature `function(ind)` that returns an integer
#'   number of offspring drawn from `stats::rpois(1, lambda)`. If no matching
#'   row exists for the individual's sex/age, `lambda` defaults to 0 (no
#'   offspring).
#' @export
build_fecundity_fun_from_table <- function(tbl) {
  tbl_validated <- validate_fecundity_table(tbl)
  tbl_split <- lapply(split(tbl_validated, tbl_validated$sex), function(x) {
    x[order(x$age_min), , drop = FALSE]
  })

  function(ind) {
    sex_chr <- as.character(ind$sex)
    age_num <- as.numeric(ind$age)

    if (is.null(sex_chr) || is.na(sex_chr) || identical(sex_chr, "")) {
      return(0L)
    }
    if (is.null(age_num) || is.na(age_num)) {
      return(0L)
    }

    tbl_sex <- tbl_split[[sex_chr]]
    if (is.null(tbl_sex) || nrow(tbl_sex) == 0) {
      return(0L)
    }

    matches <- tbl_sex[
      tbl_sex$age_min <= age_num & age_num <= tbl_sex$age_max,
      ,
      drop = FALSE
    ]

    if (nrow(matches) == 1) {
      lambda <- matches$lambda[[1]]
    } else if (nrow(matches) > 1) {
      stop(
        "Multiple fecundity rows match age ", age_num, " for sex '", sex_chr, "'",
        call. = FALSE
      )
    } else {
      lambda <- 0
    }

    stats::rpois(1L, lambda)
  }
}
