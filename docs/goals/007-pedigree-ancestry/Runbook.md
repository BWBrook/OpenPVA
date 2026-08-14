# Runbook

## Scope

Work only in OpenPVA. Preserve the append-only population ledger and ordinary
birth/introduction creator contracts. Use public IDs only for references and a
derived row index only within one population calculation. Do not add a matrix
cache, global registry, marker module, fitness response, database or controller
branch. Stop if exact ancestry requires a second authoritative population
representation or material engine redesign.

## Numerical convention

Tests use numerator relationship `A`: `A[i,i] = 1 + F[i]`, off-diagonals use
the standard parental average, and offspring `F = A[mother,father] / 2`.
Production uses the equivalent `A = T D T'` factorisation with transient
ancestor-contribution vectors and persistent linear-size parent, `F` and `D`
vectors only.

## Acceptance commands

```sh
Rscript scripts/run_tests.R pedigree
Rscript scripts/run_tests.R birth
Rscript scripts/run_tests.R introduction
Rscript scripts/run_tests.R
git diff --check
R CMD build --no-build-vignettes .
R CMD check --no-manual --no-build-vignettes OpenPVA_*.tar.gz
```

Run build/check in an isolated temporary directory and remove it. Scan active
R, tests, exports, help and current docs for retired `F`, `Fhat`, `mean_Fhat`,
`alleles`, genotype helpers and inbreeding-survival helper; preserve historical
logs. Scan controller/database/artifact surfaces and do not reconcile `renv`.

## Stop rule

After core implementation, required evidence and one focused material review
pass, report exact results and residual limitations. Do not begin marker
genetics, inbreeding depression, mate management or persistence.
