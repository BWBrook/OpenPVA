# WP-0.5.1 artefact bundle

Date: 2026-02-08

This WP is a decision/documentation milestone (no runtime code mutation).

## Evidence

- Decision lock recorded in `docs/decisions.md`:
  - DEC-001 (core semantics + compatibility strategy)
  - DEC-002 (resolved under DEC-001)
  - DEC-003 (EV/cat placement policy)
- Design doc updated in `docs/design/reproduction_ev_semantics.md`:
  - status changed to decision-locked,
  - explicit controller responsibilities,
  - compatibility/deprecation contract,
  - worked example.
- Engineering log entry: `docs/log/008_wp-0.5.1.md`.

## Sanity note

- This WP intentionally introduces no runtime behavior changes.
- Validation baseline from WP-0.4.3 (tests/check/render) remains applicable.
