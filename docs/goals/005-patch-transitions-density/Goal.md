# Goal 005 - Patch transitions and patch-specific density

## Objective

Replace the controller-era spatial surface with explicit patch state, ordinary
dispersal and patch-density processes, and event-first transition evidence.

## Required outcomes

1. `patch_id` is a strict positive-integer individual attribute interpreted
   within an explicit ordered patch domain. `initialize_patches()` assigns only
   modeller-supplied identifiers and never invents a distribution.
2. A reusable ordinary dispersal process changes only eligible living
   individuals' `patch_id`. All destination decisions see the same pre-process
   population and are applied simultaneously.
3. A narrow Markov constructor accepts an explicit domain and row-stochastic
   transition matrix. It rejects invalid probabilities and row sums rather than
   normalising or supplying empirical defaults.
4. Dispersal emits aggregate `patch_transition` events for every realised
   origin/destination combination, including retention. These engine-stamped
   events are the authoritative connectivity evidence.
5. A positioned patch-density process records living counts for the full
   declared domain, including empty patches, in one keyed global field and
   emits one snapshot event per patch.
6. Patch-specific vital-rate callbacks combine explicit keyed counts and
   capacities with `ceiling_density_multiplier()`. Unknown, missing or
   mismatched keys fail rather than becoming density-neutral.
7. Newborn patch state remains modeller-owned through declared inheritance or
   initialisation, and lifecycle order remains biologically consequential.
8. The obsolete dispersal functions, fixed connectivity regimes, spatial
   convenience initialisers and history-inferred spatial summary suite are
   removed without aliases or adapters.

## Scientific boundary

Patches are discrete modeller-defined labels. A dispersal process represents
one simultaneous transition at its declared lifecycle position. Transition
events, not differences between survivor snapshots, are the evidence for
movement. Patch density is a positioned phenomenological vital-rate feedback,
not a landscape, habitat or movement model.

## Acceptance evidence

- Strict domain and patch-state validation, including invalid fractional,
  missing, non-positive and unknown identifiers and declared empty patches.
- Exact identity/swap transitions, pre-state simultaneity, fixed dead or
  ineligible records, non-patch byte stability and transition reconciliation.
- Strict Markov-matrix validation, analytic seeded transition frequencies, and
  serial/fork identity.
- Explicit newborn inheritance, omission failure and birth/dispersal order
  falsification.
- Full-domain density snapshots, strict keyed capacity lookup, exact density
  multipliers/rates and dispersal/density order falsification.
- Focused and full tests pass; isolated package build and check succeed;
  intended public/retired surface scans and `git diff --check` are clean.

## Non-goals

Continuous space, GIS, paths, distances, movement costs or mortality, habitat
dynamics, empirical connectivity defaults, multiple dispersal substeps,
supplementation, genetics or gene-flow summaries, YAML, Quarto/reporting,
release evidence, uncertainty/calibration, `renv` reconciliation, compatibility
layers, registries, DSLs, landscape objects and broad engine redesign.

## Publication boundary

No staging, commit, push, tag or release is authorised by this goal.
