test_that("summarise_sensitivity_prcc captures directional toy signals", {
  draw_tbl <- tibble::tibble(
    draw_id = seq_len(30),
    param_a = rep(seq(0.05, 0.95, length.out = 10), 3),
    param_b = rep(c(0.1, 0.5, 0.9), each = 10)
  )
  draw_tbl$response <- 1.5 * draw_tbl$param_a - 0.8 * draw_tbl$param_b

  out <- summarise_sensitivity_prcc(
    ensemble_data = draw_tbl,
    response_col = "response",
    parameter_cols = c("param_a", "param_b")
  )

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2L)
  expect_true(out$prcc[out$parameter == "param_a"] > 0)
  expect_true(out$prcc[out$parameter == "param_b"] < 0)
  expect_true(all(out$abs_prcc >= 0))
})

test_that("summarise_sensitivity_prcc accepts summary-list input", {
  per_draw <- tibble::tibble(
    draw_id = seq_len(8),
    p_extinction = c(0.1, 0.2, 0.1, 0.35, 0.4, 0.5, 0.3, 0.45),
    harvest_quota = c(0, 1, 1, 2, 3, 4, 2, 3),
    cat_surv_prob = c(0.01, 0.03, 0.02, 0.06, 0.08, 0.1, 0.05, 0.09)
  )

  out <- summarise_sensitivity_prcc(
    ensemble_data = list(per_draw = per_draw),
    response_col = "p_extinction"
  )
  expect_equal(nrow(out), 2L)
  expect_true(all(c("parameter", "prcc", "p_value") %in% names(out)))
})
