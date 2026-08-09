# Runbook

## Scope

Work only in the OpenPVA action repository. Use direct ordinary-R process lists
and small reusable constructors. Do not add a controller branch, registry,
configuration DSL, empirical values or workflow platform.

## Acceptance commands

```sh
Rscript scripts/run_tests.R grizzly
Rscript scripts/run_tests.R
R CMD build --no-build-vignettes .
R CMD check --no-manual --no-build-vignettes OpenPVA_*.tar.gz
git diff --check
```

Remove build/check artefacts before handoff. Record exact pass/fail/warn/skip
counts and residual limitations in `Log.md`.

## Stop rule

After the core benchmark and one focused repair pass satisfy the gates, report
the result. Do not polish speculative interfaces or begin Stage 3.
