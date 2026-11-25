# Lifecycle-process contract

## Status

This is the active engine contract for OpenPVA 2.0.0. It describes what a
process may do, what the engine owns and what strict validation checks. The
package tests in `tests/testthat/` are its executable form.

## Decision

A lifecycle is an ordered list of validated, ordinary R process objects. Each
wraps a function plus explicit metadata and parameters. There is no controller
branch, global registry, lifecycle DSL, plugin manager or class hierarchy. A
`pva_process` class tag exists for printing and validation only.

## State

`pva_state()` carries:

- `population`: a columnar table, a named list of equal-length vectors with one
  element per **living** individual;
- `globals`: named dynamic values shared among processes;
- `next_id`: the identifier allocator;
- `kinship`: the kinship of the living population when pedigree tracking is
  on, otherwise `NULL` (see Pedigree).
- `max_dense_kinship` sets the maximum number of dense slots per replicate.

Core population fields are `id`, `sex`, `age`, `alive`, `mother_id`,
`father_id`, `origin` and `entry_time`. Any other field is the modeller's, with
a fixed type for the whole run. The set of fields is fixed by the initial
state: a process cannot add or drop a field.

The engine owns `id`, `origin` (`initial`, `birth` or `introduction`),
`entry_time` (the interval of entry; -1 for the initial population),
`pedigree_F`, `next_id` and `kinship`. A process cannot declare them in
`writes`, and strict validation rejects any change to them.

Mortality and removal are recorded by setting `alive` to `FALSE`. After the
process returns and is validated, the engine moves those records out of the
living table (into the ledger when one is kept), so every process starts with
living individuals only. Records are never reordered.

## Process

```r
pva_process(
  name = "independent_survival",
  run = function(state, context, params) { ... },   # returns pva_result()
  params = list(...),
  requires = c("population.age", "globals.weather"),
  writes = "population.alive",
  creates = NULL
)
```

- `requires` and `writes` are state paths, `population.<field>` or
  `globals.<name>`.
- A process that adds individuals declares `creates`: the fields it
  initialises, which must include `sex` and `age` and cover every non-core
  field. It adds them only through `add_individuals()`, which allocates
  identifiers and refuses an incomplete set of fields.
- `context` is read-only: `run`, `time`, `dt`, `phase`, `n_steps`,
  `process_index`, `process_name`, `occurrence` and `departed_males` (IDs lost earlier in the interval).
- `pva_result(state, events, census)` returns the new state, optional events
  from `pva_events(event_type, value, label)` and an optional named numeric
  census vector.

Built-in processes take vectorised functions of `(pop, state, context, params)`
that return one value per living individual. Every function supplied to one
process sees the same pre-process state: survival cannot see a death drawn
earlier in the same process, and breeding cannot see newborns of the same
process. Named environment variables evaluate in list order, so subsequent rates can use the current shared draw. Random draws are taken in population (identifier) order.

## Preflight

Before a run the engine checks every process object, then traces the field plan
through the ordered list against the initial state:

1. every `requires` path exists initially or is written upstream;
2. every written population field exists;
3. every creator's `creates` covers every non-core field, so a newborn can never
   reach a downstream process with a field uninitialised.

## Strict validation after every process

- the result is a `pva_result` holding a `pva_state`;
- the population has the same fields in the same order, each with its type and
  the right length; no record was deleted or reordered;
- every field and global not listed in `writes` is unchanged (compared by
  value, column by column);
- written core fields hold no missing or invalid values;
- `next_id` advanced by exactly the number of new records, new identifiers are
  the allocated ones, and new records are alive and carry no engine-owned
  values;
- the engine-owned pedigree and slot limit retain their values during callbacks, including element-wise assignments;
- **cohort accounting**: the number of existing individuals that stopped living
  equals the `death` plus `removal` event values, and the number of created
  individuals equals the `birth` plus `introduction` event values. The two are
  checked separately, so an unreported loss offset by an unreported entry is
  caught even though net abundance is unchanged. A process reports one loss
  type and one entry type per execution.

