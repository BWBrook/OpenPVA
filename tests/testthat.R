if (requireNamespace("testthat", quietly = TRUE) &&
    requireNamespace("OpenPVA", quietly = TRUE)) {
  testthat::test_check("OpenPVA")
}
