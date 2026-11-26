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

# Tabular kinship recurrence using only the founder matrix and planned parents.
kinship_oracle <- function(founders, mother, father) {
  n <- nrow(founders)
  total <- n + length(mother)
  K <- matrix(0, total, total)
  K[seq_len(n), seq_len(n)] <- founders
  for (i in seq_along(mother)) {
    child <- n + i
    prior <- seq_len(child - 1L)
    m <- mother[i]
    f <- father[i]
    K[child, prior] <- K[prior, child] <- 0.5 * (K[m, prior] + K[f, prior])
    K[child, child] <- 0.5 * (1 + K[m, f])
  }
  K
}

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

  # The other groups have identical pedigrees and zero between-group kinship.
  group <- 20L
  generation <- rep(seq_len(generations) - 1L, each = group)
  pair <- rep((seq_len(group) - 1L) %/% 2L, generations)
  mother <- generation * group + 2L * pair + 1L
  father <- generation * group + 2L * ((pair + generation) %% 10L) + 2L
  K <- kinship_oracle(diag(0.5, group), mother, father)
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

# The first litter fills the dense store. These siblings breed across the
# limit, and their offspring breed after removal of the original founders.
n <- 1998L
relatives <- c(seq_len(19L), n)
founders <- matrix(0, n, n)
founders[relatives, relatives] <- 0.125
diag(founders) <- 0.5
founders[1L, 1L] <- 0.625
parents <- rbind(c(1L, n), n + 1:2, n + 3:4)
K <- kinship_oracle(founders, rep(parents[, 1L], each = 2L), rep(parents[, 2L], each = 2L))
initial <- pva_state(pva_population(rep(c("F", "M"), n / 2L), 1L), pedigree = TRUE,
                     kinship = founders)
stopifnot(initial$max_dense_kinship == 2000L, is.matrix(initial$kinship))
retire <- removal_process(select = function(pop, state, context, params) {
  context$time == 2L & pop$age > 0L
})
litter <- pva_process(
  "litter", function(state, context, params) {
    pair <- params$parents[context$time + 1L, ]
    if (context$time == 1L) stopifnot(identical(state$kinship$pending$id, pair))
    state <- add_individuals(state, c("F", "M"), 0L, mother_id = pair[1L], father_id = pair[2L])
    pva_result(state, pva_events("birth", 2L))
  }, params = list(parents = parents), creates = c("age", "sex")
)
observe <- census_process(function(pop, state, context, params) {
  g <- context$time + 1L
  ids <- if (g == 3L) n + seq_len(2L * g) else seq_len(n + 2L * g)
  stopifnot(identical(pop$id, ids), is.null(state$kinship$values) == (g > 1L))
  expected <- K[ids, ids, drop = FALSE]
  c(n_alive = length(ids), max_F = max(pop$pedigree_F),
    kinship_error = max(abs(kinship_matrix(state) - expected)),
    F_error = max(abs(pop$pedigree_F - (2 * diag(expected) - 1))),
    mean_kinship_error = abs(summarise_pedigree(state)$mean_kinship - mean(expected)))
})
crossing <- scenario_spec("related founders", 1L, 3L, function() initial,
                          list(retire, litter, observe), seed = 1L)
elapsed <- system.time(census <- run_scenario(crossing, keep = "census")$census)[["elapsed"]]
errors <- vapply(census[c("kinship_error", "F_error", "mean_kinship_error")], max, numeric(1))
stopifnot(nrow(census) == 3L, all(errors < 1e-13))
cat(sprintf(paste0("N=%d related_founders=%d dense_living=%d traced_living=%d final_living=%d ",
                   "max_F=%.8f verification_s=%.3f ",
                   "kinship_error=%.17g F_error=%.17g mean_kinship_error=%.17g\n"),
            n, length(relatives), census$n_alive[1L], census$n_alive[2L], census$n_alive[3L],
            max(census$max_F), elapsed, errors[1L], errors[2L], errors[3L]))
