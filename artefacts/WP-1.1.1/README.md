# WP-1.1.1 artefact bundle

Date: 2026-02-08

This bundle captures the design/decision lock evidence for the density module.

## Scope evidence

- `docs/decisions.md` contains active `DEC-005` for density semantics and compatibility.
- `docs/design/density_module.md` is implementation-ready and explicitly defines:
  - channel set (`survival`, `breeding`, `fecundity`),
  - composition order,
  - state scope,
  - compatibility mapping from legacy `K`/`K_patches`.

## Validation evidence

- `decision_validation.txt` records line-level checks confirming decision and
  design lock markers are present.
