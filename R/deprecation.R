.openpva_deprecation_state <- new.env(parent = emptyenv())
.openpva_deprecation_state$seen <- character()

.deprecation_warnings_enabled <- function() {
  isTRUE(getOption("openpva.deprecation_warnings", TRUE))
}

.soft_deprecate_once <- function(id, message) {
  if (!.deprecation_warnings_enabled()) {
    return(invisible(FALSE))
  }
  id <- as.character(id)
  message <- as.character(message)
  if (length(id) != 1L || !nzchar(id)) {
    stop("id must be a single non-empty string", call. = FALSE)
  }
  if (length(message) != 1L || !nzchar(message)) {
    stop("message must be a single non-empty string", call. = FALSE)
  }

  seen <- .openpva_deprecation_state$seen
  if (id %in% seen) {
    return(invisible(FALSE))
  }
  .openpva_deprecation_state$seen <- c(seen, id)

  warning(
    message,
    call. = FALSE,
    immediate. = TRUE
  )
  invisible(TRUE)
}

.reset_deprecation_registry <- function() {
  .openpva_deprecation_state$seen <- character()
  invisible(TRUE)
}
