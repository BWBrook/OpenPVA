# Global density API

## Public functions

- `density_snapshot_process(name = "density_snapshot")`
- `ceiling_density_multiplier(n_alive, capacity)`
- `grizzly_density_extension_scenario(capacity, ...)`

## Snapshot contract

The ordinary snapshot process records living abundance at its exact lifecycle
position in `state$globals$density_n_alive` and emits a `density_snapshot`
event with `n_alive`. It does not change population records or IDs. Downstream
callbacks declare `globals.density_n_alive` in their process `requires` field.

## Multiplier contract

`n_alive` must be one finite non-negative whole number and `capacity` one
finite positive number. The result is exactly `1` at zero, below capacity and
at capacity; above capacity it is `capacity / n_alive`.

The function is a phenomenological vital-rate multiplier, not a population
cap, empirical estimate, equilibrium condition or removal operation. The
modeller explicitly composes it in any selected survival, breeding or
fecundity callback.

## Extension fixture

`grizzly_density_extension_scenario()` adds a positioned snapshot and explicit
density terms to the synthetic Goal 003 baseline. Its required `capacity` is
illustrative and source-labelled. The five canonical benchmark scenarios are
unchanged.

Patch-specific density, density configuration schemas and controller-managed
modifier channels are not part of this API.