Fast validation skips the structural comparison. Parentage and individual
accounting counts are checked in both modes, which give identical biological
results for valid inputs.

## Accounting ledger

For every process and interval the engine records `n_before`, `births`,
`introductions`, deaths and removals split into `resident`, `born` (this
interval) and `introduced` (this interval), and `n_after`.
`summarise_accounting()` reconciles each interval. Because losses are attributed
to the cohort and the process in which they occur, the ledger shows, for
example, whether released animals were exposed to mortality that preceded
their release.

## Pedigree

With `pva_state(pedigree = TRUE)` the engine tracks exact kinship. A child's
inbreeding coefficient is the kinship of its parents. Its kinship with another
individual is the mean of the two parental kinships with that individual. Its
self-kinship is half of one plus its inbreeding coefficient.

Initial parent IDs may refer to later rows. The engine evaluates them in
pedigree order. Supply an aligned matrix when starting animals have known
kinship outside the recorded ancestry. Each missing parent represents an
independent, unrelated contribution. Either known parent may die after
pairing and before birth in the same interval.

Small populations use reusable dense slots with deferred offspring rows.
Callbacks receive R values with copy-on-modify semantics, so they cannot
silently change another process's kinship. Above the dense limit the engine
tracks parent indices and inbreeding in a compact ledger. It traces the
ancestors of each distinct breeding pair, preserving the covariance of any
related starting animals. The ledger grows with recorded ancestry. Starting animals
with nonzero mutual kinship retain a dense covariance block. Request selected living pairs with
`kinship_matrix(state, ids)`. Population-wide mean kinship uses a weighted
ancestry calculation in compact mode. Returning the full living matrix still
requires quadratic space.

## Random numbers

`run_scenario()` assigns one L'Ecuyer-CMRG stream to each replicate before any
work is dispatched. A replicate consumes its stream in declared process order,
so results are bit-identical for a given seed whether replicates run serially,
on fork workers or on a PSOCK cluster. An unseeded call first draws one root seed from the caller. The remaining
simulation restores the caller's RNG on exit, including on error. Processes may draw random numbers but
never call `set.seed()`. Reordering a lifecycle is a model change and changes
the draws.

## Time and census

Step `t` is the interval `t → t + 1`. Every process in the list sees
`context$time = t`; the engine advances time only after the whole list has run.
A census is an ordinary non-mutating process, and its position defines what it
observes. An optional initial census describes the state at year 0;
`summarise_pva()` labels the census of interval `t` as year `t + 1`.

## Retention

`run_scenario(keep = ...)` chooses what a run returns: `census`, `events`,
`accounting`, final `state` and the full `ledger`. The default retains census, events and accounting. Retention never changes what is computed.

## Precedents and design inference

- [VORTEX 10](https://scti.tools/manuals/Vortex10Manual.pdf) and
  [HexSim](https://www.hexsim.net/help/events) demonstrate value in
  reorderable and repeated event sequences, user variables, validation and
  event logging.
- [`steps`](https://doi.org/10.1111/2041-210X.13354) is the closest R-native
  precedent: parameterised functions, shared state and direct process order.
- [RangeShiftR](https://doi.org/10.1111/ecog.05689) demonstrates whole-model
  preflight but also the cost of a broad S4 object system.
- [Mesa](https://doi.org/10.21105/joss.07668) reinforces engine ownership of
  context and random numbers and the separation of reporters.

These are design inferences recorded by the original authors of this contract,
not claims that OpenPVA reproduces another framework's API.

## Rejected alternatives

- **Fixed labels plus more `if` branches:** fails community composition.
- **Global process registry:** adds discovery, namespace and hidden-state
  problems without a demonstrated need.
- **YAML lifecycle DSL:** duplicates R and constrains user functions.
- **S4/R6 process hierarchy:** adds inheritance and construction cost without a
  proven polymorphism requirement.
- **A list of per-individual records as state:** the 1.x representation. It
  made every check and every rate a loop over R closures and over every
  individual ever born; a 40-year Woodhen replicate took about 100 s.
