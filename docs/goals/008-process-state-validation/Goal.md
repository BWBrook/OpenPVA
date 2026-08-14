# Goal 008 - Common process state and lean trusted validation

## Objective

Make built-in individual demography use one explicit pre-process state, remove
the hidden offspring-sex assumption and eliminate repeated trusted-path
validation work without changing the controller-free process seam.

## Required outcomes

1. Survival eligibility and probability callbacks share one immutable
   pre-process state; deaths are staged and applied together with exact
   accounting and unchanged sequential RNG order.
2. Reproduction breeding, mating, fecundity, offspring-sex and newborn
   initialisation share one pre-process state/population; newborns stage in
   deterministic ledger order and append together with consecutive IDs.
3. `offspring_sex` is a required modeller callback. No fallback, compatibility
   overload or biological default remains.
4. Public execution/allocation and actual replicate initialisation retain exact
   pedigree validation; every actual lineage change triggers exact full-ledger
   validation.
5. Static process/field-plan metadata is not rebuilt each interval and the
   trusted allocator does not rescan the population per newborn, while dynamic
   state, field, write, creator, event and accounting contracts remain active.
6. Focused tests prove pre-state visibility, staged accounting, explicit sex,
   fixed-seed retention, trust boundaries and bounded validation reuse.

## Non-goals

Goal 009 legacy API/dependency/release cleanup; Stage 4 reconnection; new
biology/modules; test pruning; broad file splitting; pedigree persistence or
caching; a second population representation; compatibility; publication.

## Acceptance evidence

- Focused process, density, grizzly, introduction and pedigree tests pass.
- The full test suite and isolated R 4.6.1 build/check pass.
- Bounded call-count tests demonstrate no interval-level static-validation
  replay and no per-newborn full-state allocator validation.
- Caller/default scans and `git diff --check` are clean.

## Publication boundary

No staging, commit, push, tag, release or publication is authorised.
