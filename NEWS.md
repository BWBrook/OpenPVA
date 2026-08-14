# OpenPVA news

## OpenPVA 1.0.1 (development)

- Replaced the fixed biological dispatcher with a validated ordered process
  engine, explicit state/result/field/event contracts and reproducible
  replicate streams.
- Added a synthetic source-labelled grizzly benchmark and process-native global
  density, patch transition/density, generic introduction and optional exact
  pedigree-ancestry modules.
- Standardised built-in demographic decisions on one pre-process state and made
  offspring sex an explicit modeller callback.
- Retained strict compilers for modeller-supplied demographic tables while
  removing packaged biological schedules and silent unmatched-row defaults.
- Removed controller-era lifecycle mutators and the incompatible old-output
  summary, plotting, management, uncertainty, sensitivity and calibration
  stack without compatibility adapters.
- Simplified current API, delivery documentation and dependencies around the
  process-native product. YAML, targets and reporting reconnection remains
  deferred to Stage 4.

This development line intentionally contains breaking changes. Historical
delivery records and artefacts remain in the repository as provenance.

## OpenPVA 1.0.0

- Established the first R package, seeded scenario, YAML, targets, Quarto,
  spatial/genetic and analysis prototypes.
- Published the R 4.6.1 Mac/CI readiness baseline and release-candidate evidence.

Those prototypes informed the current design but do not override the active
North Star or public API.
