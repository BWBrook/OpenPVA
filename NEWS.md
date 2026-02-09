# OpenPVA news

## OpenPVA 1.0.1 (development)

- Added 1.x soft-deprecation framework for legacy reproduction table wrappers
  with once-per-session warnings and explicit migration guidance.
- Added migration map doc:
  - `docs/reference/migration_1x_to_2x.md`
- Runtime compatibility for legacy wrappers is preserved in the 1.x line.
- Added spatial/genetic time-series summaries:
  - `summarise_patch_occupancy_timeseries()`
  - `summarise_patch_genetic_diversity_timeseries()`
- Added connectivity/turnover diagnostics:
  - `summarise_patch_connectivity_timeseries()`
- Added optional `record_population_history` support in controller/scenario/YAML
  pathways to enable time-series spatial/genetic analysis.
- Added packaged spatial/genetic YAML scenario trio in `inst/extdata/`:
  fragmented, connected, and asymmetric flow regimes.
- Added reusable helpers for spatial/genetic scenario setup:
  - `initialize_spatial_population()`
  - `initialize_spatial_genetic_population()`
  - `dispersal_low_connectivity_fun()`
  - `dispersal_high_connectivity_fun()`
  - `dispersal_asymmetric_flow_fun()`
- Expanded regression gates:
  - spatial/genetic schema-contract coverage,
  - seeded spatial/genetic snapshot slice,
  - heavy CI reproducibility filter includes `test_spatial_patches.R`.

## OpenPVA 1.0.0

- Declared the 1.x public API stability contract (`docs/reference/public_api.md`),
  with explicit stable vs experimental exported interfaces.
- Finalized semver/release policy in `docs/decisions.md` (DEC-006).
- Completed reproduction refactor line:
  - baseline reproduction rate channels (`breeding_prob_fun`,
    `fecundity_lambda_fun`),
  - controller-level reproduction EV/cat diagnostics,
  - YAML schema v2 support with schema v1 compatibility.
- Updated user-facing docs and demos (README + Quarto) to align with
  reproduction semantics and YAML v1/v2 behavior.
- No intentional breaking changes relative to the late 0.5.x line;
  compatibility wrappers and schema v1 support are retained for 1.x.

## OpenPVA 0.3.x (development line)

- Established baseline reproducibility and smoke-check workflow evidence under `artefacts/`.
- Hardened package metadata fields (`DESCRIPTION`) for check/release readiness.
- Added initial citation metadata in `inst/CITATION`.
