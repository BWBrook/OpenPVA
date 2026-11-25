adult_population <- function(n_female = 10L, n_male = 10L, age = 2L, ...) {
  pva_population(
    sex = c(rep("F", n_female), rep("M", n_male)),
    age = age,
    ...
  )
}

always <- function(pop, state, context, params) rep(TRUE, length(pop$id))

custom_process <- function(run, writes = character(), creates = NULL, name = "custom") {
  pva_process(name = name, run = run, writes = writes, creates = creates)
}

# Independent age-by-sex matrix expectation for the lifecycle
# survival -> age -> reproduction -> census, with three age classes (0, 1, 2+).
oracle_rates <- function() {
  list(
    survival = list(F = c(0.50, 0.80, 0.90), M = c(0.45, 0.75, 0.85)),
    breeding = c(0, 0.60, 0.90),
    litter = c(0, 1.20, 1.80),
    female_probability = 0.45,
    initial = list(F = c(0L, 6L, 10L), M = c(0L, 5L, 9L))
  )
}

oracle_class <- function(age) pmin(age, 2L) + 1L

oracle_matrix <- function(rates) {
  projection <- matrix(0, 6L, 6L)
  for (sex in 1:2) {
    survival <- rates$survival[[sex]]
    offset <- 3L * (sex - 1L)
    # After survival and ageing: class 0 -> 1, class 1 -> 2+, class 2+ -> 2+.
    projection[offset + 2L, offset + 1L] <- survival[[1L]]
    projection[offset + 3L, offset + 2L] <- survival[[2L]]
    projection[offset + 3L, offset + 3L] <- survival[[3L]]
  }
  # Births come from females at their post-ageing class.
  per_female <- rates$breeding * rates$litter
  births_from <- numeric(6L)
  births_from[[1L]] <- rates$survival$F[[1L]] * per_female[[2L]]
  births_from[[2L]] <- rates$survival$F[[2L]] * per_female[[3L]]
  births_from[[3L]] <- rates$survival$F[[3L]] * per_female[[3L]]
  projection[1L, ] <- rates$female_probability * births_from
  projection[4L, ] <- (1 - rates$female_probability) * births_from
  projection
}

oracle_scenario <- function(rates, n_runs, n_steps, seed) {
  scenario_spec(
    name = "matrix_oracle",
    n_runs = n_runs,
    n_steps = n_steps,
    seed = seed,
    init_fun = function() {
      pva_population(
        sex = c(rep("F", sum(rates$initial$F)), rep("M", sum(rates$initial$M))),
        age = c(rep(0:2, rates$initial$F), rep(0:2, rates$initial$M))
      )
    },
    processes = list(
      survival_process(function(pop, state, context, params) {
        ifelse(
          pop$sex == "F",
          rates$survival$F[oracle_class(pop$age)],
          rates$survival$M[oracle_class(pop$age)]
        )
      }, requires = "population.age"),
      age_process(),
      reproduction_process(
        breeding_probability = function(pop, state, context, params) {
          rates$breeding[oracle_class(pop$age)]
        },
        litter_size = litter_poisson(function(pop, state, context, params) {
          rates$litter[oracle_class(pop$age)]
        }),
        offspring_sex = offspring_sex_bernoulli(rates$female_probability),
        requires = "population.age"
      ),
      census_process()
    )
  )
}

# Exact Markov chain for a small unstructured two-sex cohort.
# Annual order: survival -> scheduled release -> reproduction -> census.
# A female breeds with probability p_breed when at least one male is alive and
# the post-release population is below `cap`; a litter has one or two young.
cohort_design <- function() {
  list(
    f0 = 2L, m0 = 2L, years = 10L,
    s_f = 0.70, s_m = 0.60,
    p_breed = 0.55, p_two = 0.30, female_probability = 0.5,
    cap = 6L,
    release_year = 3L, release_f = 1L, release_m = 1L,
    threshold = 2
  )
}

exact_cohort_chain <- function(design) {
  bound <- 3L * design$cap + design$release_f + design$release_m + design$f0 + design$m0
  size <- bound + 1L
  thinning <- function(survival) {
    out <- matrix(0, size, size)
    for (n in 0:bound) {
      out[n + 1L, seq_len(n + 1L)] <- stats::dbinom(0:n, n, survival)
    }
    out
  }
  thin_f <- thinning(design$s_f)
  thin_m <- thinning(design$s_m)
  offspring <- lapply(seq_len(design$cap), function(females) {
    joint <- matrix(0, 2L * females + 1L, 2L * females + 1L)
    for (breeders in 0:females) {
      p_breeders <- stats::dbinom(breeders, females, design$p_breed)
      for (twos in 0:breeders) {
        total <- breeders + twos
        weight <- p_breeders * stats::dbinom(twos, breeders, design$p_two)
        for (daughters in 0:total) {
          joint[daughters + 1L, total - daughters + 1L] <-
            joint[daughters + 1L, total - daughters + 1L] +
            weight * stats::dbinom(daughters, total, design$female_probability)
        }
      }
    }
    joint
  })
  total_n <- outer(0:bound, 0:bound, `+`)
  never <- matrix(0, size, size)
  never[design$f0 + 1L, design$m0 + 1L] <- 1
  crossed <- matrix(0, size, size)
  expected_n <- numeric(design$years)
  step <- function(mass, year) {
    mass <- t(thin_f) %*% mass %*% thin_m
    if (year == design$release_year) {
      shifted <- matrix(0, size, size)
      rows <- seq_len(size - design$release_f)
      cols <- seq_len(size - design$release_m)
      shifted[rows + design$release_f, cols + design$release_m] <- mass[rows, cols]
      mass <- shifted
    }
    bred <- matrix(0, size, size)
    occupied <- which(mass > 0, arr.ind = TRUE)
    for (row in seq_len(nrow(occupied))) {
      f <- occupied[row, 1L] - 1L
      m <- occupied[row, 2L] - 1L
      weight <- mass[f + 1L, m + 1L]
      if (f >= 1L && m >= 1L && f + m < design$cap) {
        joint <- offspring[[f]]
        rows <- f + seq_len(nrow(joint))
        cols <- m + seq_len(ncol(joint))
        bred[rows, cols] <- bred[rows, cols] + weight * joint
      } else {
        bred[f + 1L, m + 1L] <- bred[f + 1L, m + 1L] + weight
      }
    }
    bred
  }
  for (year in seq_len(design$years) - 1L) {
    never <- step(never, year)
    crossed <- step(crossed, year)
    below <- total_n < design$threshold
    crossed[below] <- crossed[below] + never[below]
    never[below] <- 0
    expected_n[[year + 1L]] <- sum((never + crossed) * total_n)
  }
  final <- never + crossed
  list(
    p_ever_below = sum(crossed),
    p_below_at_horizon = sum(final[total_n < design$threshold]),
    p_extinct_at_horizon = final[1L, 1L],
    expected_n = expected_n,
    mass = sum(final)
  )
}

