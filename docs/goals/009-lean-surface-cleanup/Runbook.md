# Runbook

## Scope

Preserve the generic engine, Stage 3 processes, canonical benchmark, pedigree
contract and their tests. Preserve historical goals, logs and tracked artefacts.
Do not implement deferred analysis or compatibility.

## Acceptance commands

```sh
Rscript scripts/run_tests.R demography
Rscript scripts/run_tests.R process
Rscript scripts/run_tests.R spatial
Rscript scripts/run_tests.R grizzly
Rscript scripts/run_tests.R pedigree
Rscript scripts/run_tests.R
Rscript -e 'pkgload::load_all(quiet = TRUE); run_grizzly_benchmark(n_runs = 2L, n_steps = 3L, seed = 9009L)'
git diff --check
R CMD build --no-build-vignettes .
R CMD check --no-manual --no-build-vignettes OpenPVA_*.tar.gz
```

Run build/check outside the worktree. Scan `R/`, tests, `NAMESPACE`, `man/`,
scripts and current docs for deleted names. Treat historical goal/log/artefact
records and the explicitly deferred unrendered Quarto demo as provenance, not
active callers.

## Stop rule

After required evidence and one focused material review/repair pass, report.
Do not prune historical material, split large active files or polish Stage 4.
