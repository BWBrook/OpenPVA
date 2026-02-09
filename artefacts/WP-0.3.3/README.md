# WP-0.3.3 artefact bundle

This bundle captures README quickstart hardening evidence for `WP-0.3.3`.

## Commands run

1. README example execution via:
   - minimal R scenario (`scenario_spec()` + `run_scenario()`)
   - YAML scenario (`read_scenario_yaml()` + `run_scenario()`)
2. `Rscript -e "devtools::test()"`
3. `R CMD build --no-build-vignettes .`
4. `R CMD check --no-manual --as-cran OpenPVA_0.0.0.9000.tar.gz --output=artefacts/WP-0.3.3`

## Result summary

- README scenario snippets executed successfully (see `readme_examples.log`).
- `devtools::test()` passed (`301` tests).
- Tarball `R CMD check` completed with **0 errors, 0 warnings, 3 notes**.
- Previous README empty URL note was removed.

## Evidence files

- `readme_examples.log`: direct output from runnable README snippets.
- `tests.log` / `tests_summary.txt`: test execution evidence.
- `build.log`: package build evidence.
- `rcmdcheck.log`: package check evidence.
- `OpenPVA.Rcheck/00check.log`: full check transcript.
- `session_info.txt`: runtime session metadata.
