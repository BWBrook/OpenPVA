# Spatial processes and event interpretation

## Active surface

Discrete patch structure is expressed through ordinary lifecycle processes:

- `initialize_patches()` assigns explicit starting `patch_id` values within a
  modeller-supplied ordered domain;
- `dispersal_process()` applies a custom simultaneous destination rule;
- `markov_dispersal_process()` draws from an explicit row-stochastic matrix;
- `patch_density_snapshot_process()` records living counts for every declared
  patch, including zero-count patches;
- `patch_density_multiplier()` performs strict keyed count/capacity lookup and
  applies `ceiling_density_multiplier()`.

There is no default patch allocation, connectivity regime, landscape object or
implicit newborn patch rule.

## Transition evidence

Every eligible living individual contributes to one aggregate
`patch_transition` event cell at the process position, including individuals
retained on the diagonal. Event rows contain `origin_patch_id`,
`destination_patch_id` and non-negative integer `value`, plus engine-owned
run/time/phase/process provenance.

These events are the authoritative movement evidence. Comparing end-of-year
survivor snapshots confounds transition timing with births, deaths and process
order and must not be interpreted as realised connectivity.

For each patch and transition event batch:

```text
end abundance = start abundance + non-diagonal inflow - non-diagonal outflow
```

when no other demographic process occurs between the two censuses.

## Patch density

`patch_density_snapshot_process()` writes one named integer vector to
`state$globals$patch_density_counts`. Its keys and order are the declared patch
domain. Later modeller-owned vital-rate callbacks combine that state with an
exactly keyed capacity vector through `patch_density_multiplier()`.

The snapshot is positional. Moving dispersal before or after it deliberately
changes the local abundance available to downstream callbacks. Capacity remains
a supplied phenomenological feedback parameter, not an inferred habitat limit
or hard population ceiling.

## Birth state and order

If any downstream process requires `population.patch_id`, every creation
process must declare and initialise it. Maternal inheritance is requested
explicitly with `reproduction_process(inherit_fields = "patch_id")`; a
`newborn_initializer` can express a different biological rule. The engine does
not choose one.

Dispersal before birth moves a mother before inherited patch state is created.
Birth before an age-filtered dispersal process can leave newborns in their
birth patch. Those are different models, not interchangeable implementations.

## Scope

Patches are discrete labels and each dispersal process is one transition at one
declared lifecycle point. Continuous space, paths, distances, movement costs,
habitat dynamics, empirical matrices, gene-flow inference and pedigree
genetics are outside this surface. Genetics will be rebuilt from pedigree and
ancestry state in its own Stage 3 tranche.
