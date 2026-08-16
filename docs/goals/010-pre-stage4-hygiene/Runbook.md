# Runbook

## Scope

Preserve the generic engine, accepted Stage 3 modules, independent oracle,
canonical benchmark and exact pedigree contract. Preserve historical goals,
logs and artefacts. Do not implement Stage 4 or install/upgrade packages.

## Acceptance commands

```sh
Rscript scripts/run_tests.R
Rscript scripts/run_lint.R
Rscript -e 'renv::status()'
actionlint .github/workflows/*.yaml
Rscript -e 'pkgload::load_all(quiet = TRUE); x <- run_grizzly_benchmark(n_runs = 2L, n_steps = 3L, seed = 9010L); stopifnot(nrow(x$benchmark_summary$run_summary) == 2L)'
git diff --check
R CMD build --no-build-vignettes .
R CMD check --no-manual --no-build-vignettes OpenPVA_*.tar.gz
```

Run build/check outside the worktree. Confirm no active Quarto scaffold,
deferred dependency consumer, obsolete CI helper, or generated product remains.

## Stop rule

After required evidence and one focused material review/repair pass, report.
Do not start Stage 4 or chase the provisional assertion/runtime diagnostic by
removing distinct scientific evidence.
