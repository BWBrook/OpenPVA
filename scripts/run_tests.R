#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
filter <- if (length(args) > 0 && nzchar(args[[1]])) args[[1]] else NULL

pkgload::load_all(quiet = TRUE)
testthat::test_dir(
  "tests/testthat",
  filter = filter,
  stop_on_failure = TRUE
)
