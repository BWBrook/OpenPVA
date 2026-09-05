# Goal 011 runbook

## Standalone model

From a copied or source-tree Woodhen project with OpenPVA installed:

```sh
cd inst/examples/woodhen
Rscript run.R
```

An optional output directory and replicate count may be supplied:

```sh
Rscript run.R /tmp/openpva-woodhen 100
```

## Focused checks

```sh
Rscript scripts/run_tests.R woodhen
Rscript scripts/run_lint.R
git diff --check
```

## Full gates

```sh
Rscript scripts/run_tests.R
Rscript -e 'renv::status()'
R CMD build .
R CMD check --no-manual --no-build-vignettes OpenPVA_*.tar.gz
```

Build/check artefacts and generated model outputs are temporary validation
evidence and must not remain in the repository.
