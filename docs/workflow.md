# OpenPVA development workflow

OpenPVA uses proportional scientific validation: test the contract that changed,
exercise a representative real workflow, then run package-level gates before a
change is accepted or published.

## Per-goal cycle

1. Read `AGENTS.md`, the active goal and the relevant scientific contract.
2. Implement the smallest coherent change and update callers, tests, help and
   current documentation together.
3. Run focused contract tests and inspect structured events/state for scientific
   plausibility and exact accounting.
4. Run the full suite and one representative scenario when runtime behavior
   changed.
5. For acceptance or publication, build the source package and run the agreed
   `R CMD check` profile outside the worktree.
6. Record commands, results, limitations and the publication boundary in the
   active goal log. Perform one focused review/repair pass, then stop.

Do not repeat unchanged checks or polish historical material without a material
risk reduction. Do not relax evidence for scientific claims, state integrity,
RNG reproducibility, accounting or destructive operations.

## Current gates

```sh
Rscript scripts/run_tests.R
R CMD build --no-build-vignettes .
R CMD check --no-manual --no-build-vignettes OpenPVA_*.tar.gz
```

Run build/check in an isolated temporary directory. Lint is a fast-CI gate.
The canonical grizzly benchmark is the preferred representative runtime proof
for changes to engine or demographic behavior.

## Deferred workflow surfaces

Targets, YAML compilation and Quarto reporting remain planned Stage 4 analysis
machinery. They are not mandatory current gates and do not define lifecycle
semantics. The unrendered legacy `quarto/basic_demo.*` sources and historical
evidence bundles are retained only as migration evidence until Stage 4 replaces
them deliberately.
