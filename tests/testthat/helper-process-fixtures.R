make_test_population <- function(n = 6L, patch_id = NULL) {
  lapply(seq_len(n), function(id) {
    create_individual(
      id = id,
      sex = if (id %% 2L) "F" else "M",
      age = as.integer(2L + id %% 3L),
      patch_id = if (is.null(patch_id)) NA_integer_ else as.integer(patch_id)
    )
  })
}
constant_survival_process <- function(probability = 0.8, name = "survival") {
  survival_process(
    probability = function(individual, state, context, params) params$probability,
    name = name,
    params = list(probability = probability)
  )
}

zero_birth_process <- function(name = "reproduction") {
  reproduction_process(
    breeding_probability = function(mother, state, context, params) 0,
    fecundity_mean = function(mother, state, context, params) 0,
    name = name
  )
}
