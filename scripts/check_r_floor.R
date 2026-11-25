#!/usr/bin/env Rscript
# Run with R 4.1.0: Rscript --vanilla scripts/check_r_floor.R <private library>
args <- commandArgs(trailingOnly = TRUE)
stopifnot(getRversion() == "4.1.0", length(args) == 1L)
private_lib <- normalizePath(args[[1L]], mustWork = TRUE)
.libPaths(c(private_lib, .libPaths()))
library(OpenPVA, lib.loc = private_lib)
cat(R.version.string, "\nOpenPVA", as.character(packageVersion("OpenPVA")), "\n")

floor_population <- function() pva_state(pva_population(rep(c("F", "M"), 4L), 2L),
                                         pedigree = TRUE)
floor_components <- function(row) {
  list(init_fun = floor_population, n_steps = 4L,
       processes = list(survival_process(row$p), census_process()))
}
design <- data.frame(p = c(0.7, 0.9))
scenario <- do.call(scenario_spec, c(list(name = "floor", n_runs = 4L, seed = 23L),
                                     floor_components(design[1L, , drop = FALSE])))

Sys.unsetenv(c("R_LIBS", "R_LIBS_USER", "R_LIBS_SITE"))
cl <- parallel::makePSOCKcluster(2L, rscript_args = "--vanilla")
tryCatch({
  workers <- parallel::clusterCall(cl, function() {
    list(version = as.character(getRversion()), paths = .libPaths())
  })
  for (worker in workers) {
    stopifnot(identical(worker$version, "4.1.0"), !private_lib %in% worker$paths)
  }
  cat("Both fresh PSOCK workers run R 4.1.0 and start outside the private library.\n")
  set.seed(521L)
  before <- .Random.seed
  serial <- run_scenario(scenario)
  socket <- run_scenario(scenario, parallel = TRUE, cluster = cl)
  loaded <- parallel::clusterCall(cl, function() getNamespaceInfo(asNamespace("OpenPVA"), "path"))
  stopifnot(identical(serial, socket), identical(before, .Random.seed),
            all(unlist(loaded) == find.package("OpenPVA", lib.loc = private_lib)))
  cat("Scenario results match serial and both workers loaded the private installation.\n")
}, finally = parallel::stopCluster(cl))
serial_design <- run_pva_ensemble(design, floor_components, 3L, seed = 37L)
socket_design <- run_pva_ensemble(design, floor_components, 3L, seed = 37L,
                                 workers = 2L, backend = "psock")
stopifnot(identical(serial_design, socket_design), identical(before, .Random.seed))
cat("Ensemble results match serial on a second, internally created PSOCK cluster.\n")
if (.Platform$OS.type != "windows") {
  forked <- run_scenario(scenario, parallel = TRUE, workers = 2L, backend = "fork")
  stopifnot(identical(forked, serial), identical(before, .Random.seed))
  cat("Forked and serial scenarios also agree.\n")
}
cat("All seeded calls restored the caller's RNG.\n")
