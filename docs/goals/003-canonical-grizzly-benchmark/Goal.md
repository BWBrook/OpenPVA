# Goal 003 - Canonical grizzly benchmark

## Objective

Deliver the smallest complete, inspectable and explicitly uncalibrated
grizzly-like benchmark that demonstrates a consequential long-lived-mammal PVA
can be expressed, varied, inspected and validated entirely through ordinary-R
process composition. The engine must remain biological-agnostic.

## Required outcomes

1. An explicit annual program composes environmental state, ageing/dependency,
   breeding eligibility and mate availability, reproduction, dependent and
   independent survival, targeted human mortality, optional introductions and
   an explicitly positioned census/observation.
2. A source-labelled illustrative parameter fixture exposes units, horizon,
   threshold and assumptions. It is not empirical grizzly truth, GYE
   calibration, a recovery criterion or a sustainable-mortality claim.
3. Baseline, two independent-female survival alternatives, one sex/age-targeted
   human-mortality scenario and one immigration extension differ only through
   ordinary process objects and parameters.
4. Replicate-level outputs retain abundance, finite growth, threshold timing,
   vital-event counts, environmental modifiers, process order, parameter values
   and hash, seed provenance and software/package version.
5. Reordering mortality and reproduction, annual environmental variation, a
   custom observation process and immigration are demonstrated without engine
   edits.
6. Focused validation covers bounds/units, empty/one-sex/all-dependent edge
   cases, accounting, IDs, dependency transitions, an independent expectation
   fixture, Monte Carlo error, seeded reproducibility, order falsification and
   provenance completeness.

## Scope and non-goals

The benchmark is a narrowly justified package fixture and process-construction
surface. It does not add empirical parameterisation, management advice,
density, spatial, genetic, habitat, disease, climate, optimisation, YAML,
targets, Quarto, reporting-platform, uncertainty or calibration workflows, a
deterministic backend, or compatibility adapters.

## Acceptance evidence

- Focused Goal 003 tests and the retained full test suite pass.
- R package build and `R CMD check --no-manual --no-build-vignettes` return
  success; `git diff --check` is clean.
- No fixed biological labels or controller branches are introduced.
- One self-review/repair pass is recorded in `Log.md`, followed by a stop at
  the decisive 80/20 boundary.

## Publication boundary

No commit, push, tag or release is authorised by this goal.
