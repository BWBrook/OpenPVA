#' Default lifecycle steps
#'
#' Provides the default order of lifecycle processes applied within
#' `run_basic_simulation()`.
#'
#' @return Character vector describing the lifecycle order.
#' @export
default_lifecycle_steps <- function() {
  c("age", "survival", "breeding_births", "harvest")
}

.validate_lifecycle_steps <- function(steps) {
  allowed <- c("age", "survival", "dispersal", "breeding_births", "harvest")
  if (!is.character(steps) || !length(steps)) {
    stop("lifecycle_steps must be a non-empty character vector")
  }
  if (any(is.na(steps))) {
    stop("lifecycle_steps cannot contain NA values")
  }
  invalid <- unique(steps[!steps %in% allowed])
  if (length(invalid)) {
    stop("Invalid lifecycle steps: ", paste(invalid, collapse = ", "))
  }
  invisible(steps)
}
