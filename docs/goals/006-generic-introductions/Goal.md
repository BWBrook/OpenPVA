# Goal 006 - Generic exogenous introductions

## Objective

Replace the legacy supplementation helper and bespoke benchmark creation loop
with one public ordinary-R creator process for exogenous introductions.

## Required outcomes

1. `introduction_process()` is the sole public primitive for immigration,
   supplementation, stocking and exogenous translocation. The modeller chooses
   the process name and interpretation; OpenPVA does not add parallel APIs.
2. The modeller supplies a fixed or state/context/parameter-driven count rule.
   Every realised count is a finite non-negative R integer within allocator
   range; no quota is estimated, normalised or defaulted.
3. The engine allocator supplies consecutive IDs and advances `next_id`.
   Existing records remain byte-identical and newcomers append alive in ID
   order.
4. The modeller declares every biological initializer field exactly and
   supplies a callback for those fields. `id` and `alive` are reserved. Every
   callback invocation in one execution sees the same documented pre-process
   state, not a state containing earlier newcomers.
5. A nonblank source label is mandatory. The process emits exact aggregate
   `introduction` accounting with engine provenance. Optional grouping over
   declared newcomer fields emits a partition of that total, not an additional
   duplicate total; grouped values sum exactly to additions.
6. Generic creation-field preflight and runtime checks remain authoritative.
   Missing or `NA` downstream-required `patch_id`, and future contributed
   fields, fail without spatial or genetic branches in the creator.
7. The canonical synthetic grizzly immigration extension uses the public
   primitive at its existing lifecycle position while preserving its count,
   sex sequence, age, source label, uncalibrated provenance and summaries.
8. `apply_supplementation()` and its export, help and focused legacy test are
   removed without an adapter. Its random sex, age-zero, optional missing patch
   and `max(id)` allocation defaults disappear.

## Scientific boundary

An introduction appends exogenous living records to the focal population. It
does not decrement or otherwise model a donor population. Count, source,
individual state and lifecycle position are model assumptions owned by the
modeller.

## Acceptance evidence

- Exact zero, fixed and dynamic counts, with decisive failures for fractional,
  negative, non-finite, out-of-range and otherwise invalid callback results.
- Consecutive allocator IDs, exact `next_id`, append-only order, byte-stable
  existing records and globals, and same-pre-state initializer evidence.
- Exact field matching, reserved-field rejection, complete records, spatial
  initialization and decisive downstream missing/`NA` patch failures.
- Total and patch-grouped introduction events that reconcile exactly and retain
  source plus engine-stamped provenance.
- Introduction/survival order falsification.
- Independently derived Monte Carlo count/initializer expectations, fixed-seed
  repeatability and serial/fork identity.
- Canonical grizzly immigration results and metadata through the public
  primitive, plus a community-defined initializer field with no engine edit.
- Focused and full tests pass; isolated package build and check succeed;
  `git diff --check` and intended public/retired/controller/artifact scans are
  clean.

## Non-goals

Harvest or other removals, within-system migration/translocation, donor
subtraction, release optimisation, disease, quarantine, acclimation, capture
logistics, pedigree/genetics implementation, empirical grizzly release advice,
YAML, targets, Quarto/reporting, uncertainty/calibration, `renv`
reconciliation, compatibility layers, registries, DSLs and engine redesign.

## Publication boundary

No staging, commit, push, tag or release is authorised by this goal.
