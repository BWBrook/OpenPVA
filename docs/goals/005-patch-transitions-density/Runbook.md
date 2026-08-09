# Runbook

## Scope

Work only in the OpenPVA repository. Use ordinary processes over explicit
`patch_id` state and one keyed patch-count global. Do not add a spatial
controller, registry, landscape abstraction, compatibility path or empirical
movement default.

## Acceptance commands

```sh
Rscript scripts/run_tests.R spatial
Rscript scripts/run_tests.R
git diff --check
R CMD build --no-build-vignettes .
R CMD check --no-manual --no-build-vignettes OpenPVA_*.tar.gz
```

Run build/check in an isolated temporary directory and remove it. Scan the
public surface for the intended new functions and absence of all retired names.
Do not run Quarto, release-evidence, linting or reproducibility suites.

## Stop rule

After the core implementation and one focused review/repair pass satisfy the
gates, report exact evidence and residual limitations. Do not begin
supplementation or pedigree-genetics migration.
