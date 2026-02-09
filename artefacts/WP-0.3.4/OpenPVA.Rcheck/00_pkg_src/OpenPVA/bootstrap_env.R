# bootstrap_env.R

if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")

required_pkgs <- c(
  "pak",
  "targets", "here",
  "dplyr", "tibble", "purrr", "ggplot2", "rlang",
  "readr", "stringr", "testthat", "lintr",
  "yaml"
)

renv::init(bare = TRUE) |> invisible()
lib_status <- renv::status()
installed <- names(lib_status$library$Packages)
if (is.null(installed)) installed <- character()
missing <- setdiff(required_pkgs, installed)

if (length(missing)) pak::pkg_install(missing, ask = FALSE)

renv::snapshot()
