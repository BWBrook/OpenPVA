# Runbook

## Scope

Work only in the OpenPVA repository. Use the existing creator declaration,
allocator, event and ordered-process contracts. Do not add donor-population
state, a management controller, registry, compatibility path or empirical
quota/initializer default. Pause if a material core-engine redesign is needed.

## Acceptance commands

```sh
Rscript scripts/run_tests.R introduction
Rscript scripts/run_tests.R grizzly
Rscript scripts/run_tests.R
git diff --check
R CMD build --no-build-vignettes .
R CMD check --no-manual --no-build-vignettes OpenPVA_*.tar.gz
```

Run build/check in an isolated temporary directory and remove it. Scan the
public surface for `introduction_process()` and the absence of
`apply_supplementation()`, bespoke creation loops, unexpected artifacts and
controller branches. Do not run Quarto, targets, release evidence, uncertainty
or calibration workflows.

## Stop rule

After the core implementation and one focused review/repair pass satisfy the
gates, report exact evidence and residual limitations. Do not begin harvest,
donor-population modelling or pedigree genetics.
