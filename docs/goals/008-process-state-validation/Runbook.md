# Runbook

## Scope

Work only in OpenPVA's existing ordinary process seam. Use one local
pre-process state inside built-in demography and one plain execution-local
metadata list for validated processes, plan and creator requirements. Do not
add caches, controllers, registries, persistence or new population forms.

## Acceptance commands

```sh
Rscript -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test_process_prestate.R")'
Rscript scripts/run_tests.R process
Rscript scripts/run_tests.R density
Rscript scripts/run_tests.R grizzly
Rscript scripts/run_tests.R introduction
Rscript scripts/run_tests.R pedigree
Rscript scripts/run_tests.R
git diff --check
R CMD build --no-build-vignettes .
R CMD check --no-manual --no-build-vignettes OpenPVA_*.tar.gz
```

Run build/check in an isolated temporary directory and remove it. Scan active
callers/help/current docs for reproduction without explicit `offspring_sex`,
the removed default and accidental compatibility. Do not reconcile `renv`.

## Stop rule

After the required evidence and one focused material review/repair pass, report
and stop. Record repeated execution-local pedigree calculation as a residual
unless a small non-persistent solution is clearly justified.
