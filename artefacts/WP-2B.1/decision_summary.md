# WP-2B.1 Decision Summary

Date: 2026-02-09

## Decisions locked

- Uncertainty taxonomy for 2B includes:
  - vital-rate parameter uncertainty (survival, breeding probability,
    fecundity lambda),
  - bounded scalar management-control uncertainty.
- Composition order for rate channels:
  - baseline -> density -> uncertainty -> EV/cat -> clamp -> stochastic draw.
- Per-draw semantics:
  - sampled uncertainty parameters are fixed within draw and shared across that
    draw's replicate runs (unless a future extension explicitly adds
    year-varying uncertainty).
- Compatibility policy:
  - uncertainty remains additive/opt-in in 1.x and does not break existing
    deterministic pathways.
- Calibration boundary:
  - scaffold-level scoring/search in 2B, no full Bayesian inference.

## Referenced records

- `docs/decisions.md` (`DEC-026`)
- `docs/reference/uncertainty_validation_contract.md`

## Validation note

- WP-2B.1 is a design/contract lock package; no runtime code path changes were
  made in this WP.
