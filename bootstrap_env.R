# bootstrap_env.R

if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")

import::from("renv", init, install, snapshot, status)

required_pkgs <- c(
  "targets", "import", "here",
  "dplyr", "tibble", "purrr", "ggplot2", "rlang",
  "readr", "stringr", "testthat"
)

init(bare = TRUE) |> invisible()
missing <- setdiff(required_pkgs, status()$library$packages)

if (length(missing)) install(missing)

snapshot()
