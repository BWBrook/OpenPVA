test_that("survival and ageing apply vectorised rates to eligible individuals", {
  state <- pva_state(adult_population(200L, 200L, age = c(rep(0L, 200L), rep(5L, 200L))))
  set.seed(1L)
  out <- execute_processes(state, list(
    survival_process(
      function(pop, state, context, params) ifelse(pop$age == 0L, 0, 1),
      eligible = function(pop, state, context, params) pop$sex == "F",
      cause = "test"
    ),
    age_process(increment = 2L)
  ))
  expect_identical(length(out$state$population$id), 200L)
  expect_identical(unique(out$state$population$age), 7L)
  expect_identical(out$events$value[out$events$event_type == "death"], 200)
  expect_identical(out$events$label[[1L]], "test")
  expect_error(
    execute_processes(state, list(survival_process(1.5))),
    "survival probability"
  )
  expect_error(
    execute_processes(state, list(survival_process(function(pop, state, context, params) c(0.5, 0.5)))),
    "one non-missing value per individual"
  )
  expect_error(survival_process("high"), "finite number or a function")
})

test_that("staged survival leaves residents' fates independent of the split", {
  build <- function(share, n_release) {
    release <- introduction_process(
      count = function(state, context, params) if (context$time < 2L) n_release else 0L,
      fields = function(n, state, context, params) {
        list(sex = rep(c("F", "M"), length.out = n), age = 2L)
      }
    )
    scenario_spec(
      name = "split", n_runs = 5L, n_steps = 6L, seed = 8L,
      init_fun = function() adult_population(15L, 15L),
      processes = list(
        staged_survival_process(0.7, share, "pre"),
        release,
        staged_survival_process(0.7, share, "post"),
        age_process(),
        census_process()
      )
    )
  }
  # With no releases the whole trajectory is bit-identical for every split.
  reference <- run_scenario(build(0, 0L), keep = c("census", "ledger"))
  for (share in c(0.35, 1)) {
    other <- run_scenario(build(share, 0L), keep = c("census", "ledger"))
    expect_identical(other$census, reference$census)
    for (run in seq_along(reference$ledgers)) {
      expect_identical(
        other$ledgers[[run]][c("id", "sex", "age", "exit_time")],
        reference$ledgers[[run]][c("id", "sex", "age", "exit_time")]
      )
    }
  }
  # With releases, the residents of the first interval still meet the same fate.
  first_fate <- function(share) {
    ledger <- run_scenario(build(share, 6L), keep = "ledger")$ledgers[[1L]]
    initial <- ledger[ledger$origin == "initial", ]
    is.na(initial$exit_time) | initial$exit_time > 0L
  }
  expect_identical(first_fate(0), first_fate(1))
  expect_identical(first_fate(0), first_fate(0.5))

  # Released animals survive the release interval with probability s^share.
  survivors <- function(share) {
    result <- run_scenario(scenario_spec(
      name = "b", n_runs = 300L, n_steps = 1L, seed = 2L,
      init_fun = function() adult_population(2L, 2L),
      processes = build(share, 40L)$processes
    ), keep = "accounting")
    40 - summarise_accounting(result)$deaths_introduced
  }
  for (share in c(0, 0.5, 1)) {
    x <- survivors(share)
    expect_lt(abs(mean(x) - 40 * 0.7^share) / max(stats::sd(x) / sqrt(300), 1e-9), 3.5)
  }
  expect_error(staged_survival_process(0.7, 1.2), "post_share")
})

test_that("staged survival applies the age-specific exposure on either side of ageing", {
  n <- 240L
  age <- rep(0:1, length.out = n)
  state <- pva_state(pva_population(rep("F", n), age))
  rates <- c(0.16, 0.81, 0.36)
  probability <- function(pop, state, context, params) rates[pop$age + 1L]
  set.seed(321)
  first_draw <- runif(n)
  for (q in c(0, 0.35, 1)) {
    set.seed(321)
    result <- execute_processes(state, list(
      staged_survival_process(probability, q, "pre"), age_process(),
      staged_survival_process(probability, q, "post")
    ))
    expected <- first_draw < rates[age + 1L]^(1 - q) * rates[age + 2L]^q
    expect_identical(result$state$population$id, which(expected))
    expect_null(result$state$globals$survival_draw)
    if (q == 0) expect_equal(result$events$value[result$events$process_name == "survival_post"], 0)
  }
  set.seed(321)
  tie <- first_draw[[1L]]
  exact <- execute_processes(state, list(staged_survival_process(tie, 0.4, "pre"),
                                         staged_survival_process(tie, 0.4, "post")))
  expect_identical(exact$state$population$id, which(first_draw < tie))
})

