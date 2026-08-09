# Spatial process contract

## Decision

Discrete space uses the same ordered ordinary-process seam as demography and
density. `patch_id` is individual state interpreted against an explicit ordered
positive-integer domain; it is not a controller channel or a hidden landscape
index.

## State

Every individual participating in a spatial lifecycle has one non-missing
domain-member `patch_id`. Empty populations and empty declared patches are
valid. Initial assignment is supplied explicitly by the modeller. Birth and
introduction processes own spatial initialisation for individuals they create.

## Transition

A dispersal process selects eligible living individuals, evaluates every
destination against the same pre-process state, validates the complete result,
then applies the changes simultaneously. Existing record order, stable IDs,
alive state, abundance, non-patch attributes, globals and `next_id` are
unchanged.

The generic route accepts a modeller callback. The Markov route accepts only an
explicit domain-aligned probability matrix with finite entries in `[0, 1]` and
rows already summing to one within `sqrt(.Machine$double.eps)`. OpenPVA does not
normalise rows or supply connectivity defaults.

## Evidence

Aggregate `patch_transition` events describe every realised origin/destination
cell, including retention. Engine-stamped transition events are the movement
ledger. Survivor-history differences are timing-ambiguous and
survivorship-biased and are not a connectivity estimator.

## Patch density

The positioned snapshot process writes full-domain living counts to
`globals.patch_density_counts` and emits one event per patch. Strict keyed
lookup combines those counts with modeller-supplied capacities and the existing
ceiling multiplier. Missing, extra, reordered or unknown keys fail.

## Scientific limits

This contract represents discrete labels and a single transition at each
declared process position. It makes no claim about movement paths, costs,
mortality, habitat, distance, empirical connectivity, multiple substeps or gene
flow. Those require named models and evidence rather than architectural
defaults.
