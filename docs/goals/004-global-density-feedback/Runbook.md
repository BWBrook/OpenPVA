# Runbook

## Scope

Work only in the OpenPVA repository. Use one ordinary snapshot process, one
pure multiplier and explicit existing survival/reproduction callbacks. Do not
add a density controller, specification object, channel framework, registry,
DSL, cache or compatibility path.

## Acceptance commands

```sh
Rscript scripts/run_tests.R density
Rscript scripts/run_tests.R
git diff --check
R CMD build --no-build-vignettes .
R CMD check --no-manual --no-build-vignettes OpenPVA_*.tar.gz
```

Run build/check in an isolated temporary directory and remove it. Scan the
public surface for the two intended new functions and absence of the four
retired names. Do not run Quarto, release-evidence, linting or reproducibility
suites.

## Stop rule

After the core implementation and one focused review/repair pass satisfy the
gates, report exact evidence and residual limitations. Do not begin spatial,
supplementation or genetic migration.
