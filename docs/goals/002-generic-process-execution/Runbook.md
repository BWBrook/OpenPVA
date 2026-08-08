# Runbook

## Read first

1. `AGENTS.md`
2. `docs/design/lifecycle_process_contract.md`
3. `docs/design/canonical_grizzly_reference_model.md`
4. `docs/design/realignment_gap_map.md`
5. `docs/plan.md`

## Focused validation

```sh
Rscript scripts/run_tests.R process
Rscript scripts/run_tests.R simulation_core
Rscript scripts/run_tests.R scenario
Rscript scripts/run_tests.R rng
```

## Full validation

```sh
Rscript scripts/run_tests.R
R CMD build .
R CMD check --no-manual OpenPVA_*.tar.gz
git diff --check
```

Do not run Quarto or release-evidence automation for this implementation goal.
Do not commit or push.