test_that("reproduction honours mates, litter distributions and newborn fields", {
  state <- pva_state(adult_population(300L, 1L, patch = "a", weight = 2.5))
  breeding <- function(litter, ...) {
    reproduction_process(
      breeding_probability = 1,
      litter_size = litter,
      offspring_sex = offspring_sex_bernoulli(0.3),
      newborn_fields = function(mothers, fathers, pop, state, context, params) {
        list(weight = rep(0.1, length(mothers)))
      },
      newborn_field_names = "weight",
      inherit = "patch",
      ...
    )
  }
  set.seed(2L)
  out <- execute_processes(state, list(breeding(litter_categorical(c(1, 3), c(0.5, 0.5)))))
  born <- out$state$population$origin == "birth"
  litters <- table(out$state$population$mother_id[born])
  expect_true(all(litters %in% c(1L, 3L)))
  expect_identical(length(litters), 300L)
  expect_true(all(out$state$population$weight[born] == 0.1))
  expect_true(all(out$state$population$patch[born] == "a"))
  expect_true(all(is.na(out$state$population$father_id[born])))
  expect_identical(unique(out$state$population$entry_time[born]), 0L)
  expect_lt(abs(mean(out$state$population$sex[born] == "F") - 0.3), 0.06)

  bounded <- execute_processes(state, list(breeding(litter_binomial(4L, 2))))
  sizes <- tabulate(match(
    bounded$state$population$mother_id[bounded$state$population$origin == "birth"], 1:300
  ), 300L)
  expect_lte(max(sizes), 4L)
  expect_lt(abs(mean(sizes) - 2), 0.2)
  expect_lt(stats::var(sizes), 1.5)

  poisson <- execute_processes(state, list(breeding(litter_poisson(2))))
  expect_gt(max(tabulate(match(
    poisson$state$population$mother_id[poisson$state$population$origin == "birth"], 1:300
  ), 300L)), 4L)

  # A required mate that is absent prevents breeding; a random sire is male.
  no_males <- pva_state(adult_population(20L, 0L, patch = "a", weight = 1))
  mated <- breeding(litter_poisson(2), mate = mate_random(always))
  expect_identical(
    execute_processes(no_males, list(mated))$events$value[[1L]], 0
  )
  sired <- execute_processes(state, list(mated))$state$population
  expect_identical(unique(sired$father_id[sired$origin == "birth"]), 301L)

  expect_error(reproduction_process(1, litter_poisson(1), "F"), "offspring_sex")
  expect_error(
    reproduction_process(1, litter_poisson(1), offspring_sex_bernoulli(), require_mate = TRUE),
    "needs a mate function"
  )
  expect_error(
    reproduction_process(1, litter_poisson(1), offspring_sex_bernoulli(), inherit = "age"),
    "distinct non-core fields"
  )
  expect_error(litter_categorical(1:2, c(0.5, 0.6)), "sum to 1")
  expect_error(offspring_sex_bernoulli(2), "\\[0, 1\\]")
})

test_that("mate indices and litter sizes are checked before they can alter births", {
  state <- pva_state(pva_population(c("F", "M"), age = 2))
  for (bad in list(0, -1, 1.5, 3, Inf, NaN, TRUE, "2")) {
    reproduction <- reproduction_process(0, litter_poisson(1), offspring_sex_bernoulli(),
                                         mate = function(...) c(bad, NA))
    expect_error(execute_processes(state, list(reproduction)), "valid whole-number row index")
  }
  wrong_sex <- reproduction_process(0, litter_poisson(1), offspring_sex_bernoulli(),
                                    mate = function(...) c(1L, NA))
  expect_error(execute_processes(state, list(wrong_sex)), "not male")
  state$population$mate_id <- c(99L, NA_integer_)
  wrong_id <- reproduction_process(0, litter_poisson(1), offspring_sex_bernoulli(),
                                   mate = mate_from_field(), inherit = "mate_id")
  expect_error(execute_processes(state, list(wrong_id)), "recorded sire")
  state <- pva_state(pva_population(c("F", "M"), age = 2))
  for (bad in list(-1, NA_integer_, 1.2, Inf, "1")) {
    reproduction <- reproduction_process(1, function(...) bad, offspring_sex_bernoulli())
    expect_error(execute_processes(state, list(reproduction)), "finite, non-negative integer")
  }
})

