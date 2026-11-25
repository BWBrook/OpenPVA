# Rscript --vanilla scripts/benchmark_large_pedigree.R (installed OpenPVA)
library(OpenPVA)

# Two offspring per dam replace the adults. Rotating sires within groups of
# ten pairs gives repeated litters and overlapping, traceable ancestries.
birth <- pva_process(
  "birth", function(state, context, params) {
    pop <- state$population
    dams <- which(pop$sex == "F")
    males <- which(pop$sex == "M")
    index <- seq_along(dams) - 1L
    sires <- males[10L * (index %/% 10L) + (index + context$time) %% 10L + 1L]
    n <- 2L * length(dams)
    state <- add_individuals(state, rep(c("F", "M"), length(dams)), 0L,
                             mother_id = rep(pop$id[dams], each = 2L),
                             father_id = rep(pop$id[sires], each = 2L))
    pva_result(state, pva_events("birth", n))
  }, creates = c("age", "sex")
)
replace_adults <- removal_process(select = function(pop, state, context, params) pop$age > 0L)
life <- list(birth, replace_adults, age_process())

cat(R.version.string, "| OpenPVA", as.character(packageVersion("OpenPVA")), "\n")
for (n in c(2500L, 5000L)) {
  generations <- 10L
  state <- pva_state(pva_population(rep(c("F", "M"), n / 2L), 1L), pedigree = TRUE)
  elapsed <- system.time({
    for (i in seq_len(generations)) {
      state <- execute_processes(state, life, time = i - 1L)$state
      stopifnot(length(state$population$id) == n)
    }
    summary <- summarise_pedigree(state)
  })[["elapsed"]]

  # Independent relationship recurrence for the first twenty founders and
  # their descendants, using their published ID schedule only.
  group <- 20L
  nodes <- group * (generations + 1L)
  K <- diag(0.5, nodes)
  for (g in seq_len(generations)) {
    parent <- (g - 1L) * group
    for (j in seq_len(group)) {
      pair <- (j - 1L) %/% 2L
      m <- parent + 2L * pair + 1L
      f <- parent + 2L * ((pair + g - 1L) %% 10L) + 2L
      k <- g * group + j
      prior <- seq_len(k - 1L)
      K[k, prior] <- K[prior, k] <- 0.5 * (K[m, prior] + K[f, prior])
      K[k, k] <- 0.5 * (1 + K[m, f])
    }
  }
  expected <- K[generations * group + seq_len(group), generations * group + seq_len(group)]
  ids <- state$population$id[seq_len(group)]
  error <- max(abs(kinship_matrix(state, ids) - expected),
               abs(mean(expected) * group / n - summary$mean_kinship),
               abs(2 * diag(expected) - 1 - state$population$pedigree_F[seq_len(group)]))
  stopifnot(error < 1e-13, summary$max_inbreeding > 0, !is.matrix(state$kinship))
  cat(sprintf(paste0("N=%d peak_living=%d generations=%d ancestry_records=%d ",
                     "state_MiB=%.3f elapsed_s=%.3f max_F=%.8f max_abs_oracle_error=%.17g\n"),
              n, 2L*n, generations, n*(generations+1L), as.numeric(object.size(state))/1024^2,
              elapsed, summary$max_inbreeding, error))
}
