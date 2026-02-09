# Uncertainty and Validation Contract (Line 2B)

This note defines the implementation contract for Line 2B uncertainty and
validation work (`WP-2B.1` through `WP-2B.6`).

## 1) Scope boundary

In scope for 2B:
- Parameter uncertainty on vital-rate baseline channels:
  - survival baseline,
  - breeding probability baseline,
  - fecundity lambda baseline.
- Scalar management-control uncertainty (bounded and additive to existing
  management controls).
- Reproducible ensemble execution and summary/sensitivity diagnostics.
- Bounded hindcast/calibration scaffold (scoring + constrained search).

Out of scope for 2B:
- Full Bayesian inference workflows.
- Observation model/likelihood frameworks for detection error.
- Breaking redesign of existing lifecycle/controller interfaces.

## 2) Modifier composition order

For each vital-rate channel, modifiers must apply in this order:

1. Baseline rate from demography function.
2. Density modifier.
3. Uncertainty modifier (draw-level by default).
4. Year-level EV/cat modifier.
5. Bounds clamp to biologically valid interval/range.
6. Stochastic realization in controller.

This order is part of the behavioral contract and must be preserved unless
superseded by a new decision entry.

## 3) Draw semantics and reproducibility

- A single uncertainty draw defines one parameter set.
- That draw-level parameter set is shared across replicate runs within the draw
  unless explicitly marked as year-varying in the future.
- Seeded ensemble runs must be reproducible and restore caller RNG state as
  required by existing deterministic contracts.

## 4) Compatibility and schema strategy

- Uncertainty remains opt-in and additive in 1.x.
- Existing deterministic behavior remains default when uncertainty is omitted.
- YAML support will be additive via schema v3 `uncertainty` block with explicit
  migration tests from v2/defaults.

## 5) Validation outputs (minimum contract)

Line 2B implementations must emit and document:
- sampled parameter table (per draw),
- run-level identifiers linking draw/run outputs,
- per-draw summary outputs,
- overall uncertainty summary outputs.

Sensitivity/calibration helpers must return stable tidy outputs with documented
columns and interpretation caveats.