test_that("bounded litters match the conditional mean, including a positive minimum", {
  pop <- pva_population(c("F", "M"), age = 2)
  draw <- function(size, mean, minimum, n) {
    litter_binomial(size, mean, minimum)(rep(1L, n), pop, NULL, NULL, NULL)
  }
  set.seed(813)
  observed <- draw(3L, 1.5, 1L, 100L)
  set.seed(813)
  expect_identical(observed, 1L + stats::rbinom(100L, 2L, 0.25))
  expect_identical(draw(3L, 3L, 3L, 2L), c(3L, 3L))
  expect_error(litter_binomial(2L, 3), "litter mean")
  expect_error(draw(3L, function(...) c(0, 0), 1L, 2L), "litter mean")
  expect_error(draw(3L, function(...) c(4, 0), 1L, 2L), "litter mean")
  expect_error(litter_categorical(c(1, Inf), c(0.5, 0.5)), "whole")
})

test_that("removals, ceilings and introductions reconcile and report shortfalls", {
  state <- pva_state(adult_population(6L, 6L, age = c(1:6, 1:6)))
  set.seed(3L)
  counted <- execute_processes(state, list(removal_process(
    count = 4, order = "id", cause = "capture",
    eligible = function(pop, state, context, params) pop$sex == "F"
  )))
  expect_identical(counted$state$population$id[1:2], 5:6)
  expect_identical(counted$events$value, c(4, 0))
  expect_identical(counted$events$event_type, c("removal", "removal_shortfall"))
  expect_identical(counted$accounting$removals_resident, 4L)

  short <- execute_processes(state, list(removal_process(
    count = function(state, context, params) 9,
    eligible = function(pop, state, context, params) pop$sex == "M"
  )))
  expect_identical(short$events$value, c(6, 3))

  chosen <- execute_processes(state, list(removal_process(
    select = function(pop, state, context, params) pop$age >= 5L
  )))
  expect_identical(length(chosen$state$population$id), 8L)
  hazard <- execute_processes(state, list(removal_process(probability = 1)))
  expect_identical(length(hazard$state$population$id), 0L)
  expect_error(removal_process(count = 1, probability = 0.5), "exactly one")
  expect_error(removal_process(), "exactly one")
  expect_error(
    execute_processes(state, list(removal_process(
      select = function(pop, state, context, params) c(1L, 1L)
    ))),
    "distinct eligible rows"
  )

  capped <- execute_processes(state, list(ceiling_process(capacity = 7)))
  expect_identical(length(capped$state$population$id), 7L)
  expect_identical(capped$events$event_type[[1L]], "death")
  expect_identical(capped$events$label[[1L]], "ceiling")
  females_capped <- execute_processes(state, list(ceiling_process(
    capacity = function(state, context, params) 2,
    eligible = function(pop, state, context, params) pop$sex == "F"
  )))$state$population
  expect_identical(sum(females_capped$sex == "F"), 2L)
  expect_identical(sum(females_capped$sex == "M"), 6L)
  expect_identical(
    length(execute_processes(state, list(ceiling_process(50)))$state$population$id), 12L
  )

  released <- execute_processes(state, list(introduction_process(
    count = 3,
    fields = function(n, state, context, params) list(sex = "M", age = 2L),
    source = "translocation"
  )), time = 6L)
  new <- released$state$population$origin == "introduction"
  expect_identical(sum(new), 3L)
  expect_identical(released$state$population$id[new], 13:15)
  expect_identical(unique(released$state$population$entry_time[new]), 6L)
  expect_identical(released$events$label, "translocation")
  expect_identical(released$accounting$introductions, 3L)
})

test_that("pairing limits breeders by mates and territories under both priorities", {
  state <- pva_state(adult_population(6L, 4L, mate_id = NA_integer_))
  breeding_age <- function(pop, state, context, params) pop$age >= 1L
  by_id <- execute_processes(state, list(pairing_process(breeding_age, capacity = 3)))
  mates <- by_id$state$population$mate_id
  expect_identical(mates[1:3], 7:9)
  expect_identical(mates[7:9], 1:3)
  expect_true(all(is.na(mates[c(4:6, 10L)])))
  expect_identical(by_id$events$value, c(3, 4))

  unlimited <- execute_processes(state, list(pairing_process(breeding_age)))
  expect_identical(sum(!is.na(unlimited$state$population$mate_id)), 8L)

  set.seed(4L)
  holders <- replicate(200L, {
    out <- execute_processes(state, list(pairing_process(
      breeding_age, capacity = 2, priority = "lottery"
    )))$state$population
    expect_identical(sum(!is.na(out$mate_id)), 4L)
    expect_identical(out$mate_id[match(out$mate_id[!is.na(out$mate_id)], out$id)],
                     out$id[!is.na(out$mate_id)])
    !is.na(out$mate_id[1:6])
  })
  # Under the lottery every female holds a territory about one time in three.
  expect_true(all(abs(rowMeans(holders) - 1 / 3) < 0.12))

  father <- mate_from_field()(by_id$state$population, NULL, NULL, NULL)
  expect_identical(father[1:3], 7:9)
})

