# WP-0.3.2 artefact bundle

This bundle captures metadata hardening and package-check evidence for `WP-0.3.2`.

## Commands run

1. `Rscript -e "devtools::document()"`
2. `R CMD build --no-build-vignettes .`
3. `R CMD check --no-manual --as-cran OpenPVA_0.0.0.9000.tar.gz --output=artefacts/WP-0.3.2`

## Result summary

- `R CMD check` completed with **0 errors, 0 warnings, 3 notes**.
- Notes are tracked in `rcmdcheck_post.log` and are currently:
  - CRAN incoming note for new submission/version and one empty URL in README.
  - LICENSE stub format note for `MIT + file LICENSE`.
  - Non-standard top-level files (`_targets.R`, `bootstrap_env.R`, `CONTRIBUTING.md`) note.

## Evidence files

- `build.log`: package build log.
- `document.log`: roxygen regeneration log.
- `rcmdcheck_pre.log`: initial pre-fix check failure snapshot.
- `rcmdcheck_post.log`: final check run with 0 errors/0 warnings.
- `OpenPVA.Rcheck/00check.log`: full check transcript.
- `session_info.txt`: runtime session metadata.
- `check_summary.txt`: concise status extraction.