cohort_scenario <- function(design, n_runs, seed) {
  scenario_spec(
    name = "cohort_oracle",
    n_runs = n_runs,
    n_steps = design$years,
    seed = seed,
    init_fun = function() adult_population(design$f0, design$m0),
    processes = list(
      survival_process(function(pop, state, context, params) {
        ifelse(pop$sex == "F", design$s_f, design$s_m)
      }),
      introduction_process(
        count = function(state, context, params) {
          if (context$time == design$release_year) {
            design$release_f + design$release_m
          } else {
            0L
          }
        },
        fields = function(n, state, context, params) {
          list(sex = c(rep("F", design$release_f), rep("M", design$release_m)), age = 1L)
        },
        source = "scheduled_release"
      ),
      reproduction_process(
        breeding_probability = function(pop, state, context, params) {
          if (length(pop$id) < design$cap) design$p_breed else 0
        },
        litter_size = litter_categorical(1:2, c(1 - design$p_two, design$p_two)),
        offspring_sex = offspring_sex_bernoulli(design$female_probability),
        mate = mate_random(always),
        require_mate = TRUE
      ),
      census_process()
    )
  )
}

# Independent dense numerator-relationship oracle (tabular method over the
# complete ledger, in identifier order).
dense_inbreeding <- function(ledger, initial_relationship = NULL) {
  diag(dense_relationship(ledger, initial_relationship)) - 1
}

dense_relationship <- function(ledger, initial_relationship = NULL) {
  n <- nrow(ledger)
  stopifnot(identical(ledger$id, seq_len(n)))
  relationship <- matrix(0, n, n)
  n_initial <- if (is.null(initial_relationship)) 0L else nrow(initial_relationship)
  if (n_initial) {
    relationship[seq_len(n_initial), seq_len(n_initial)] <- initial_relationship
  }
  for (index in seq.int(n_initial + 1L, length.out = n - n_initial)) {
    mother <- ledger$mother_id[[index]]
    father <- ledger$father_id[[index]]
    if (is.na(mother) && is.na(father)) {
      relationship[index, index] <- 1
      next
    }
    earlier <- seq_len(index - 1L)
    half <- 0.5 * (relationship[mother, earlier] + relationship[father, earlier])
    relationship[index, earlier] <- half
    relationship[earlier, index] <- half
    relationship[index, index] <- 1 + 0.5 * relationship[mother, father]
  }
  relationship
}

pedigree_scenario <- function(n_runs, n_steps, seed, capacity = 5, kinship = NULL) {
  breeding_age <- function(pop, state, context, params) pop$age >= 1L
  scenario_spec(
    name = "pedigree_oracle",
    n_runs = n_runs,
    n_steps = n_steps,
    seed = seed,
    init_fun = function() {
      pva_state(
        pva_population(
          sex = rep(c("F", "M"), 4L), age = 1L, mate_id = NA_integer_
        ),
        pedigree = TRUE,
        kinship = kinship
      )
    },
    processes = list(
      survival_process(function(pop, state, context, params) {
        ifelse(pop$age == 0L, 0.55, 0.8)
      }, requires = "population.age"),
      age_process(),
      pairing_process(breeding_age, capacity = capacity, priority = "lottery",
                      requires = "population.age"),
      reproduction_process(
        breeding_probability = function(pop, state, context, params) {
          as.numeric(!is.na(pop$mate_id))
        },
        litter_size = litter_poisson(2.2),
        offspring_sex = offspring_sex_bernoulli(0.5),
        mate = mate_from_field("mate_id"),
        require_mate = TRUE,
        newborn_fields = function(mothers, fathers, pop, state, context, params) {
          list(mate_id = NA_integer_)
        },
        newborn_field_names = "mate_id",
        requires = "population.mate_id"
      ),
      introduction_process(
        count = function(state, context, params) if (context$time == 4L) 2L else 0L,
        fields = function(n, state, context, params) {
          list(sex = c("F", "M"), age = 1L, mate_id = NA_integer_)
        },
        creates = c("sex", "age", "mate_id")
      ),
      census_process()
    )
  )
}
