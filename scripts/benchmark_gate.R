# Charter 3.2 scaling gate: a 40-year, pedigree-enabled Woodhen-scale ensemble
# of 1,000 replicates with strict validation.
# Usage: Rscript scripts/benchmark_gate.R <capacity_pairs> <n_runs> <workers> <backend> <validation>
args <- commandArgs(trailingOnly = TRUE)
capacity <- as.numeric(args[[1L]])
n_runs <- as.integer(args[[2L]])
workers <- as.integer(args[[3L]])
backend <- args[[4L]]
validation <- args[[5L]]
library(OpenPVA)
example_dir <- system.file("examples", "woodhen", package = "OpenPVA")
sys.source(file.path(example_dir, "parameters.R"), envir = globalenv())
sys.source(file.path(example_dir, "model.R"), envir = globalenv())
parameters <- woodhen_parameters()
parameters$scenarios$territory_capacity_pairs[2L] <- capacity
parameters$scenarios$territory_capacity_sd[2L] <- capacity / 10
scenario <- woodhen_build_scenario(
  "pig_control", n_runs = n_runs, seed = 20261124L,
  parameters = parameters, pedigree = TRUE
)
elapsed <- system.time(result <- run_scenario(
  scenario,
  parallel = workers > 1L, workers = workers, backend = backend,
  validation = validation, keep = c("census", "accounting")
))[["elapsed"]]
census <- result$census[result$census$phase == "interval", ]
living <- tapply(census$n_alive, census$time, mean)
accounting <- summarise_accounting(result)
cat(sprintf(
  "%g,%d,%d,%s,%s,%.2f,%.1f,%.1f,%.1f,%s\n",
  capacity, n_runs, workers, backend, validation, elapsed,
  mean(living[as.character(10:39)]), min(living[as.character(10:39)]),
  max(living[as.character(10:39)]), all(accounting$reconciled)
))
