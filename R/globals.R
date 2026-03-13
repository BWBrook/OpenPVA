# Declare data pronoun used inside dplyr/ggplot2 expressions to keep R CMD check clean.
utils::globalVariables(c(".data"))

`%||%` <- function(a, b) {
  if (!is.null(a)) {
    return(a)
  }
  b
}
