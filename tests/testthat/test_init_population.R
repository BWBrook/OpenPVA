test_that("initialize_population returns expected structure", {
  pop <- initialize_population(n = 5, max_age = 2)
  expect_length(pop, 5)
  required <- c("id", "sex", "age", "alive", "mother_id", "father_id", "patch_id")
  expect_true(all(vapply(pop, function(ind) all(required %in% names(ind)), logical(1))))
  expect_true(all(vapply(pop, function(ind) ind$age >= 0 && ind$age <= 2, logical(1))))
  expect_true(all(vapply(pop, function(ind) ind$alive, logical(1))))
  expect_true(all(vapply(pop, function(ind) is.na(ind$mother_id), logical(1))))
  expect_true(all(vapply(pop, function(ind) is.na(ind$father_id), logical(1))))
  expect_true(all(vapply(pop, function(ind) is.na(ind$patch_id), logical(1))))
  expect_false(any(vapply(pop, function(ind) "alleles" %in% names(ind), logical(1))))
  expect_false(any(vapply(pop, function(ind) "F" %in% names(ind), logical(1))))
})

test_that("default_survival_fun respects age cutoffs", {
  expect_equal(default_survival_fun(list(age = 0)), 0.85)
  expect_equal(default_survival_fun(list(age = 3)), 0.92)
  expect_equal(default_survival_fun(list(age = 7)), 0.70)
})
