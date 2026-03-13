test_that("initialize_genotypes assigns allele matrices", {
  pop <- initialize_population(n = 3, max_age = 1)
  pop_g <- initialize_genotypes(population = pop, n_loci = 4, n_alleles = 3)

  expect_length(pop_g, 3)
  lapply(pop_g, function(ind) {
    expect_true(is.matrix(ind$alleles))
    expect_equal(dim(ind$alleles), c(2, 4))
    expect_true(all(ind$alleles %in% 1:3))
  })

  Fs <- vapply(pop_g, function(ind) ind$F, numeric(1))
  expect_true(all(!is.na(Fs)))
  expect_true(all(Fs >= 0))
  expect_true(all(Fs <= 1))
})

test_that("inherit_genotype_simple samples haplotypes and respects mutation bounds", {
  mother <- create_individual(id = 1L, sex = "F", age = 3L)
  father <- create_individual(id = 2L, sex = "M", age = 4L)
  mother$alleles <- rbind(c(1L, 1L), c(1L, 1L))
  father$alleles <- rbind(c(2L, 2L), c(2L, 2L))

  offspring <- inherit_genotype_simple(mother, father, mutation_rate = 0)
  expect_equal(dim(offspring), c(2, 2))
  expect_true(all(offspring[1, ] == 1L))
  expect_true(all(offspring[2, ] == 2L))

  set.seed(123)
  offspring_mut <- inherit_genotype_simple(mother, father, mutation_rate = 0.5, n_alleles = 2L)
  expect_true(all(offspring_mut %in% 1:2))
})

test_that("summarise_genetic_diversity computes heterozygosity means", {
  ind1 <- create_individual(1L, "F", age = 2L)
  ind2 <- create_individual(2L, "M", age = 2L)
  ind1$alleles <- rbind(c(1L, 2L, 1L, 2L), c(2L, 1L, 2L, 1L))
  ind2$alleles <- rbind(c(1L, 1L, 1L, 1L), c(1L, 1L, 1L, 1L))
  pop <- list(ind1, ind2)

  summary <- summarise_genetic_diversity(pop, alive_only = TRUE)
  expect_equal(summary$n_individuals, 2L)
  expect_true(summary$alive_only)
  expect_equal(summary$mean_heterozygosity, 0.5)
  expect_equal(summary$mean_Fhat, 0.5)
})

test_that("summarise_genetic_diversity handles missing genotypes", {
  pop <- initialize_population(n = 2)
  summary <- summarise_genetic_diversity(pop, alive_only = TRUE)
  expect_equal(summary$n_individuals, 0L)
  expect_true(is.na(summary$mean_heterozygosity))
  expect_true(is.na(summary$mean_Fhat))
})

test_that("apply_reproduction assigns alleles when inherit_fun provided", {
  mother <- create_individual(1L, "F", age = 3L)
  father <- create_individual(2L, "M", age = 4L)
  mother$alive <- TRUE
  father$alive <- TRUE
  mother$alleles <- rbind(c(1L, 1L), c(2L, 2L))
  father$alleles <- rbind(c(1L, 1L), c(2L, 2L))
  pop <- list(mother, father)
  breeders <- list(mother)
  fecundity_fun <- function(ind) 1L

  pop_after <- apply_reproduction(
    population = pop,
    breeders = breeders,
    fecundity_fun = fecundity_fun,
    mating_fun = default_mating_fun,
    inherit_fun = inherit_genotype_simple
  )

  expect_length(pop_after, 3L)
  newborn <- pop_after[[3L]]
  expect_equal(newborn$mother_id, mother$id)
  expect_equal(newborn$father_id, father$id)
  expect_true(is.matrix(newborn$alleles))
  expect_equal(dim(newborn$alleles), c(2, 2))
  expect_true(all(newborn$alleles %in% c(1L, 2L)))
  expect_false(is.na(newborn$F))
  expect_true(newborn$F >= 0)
  expect_true(newborn$F <= 1)
})

test_that("apply_reproduction records low F for heterozygous offspring", {
  mother <- create_individual(1L, "F", age = 3L)
  father <- create_individual(2L, "M", age = 4L)
  mother$alive <- TRUE
  father$alive <- TRUE
  mother$alleles <- rbind(rep(1L, 3), rep(1L, 3))
  father$alleles <- rbind(rep(2L, 3), rep(2L, 3))

  pop <- list(mother, father)
  breeders <- list(mother)
  fecundity_fun <- function(ind) 1L

  set.seed(123)
  pop_after <- apply_reproduction(
    population = pop,
    breeders = breeders,
    fecundity_fun = fecundity_fun,
    mating_fun = default_mating_fun,
    inherit_fun = inherit_genotype_simple
  )

  newborn <- pop_after[[3L]]
  expect_true(newborn$F <= 0.1)
})

test_that("apply_reproduction leaves alleles NULL when data missing", {
  mother <- create_individual(1L, "F", age = 3L)
  father <- create_individual(2L, "M", age = 4L)
  mother$alive <- TRUE
  father$alive <- TRUE
  mother$alleles <- rbind(c(1L, 1L), c(2L, 2L))
  father$alleles <- NULL
  pop <- list(mother, father)
  breeders <- list(mother)
  fecundity_fun <- function(ind) 1L

  pop_after <- apply_reproduction(
    population = pop,
    breeders = breeders,
    fecundity_fun = fecundity_fun,
    mating_fun = default_mating_fun,
    inherit_fun = inherit_genotype_simple
  )

  newborn <- pop_after[[3L]]
  expect_null(newborn$alleles)
  expect_true(is.na(newborn$F))
})

test_that("make_inbreeding_survival_fun applies linear penalty", {
  base_survival_fun <- function(ind) 0.8
  surv_fun <- make_inbreeding_survival_fun(base_survival_fun, beta = 0.5)

  ind_low <- create_individual(1L, "F", age = 2L, inbreeding_coeff = 0)
  ind_high <- create_individual(2L, "F", age = 2L, inbreeding_coeff = 1)

  expect_equal(surv_fun(ind_low), 0.8, tolerance = 1e-8)
  expect_equal(surv_fun(ind_high), 0.4, tolerance = 1e-8)
  expect_error(make_inbreeding_survival_fun(base_survival_fun, beta = -0.1))
})

test_that("make_inbreeding_survival_fun treats missing F as zero", {
  base_survival_fun <- function(ind) 0.6
  surv_fun <- make_inbreeding_survival_fun(base_survival_fun, beta = 0.5)

  ind_na <- create_individual(1L, "F", age = 2L)
  ind_na$F <- NA_real_

  expect_equal(surv_fun(ind_na), 0.6, tolerance = 1e-8)
})

test_that("run_basic_simulation propagates inherit_fun through controller", {
  init_fun <- function() {
    pop <- list(
      create_individual(1L, "F", age = 3L),
      create_individual(2L, "M", age = 3L)
    )
    initialize_genotypes(population = pop, n_loci = 2, n_alleles = 2)
  }
  survival_fun <- function(ind) 1
  set.seed(123)
  res <- run_basic_simulation(
    initial_population = init_fun(),
    n_years = 1,
    survival_fun = function(ind) 1,
    breeding_prob_fun = function(ind) 1,
    fecundity_lambda_fun = function(ind) 1,
    inherit_fun = inherit_genotype_simple
  )

  newborns <- Filter(function(ind) ind$id > 2L, res$population)
  expect_true(length(newborns) >= 1L)
  expect_true(all(vapply(newborns, function(ind) !is.null(ind$alleles), logical(1))))
  expect_true(all(vapply(newborns, function(ind) !is.na(ind$F), logical(1))))
})
