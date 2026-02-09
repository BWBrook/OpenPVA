# WP-1.0.1 artefact bundle

Date: 2026-02-08

This bundle captures release-line stabilization evidence for OpenPVA `1.0.0`.

## Policy/versioning evidence

- `DESCRIPTION` bumped to `Version: 1.0.0`.
- `NEWS.md` includes a `1.0.0` entry.
- `docs/decisions.md` includes semver/release policy (DEC-006).
- `docs/reference/public_api.md` defines stable vs experimental exported APIs.
- `rc_sanity_note.txt` summarizes release-line sanity checks.

## Build sanity evidence

- `tests.log`: `devtools::test()` passed (`PASS 437`, `FAIL 0`).
- `lint.log`: `lintr::lint_package()` reported no lints.
- `check_stdout.log` + `00check.log`: `R CMD check --no-manual --as-cran`
  completed with `0` errors, `0` warnings (`3` notes).
- `quarto_render.log`: `quarto render quarto` succeeded.
- `targets_smoke.log`: minimal targets smoke (`sim_basic`) completed.
