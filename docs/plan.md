# OpenPVA living plan

## Authority and current objective

`docs/vision_and_scope.md` is product authority. Goals 001-011 are accepted and
published; Goal 011 landed at `6a0c8e6` as the first Stage 4 external-modeller
vertical slice.

> The modeller defines the biological program; OpenPVA supplies the execution
> engine, reusable processes, scientific contracts, and reproducible analysis
> machinery.

## Current product

- A lifecycle is a direct ordered list of validated ordinary R processes.
- The engine owns time, reproducible replicate streams, stable IDs, field and
  event contracts, exact accounting and provenance.
- Built-ins cover age, survival, reproduction, census, density snapshots,
  simultaneous patch transitions and generic exogenous introductions.
- Optional exact pedigree ancestry uses explicit founders/parentage and
  conditional pedigree IBD, separate from marker observations.
- The synthetic grizzly benchmark is the canonical end-to-end acceptance
  fixture; its values are illustrative and uncalibrated.
- Demographic table builders compile modeller-supplied schedules and fail on
  missing coverage. OpenPVA ships no biological table defaults.
- Controller-era direct mutators and old-output analysis/release surfaces are
  removed in Goal 009 rather than adapted.

There is no fixed dispatcher, lifecycle DSL, global registry, plugin manager,
dependency-injection framework, compatibility layer or second aggregate
population representation.

## Latest completed tranche - Goal 011

1. Translate the 1980 Lord Howe Island woodhen recovery comparison into a
   standalone ordinary-R project using only installed public APIs.
2. Compare no intervention, pig control and pig control plus captive breeding
   under a common 40-year starting state.
3. Make sexes, mate availability, territory occupancy, floaters, intervention
   receipts and parentage explicit without reproducing rPVA's mixed units or
   hard abundance ceiling.
4. Retain reproducible replicate evidence, exact accounting and honest Monte
   Carlo uncertainty without claiming fresh calibration or numerical parity.
5. Run one proportional installed-package and package validation pass and
   publish after Barry's acceptance.

## Next programme decision

Use the completed external model to identify actual public-API friction.
Generalise only a repeated modeller need exposed by a second consumer; do not
infer a project framework, YAML layer or reporting stack from one successful
case.

## Stop rule

Do not calibrate the woodhen model or generalise its project-local processes
without a new scientific goal. Select the next consumer before restoring
workflow machinery.
