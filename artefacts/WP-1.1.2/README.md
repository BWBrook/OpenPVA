# WP-1.1.2 artefact bundle

Date: 2026-02-08

This bundle captures R-level density module integration evidence for survival,
breeding-probability, and fecundity-lambda channels.

## Build and quality evidence

- `document.log`: roxygen regeneration completed.
- `tests_density.log`: density + spatial regression subset passed.
- `tests.log`: full test suite passed (`PASS 461`, `FAIL 0`).
- `lint.log`: `lintr::lint_package()` reported no lints.
- `build_stdout.log`: package tarball built successfully.
- `check_stdout.log` + `00check.log`: `R CMD check --no-manual --as-cran`
  completed with `0` errors, `0` warnings (`3` notes).

## Runtime and reproducibility evidence

- `quarto_render.log`: Quarto project render succeeded.
- `targets_smoke.log`: minimal targets smoke invocation completed.
- `OpenPVA_1.0.0.tar.gz`: built package artefact used for check.

## Density behavior sanity evidence

- `density_channel_demo_summary.csv`: seeded toy comparison showing density
  channels reduce abundance and births versus neutral baseline.
- `density_compatibility_summary.csv`: seeded parity check showing legacy
  `K_patches` and equivalent `density_spec` adapter match alive counts.
- `density_toy_interpretation_note.txt`: short interpretation summary.
- `domain_sanity.log`: execution log for toy density sanity script.
