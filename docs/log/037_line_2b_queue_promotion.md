# Log 037 — Promote Line 2B.x roadmap queue

## Date
- 2026-02-09

## Trigger
- Priority Queue completed through `WP-2A.6` and maintainer requested
  implementation of the proposed next tranche plan.

## Summary
- Promoted a new strict-order roadmap tranche under `Line 2B.x` for:
  - uncertainty contracts,
  - ensemble/sampling APIs,
  - YAML schema v3 uncertainty support,
  - sensitivity diagnostics,
  - hindcast/calibration scaffold,
  - performance + uncertainty docs integration.

## Changes made
- Updated `docs/roadmap.md`:
  - Added `Line 2B.x` queue entries (`WP-2B.1`..`WP-2B.6`) as unchecked items.
  - Added detailed WP specs with outcomes/scope/acceptance/artefact evidence/
    stop conditions.
- Updated `docs/plan.md`:
  - Set current phase to active `Line 2B.x` startpoint at `WP-2B.1`.
  - Updated immediate next steps to execute `WP-2B.1` then proceed in order.
- Updated `docs/decisions.md`:
  - Added `DEC-025` documenting tranche promotion rationale and execution order.

## Validation
- Confirmed queue is no longer exhausted (`docs/roadmap.md` now has unchecked
  2B entries).
- Confirmed changes are documentation/roadmap governance only (no runtime code
  changes in this promotion step).

## Follow-up
1. Execute `WP-2B.1` end-to-end under WP-DoD.
2. Continue autonomous queue progression through `Line 2B.x` unless blocked.
