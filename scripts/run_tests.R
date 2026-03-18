#!/usr/bin/env Rscript

pkgload::load_all(quiet = TRUE)
testthat::test_dir("tests/testthat", stop_on_failure = TRUE)
