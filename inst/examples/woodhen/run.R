#!/usr/bin/env Rscript

woodhen_script_dir <- function() {
  command <- commandArgs(trailingOnly = FALSE)
  file_arg <- command[grepl("^--file=", command)]
  if (!length(file_arg)) {
    return(normalizePath(getwd(), mustWork = TRUE))
  }
  normalizePath(dirname(sub("^--file=", "", file_arg[[1L]])), mustWork = TRUE)
}

project_dir <- woodhen_script_dir()
sys.source(file.path(project_dir, "parameters.R"), envir = .GlobalEnv)
sys.source(file.path(project_dir, "model.R"), envir = .GlobalEnv)
sys.source(file.path(project_dir, "analyse.R"), envir = .GlobalEnv)

args <- commandArgs(trailingOnly = TRUE)
output_dir <- if (length(args) >= 1L) args[[1L]] else file.path(project_dir, "outputs")
n_runs <- if (length(args) >= 2L) as.integer(args[[2L]]) else NULL
if (!is.null(n_runs) && (is.na(n_runs) || n_runs <= 0L)) {
  stop("n_runs must be a positive integer", call. = FALSE)
}
workers <- if (length(args) >= 3L) {
  as.integer(args[[3L]])
} else if (.Platform$OS.type == "windows") {
  1L
} else {
  2L
}
if (is.na(workers) || workers <= 0L) {
  stop("workers must be a positive integer", call. = FALSE)
}

parameters <- woodhen_parameters()
results <- woodhen_run_all(
  n_runs = n_runs,
  parameters = parameters,
  workers = workers
)
bundle <- woodhen_prepare_bundle(results, parameters)
woodhen_write_bundle(bundle, output_dir)

print(bundle$scenario_summary, row.names = FALSE)
cat("Woodhen evidence written to ", normalizePath(output_dir), "\n", sep = "")