test_that("environment, catastrophe and density helpers behave as defined", {
  state <- pva_state(adult_population(100L, 100L), globals = list(a = 0, b = 0, storm = FALSE))
  weather <- environment_process(list(
    a = function(state, context, params) params$value,
    b = function(state, context, params) state$globals$a * 2
  ), params = list(value = 3))
  out <- execute_processes(state, list(weather))$state
  expect_identical(out$globals[c("a", "b")], list(a = 3, b = 6))

  set.seed(6L)
  hit <- execute_processes(state, list(catastrophe_process(1, mortality = 0.5, name = "storm")))
  expect_true(hit$state$globals$storm)
  expect_identical(hit$events$event_type, c("catastrophe", "death"))
  expect_lt(abs(hit$events$value[[2L]] - 100), 25)
  miss <- execute_processes(state, list(catastrophe_process(0, mortality = 1, name = "storm")))
  expect_false(miss$state$globals$storm)
  expect_identical(length(miss$state$population$id), 200L)

  shapes <- beta_shapes(0.6, 0.1)
  expect_equal(shapes$shape1 / (shapes$shape1 + shapes$shape2), 0.6)
  expect_error(beta_shapes(0.5, 0.6), "too large")
  expect_equal(shift_logit(0.5, 0), 0.5)
  expect_gt(shift_logit(0.5, 1), 0.7)

  expect_equal(ceiling_density_multiplier(c(50, 100, 200), 100), c(1, 1, 0.5))
  expect_equal(beverton_holt_multiplier(c(0, 100), 100, 1.5), c(1, 1 / 1.5))
  expect_equal(ricker_multiplier(c(0, 100, 200), 100, 1.5), c(1, 1 / 1.5, 1 / 2.25))
  expect_error(beverton_holt_multiplier(10, 100, 0.9), "at least 1")
  expect_error(ricker_multiplier(-1, 100, 2), "non-negative")
})

test_that("age-by-sex tables compile to strict vectorised lookups", {
  table <- data.frame(
    age_min = c(0, 1, 4, 0), age_max = c(0, 3, Inf, Inf),
    sex = c("F", "F", "F", "M"), rate = c(0.4, 0.8, 0.6, 0.7)
  )
  lookup <- age_sex_rate(table, "rate")
  pop <- pva_population(sex = c("F", "F", "F", "M", "F"), age = c(0, 3, 40, 9, 4))
  expect_equal(lookup(pop, NULL, NULL, NULL), c(0.4, 0.8, 0.6, 0.7, 0.6))
  female_rates <- age_sex_rate(table[table$sex == "F", ], "rate")
  expect_equal(female_rates(pop, NULL, NULL, NULL), c(0.4, 0.8, 0.6, 0, 0.6))
  gap <- table[-2L, ]
  expect_error(age_sex_rate(gap, "rate")(pop, NULL, NULL, NULL), "no rate class covers sex F at age 3")
  overlap <- table
  overlap$age_max[[1L]] <- 2
  expect_error(age_sex_rate(overlap, "rate"), "overlap")
  expect_error(age_sex_rate(table, "missing"), "value column")
})

test_that("individuals move among declared patches", {
  transition <- matrix(
    c(0, 1, 1, 0), 2L, byrow = TRUE, dimnames = list(c("1", "2"), c("1", "2"))
  )
  state <- pva_state(adult_population(4L, 4L, patch_id = rep(1:2, 4L)))
  moved <- execute_processes(state, list(markov_dispersal_process(transition)))
  expect_identical(moved$state$population$patch_id, rep(2:1, 4L))
  expect_identical(moved$events$value[moved$events$event_type == "dispersal"], 8)
  expect_identical(
    patch_counts(moved$state$population, 1:3),
    c(`1` = 4L, `2` = 4L, `3` = 0L)
  )
  females <- execute_processes(state, list(dispersal_process(
    destination = function(rows, pop, state, context, params) rep(2L, length(rows)),
    patches = 1:2,
    eligible = function(pop, state, context, params) pop$sex == "F"
  )))$state$population
  expect_identical(females$patch_id, c(2L, 2L, 2L, 2L, 1L, 2L, 1L, 2L))
  expect_error(
    execute_processes(state, list(dispersal_process(
      function(rows, pop, state, context, params) rep(9L, length(rows)), patches = 1:2
    ))),
    "declared patch"
  )
  expect_error(markov_dispersal_process(matrix(0.5, 2L, 2L)), "row-stochastic")
  expect_error(patch_counts(state$population, 1L), "outside the declared patches")
})
