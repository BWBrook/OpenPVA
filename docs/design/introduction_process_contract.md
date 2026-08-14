# Exogenous introduction process contract

## Decision

Use one public `introduction_process()` ordinary-process constructor for
immigration, supplementation, stocking and exogenous translocation. These names
describe modeller intent, not separate engine categories. Process name, count,
source, initialized state and lifecycle position are explicit model choices.

## Count and state

`count` is either one fixed non-negative integer or a modeller callback over
the pre-process state, engine context and explicit parameters. A callback may
be stochastic through the engine-scoped replicate stream. Invalid, fractional,
non-finite, negative or unallocatable counts fail; OpenPVA supplies no quota,
empirical distribution or fallback.

The engine's `allocate_ids()` supplies consecutive IDs and advances `next_id`.
Existing records and globals are unchanged, and all newcomers append alive in
allocator order. This process creates exogenous records only: no donor
population is represented or decremented.

## Initialization

The modeller declares `initializer_fields` exactly and supplies an initializer
called with newcomer index, allocated ID, one common pre-process state, engine
context and explicit parameters. The callback returns precisely those fields.
`id` and `alive` are engine-owned and cannot be overridden.

Newcomers are collected before any are appended, so one initializer cannot
observe an earlier newcomer from the same execution. Core field types and
values remain engine-validated. The generic creation contract also requires
every field consumed anywhere downstream: missing or `NA` required `patch_id`
fails in the same way as any future community-contributed required field.

## Events and provenance

Every positive addition emits aggregate `event_type = "introduction"`
accounting with an integer `value` and a required nonblank modeller `source`.
The engine stamps run, interval, phase, process position/name and occurrence.
A zero addition emits no accounting row because no population change occurred.

Optional `group_by` fields must be declared initializer fields with non-missing
atomic scalar values. Grouped rows partition the additions and replace the one
ungrouped row; they do not accompany it. Their values therefore sum exactly to
the number of appended records and pass the existing accounting validator
without double-counting.

## Canonical fixture

The synthetic grizzly immigration extension uses `introduction_process()` at
its established position after survival and before observation/census. It
retains the explicit count, alternating configured sex sequence within an
execution, age, independent status, unknown parents, source
`"illustrative translocation"`, and the benchmark's broader uncalibrated source
label. These are fixture semantics, not empirical grizzly release advice.

## Scientific limits

This contract does not cover harvest/removal, within-system movement,
donor-population dynamics, capture or release logistics, quarantine, disease,
acclimation, release optimisation, empirical supplementation advice or
pedigree/genetics. Those require separate modeller-specified processes and
scientific evidence.
