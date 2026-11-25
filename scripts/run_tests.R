#!/usr/bin/env Rscript
# Install the working tree into a temporary library and run the full test
# suite against the installed package (so PSOCK workers load the same code).
# Usage: Rscript scripts/run_tests.R [reporter]
args <- commandArgs(trailingOnly = TRUE)
library_dir <- file.path(tempdir(), "openpva-lib")
dir.create(library_dir, showWarnings = FALSE)
status <- system2(
  file.path(R.home("bin"), "R"),
  c("CMD", "INSTALL", "--no-docs", shQuote(paste0("--library=", library_dir)), "."),
  stdout = "", stderr = ""
)
if (status != 0L) {
  stop("installation failed", call. = FALSE)
}
.libPaths(c(library_dir, .libPaths()))
library(OpenPVA)
results <- testthat::test_dir(
  "tests/testthat",
  package = "OpenPVA",
  load_package = "installed",
  reporter = if (length(args)) args[[1L]] else "summary",
  stop_on_failure = FALSE
)
table <- as.data.frame(results)
cat(sprintf(
  "\nassertions: %d passed, %d failed, %d skipped, %d warnings, %d errors; %.1f s\n",
  sum(table$passed), sum(table$failed), sum(table$skipped), sum(table$warning),
  sum(table$error), sum(table$real)
))
if (any(table$failed | table$error | table$warning | table$skipped)) {
  quit(status = 1L)
}
