validate_age_sex_table <- function(table, value) {
  if (!is.data.frame(table) || !.is_name(value) ||
      !all(c("age_min", "age_max", "sex", value) %in% names(table))) {
    .stop("table must be a data frame with age_min, age_max, sex and the value column")
  }
  if (!nrow(table)) {
    .stop("table must have at least one row")
  }
  if (!is.numeric(table$age_min) || !is.numeric(table$age_max) ||
      anyNA(table$age_min) || anyNA(table$age_max) ||
      any(table$age_min < 0) || any(table$age_min != floor(table$age_min)) ||
      any(is.finite(table$age_max) & table$age_max != floor(table$age_max)) ||
      any(table$age_max < table$age_min)) {
    .stop("age_min and age_max must be whole, non-negative and ordered (age_max may be Inf)")
  }
  if (!all(table$sex %in% c("F", "M"))) {
    .stop("sex must be 'F' or 'M'")
  }
  if (!is.numeric(table[[value]]) || anyNA(table[[value]])) {
    .stop(value, " must be non-missing numeric")
  }
  for (sex in unique(table$sex)) {
    rows <- table[table$sex == sex, , drop = FALSE]
    rows <- rows[order(rows$age_min), , drop = FALSE]
    if (nrow(rows) > 1L &&
        any(rows$age_min[-1L] <= rows$age_max[-nrow(rows)])) {
      .stop("age classes overlap for sex ", sex)
    }
  }
  invisible(table)
}

age_sex_rate <- function(table, value) {
  validate_age_sex_table(table, value)
  lookup <- lapply(split(table, as.character(table$sex)), function(rows) {
    rows <- rows[order(rows$age_min), , drop = FALSE]
    list(
      age_min = as.numeric(rows$age_min),
      age_max = as.numeric(rows$age_max),
      value = as.numeric(rows[[value]])
    )
  })
  function(pop, state, context, params) {
    out <- numeric(length(pop$id))
    for (sex in names(lookup)) {
      rows <- which(pop$sex == sex)
      if (!length(rows)) {
        next
      }
      classes <- lookup[[sex]]
      class <- findInterval(pop$age[rows], classes$age_min)
      covered <- class > 0L
      covered[covered] <- pop$age[rows][covered] <= classes$age_max[class[covered]]
      if (!all(covered)) {
        missing <- rows[which(!covered)[[1L]]]
        .stop("no ", value, " class covers sex ", sex, " at age ", pop$age[[missing]])
      }
      out[rows] <- classes$value[class]
    }
    out
  }
}
