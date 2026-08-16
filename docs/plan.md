# OpenPVA living plan

## Authority and current objective

`docs/vision_and_scope.md` is product authority. Goals 001-009 are accepted and
published; Goals 008 and 009 landed at `d426910` and `7dcb850`. Goal 010 is the
active pre-Stage 4 hygiene tranche. Publication is not authorised.

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

## Active tranche - Goal 010

1. Right-size repeated test evidence without weakening distinct scientific,
   engine, process-order, accounting, RNG or pedigree contracts.
2. Make `R CMD check` the single CI test authority while retaining lean local
   test and lint entry points.
3. Remove the obsolete Quarto project and generated residue without replacement.
4. Lock only executable runtime/development consumers and reconcile the R 4.6.1
   environment.
5. Complete proportional package evidence and stop for Barry's acceptance.

## Next programme decision

After Goal 010 acceptance, frame the first Stage 4 executable vertical slice
against the current process/event/output contracts. Choose YAML, orchestration
or reporting tools only after the consumer is concrete. Harvest/removal should
return only as an ordinary evidence-backed process goal.

## Stop rule

Stop after Goal 010 evidence and one material review pass. Do not begin Stage 4,
prune historical artefacts, split the active engine/benchmark or publish without
separate authority.
