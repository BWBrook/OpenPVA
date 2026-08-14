# Declare the data pronoun used inside dplyr expressions for R CMD check.
utils::globalVariables(c(".data"))

`%||%` <- function(a, b) {
  if (!is.null(a)) {
    return(a)
  }
  b
}
