# Lifecycle-process contract

## Status

This is the active Stage 1 design contract. The exported constructors are
`pva_state()`, `pva_process()`, `pva_result()`, `validate_processes()`,
`allocate_ids()` and `execute_processes()`. Code blocks remain conceptual where
they omit implementation details.

## Decision

Use an ordered list of validated, ordinary R process objects. Each object wraps
a function plus explicit metadata and parameters. No controller branch, global
registry, YAML lifecycle DSL, plugin manager, dependency injection, or S4/R6
hierarchy is required.

A tiny `pva_process` S3 class tag is useful for printing and dispatching one
validator, but process validity does not depend on inheritance: a named list that
satisfies the contract is sufficient.

## Vocabulary and ownership

### `state`

Engine-carried mutable simulation value:

- `population`: the current population representation;
- `globals`: named dynamic values deliberately shared among processes;
- `next_id`: engine-managed stable ID allocator.

These three state names are reserved. `globals` is a named list and `next_id` is
a length-one, non-missing positive integer. An individual-based `population` is
a list of named individual records; `id` is reserved as a unique, non-missing
positive integer. Other fields become required core fields only when the model
contract declares them, at which point their exact names and types are
validated.

Processes return a replacement state. They do not mutate global variables,
options, files, environments, or hidden package state.

### `context`

Engine-owned, read-only execution context:

- run identifier;
- current time and `dt`;
- process position, name and occurrence count;
- replicate stream provenance;
- provenance/failure identifiers.

A process cannot change time, run identity, seed provenance, or process order.

### Process

Conceptual shape:

```r
list(
  name = "independent_survival",
  run = function(state, context, params) { ... },
  params = list(...),
  requires = c("population.id", "population.age"),
  writes = "population.alive"
)
```

Required metadata:

- stable, non-empty `name`;
- callable `run`;
- explicit `params`;
- declared required fields;
- declared written fields.

Optional metadata may include a human description, semantic version, package
source and validator. Metadata is for validation and provenance, not discovery
through a central registry.

A process that creates individuals also supplies the minimal explicit
`creates` declaration listing every `population.*` field it promises to
initialise. This is checked against lifecycle requirements at preflight and
against actual newborns or introductions at runtime.

The Stage 1 population is an append-only record ledger. Existing records retain
their position and `id`; mortality changes `alive`; creators append records in
consecutive engine-ID order. The structural `population` write is reserved for
declared creators and does not authorize changes to existing records, which
still require granular `population.<field>` declarations.

### Result

Conceptual shape:

```r
list(
  state = next_state,
  events = event_records
)
```

`events` may be empty only when the process has no reportable or accounting
effect. The process supplies `event_type`; the engine adds `run`, `time`, phase,
`process_index`, `process_name`, and process occurrence. A process may add
`individual_id`, aggregate `value`, and documented extra columns. Births,
deaths, introductions, removals, and other events required to reconcile
population change cannot be silently suppressed.

## Composition

The lifecycle is a direct ordered list:

```r
processes <- list(
  age_process(...),
  dependency_process(...),
  reproduction_process(...),
  survival_process(...),
  custom_harvest_process(...),
  census_process(...)
)
```

The engine validates the list, then calls each process in order. Repeated names
are permitted only when occurrence identity is unambiguous; omission is
permitted if downstream requirements remain satisfied. A project package can
export a constructor returning a conforming object. The OpenPVA controller does
not need to know the process's biological category.

## Validation

Preflight must:

1. validate object shape and callable signatures;
2. validate parameters with process-specific validators;
3. check initial required fields;
4. trace declared writes through the ordered list to detect missing upstream
   fields;
5. check duplicate/ambiguous names and occurrence rules;
6. reject writes to engine-owned context fields;
7. verify that every birth/introduction process initializes fields required by
   downstream processes;
8. produce a readable execution plan and provenance record.

Declared fields are a scientific contract and diagnostic aid, not a static type
system. Runtime validation remains necessary.

## RNG contract

The engine assigns one independent reproducible L'Ecuyer-CMRG stream to each
replicate before execution. A replicate consumes sequential draws through its
declared process order. This preassignment must produce identical results for
the same model and root seed whether replicates run serially or in parallel.

Processes may use standard R RNG calls, but must never call `set.seed()` or
silently manage `.Random.seed`. The engine scopes the replicate stream, restores
the caller's RNG state on exit (including failure), and records enough stream
provenance to reproduce a replicate. Reordering a lifecycle is a model change
and may change all downstream draws. Per-process substreams are deliberately
deferred until a real use case shows that their complexity is valuable.

## Time and census contract

Step `t` represents interval `t -> t+1`. Every process in the ordered list sees
`context$time = t`; births and other emitted events are labelled `t`; the engine
advances time only after the full ordered list completes. An optional initial
census may describe state at `t = 0`. Thereafter census is an ordinary
non-mutating observer process, and its exact position in the lifecycle defines
whether it observes pre- or post-management state. The engine inserts no
implicit census.

## Arbitrary attributes and births

Core engine field names and exact types are reserved and validated. Processes
declare the fields they require and write. Ordinary named attributes remain
allowed without a central type registry or namespace framework; contributed
packages should prefix a field name when collision is plausible and document
its type and meaning in the process constructor.

The context and engine event-column names documented here are also reserved.
At preflight and runtime, every birth or introduction process must initialize
all fields required by any downstream process, or fail immediately with the
missing field and process names. Multiple writers must be explicit in the
execution plan. The existing missing newborn `patch_id` is the concrete
falsification case this contract must prevent.

## Event contract

The required engine columns and aggregate/individual detail policy are defined
under Result. Process constructors document their `event_type` vocabulary and
any extra columns. The engine may configure retention or aggregation, but it
must preserve the core accounting events and provenance needed to reconcile
each step. This avoids mandatory full individual histories without permitting a
memory setting to erase scientific accounting.

## Precedents and design inference

- [VORTEX 10](https://scti.tools/manuals/Vortex10Manual.pdf) and
  [HexSim](https://www.hexsim.net/help/events) demonstrate value in
  reorderable/repeated event sequences, user/global/individual variables,
  validation, and event logging.
- [`steps`](https://doi.org/10.1111/2041-210X.13354) is the closest R-native
  precedent: parameterised functions, shared state and direct process order.
- [RangeShiftR](https://doi.org/10.1111/ecog.05689) demonstrates whole-model
  preflight but also the cost of a broad S4 object system.
- [Madingley](https://doi.org/10.1371/journal.pbio.1001841)'s separation of
  state, deltas and diagnostics is useful; its registry and signature complexity
  is not needed here.
- [Mesa](https://doi.org/10.21105/joss.07668) reinforces engine ownership of
  context/RNG and separation of reporters.

These are design inferences, not claims that OpenPVA will reproduce another
framework's API.

## Rejected alternatives

- **Fixed labels plus more `if` branches:** fails community composition.
- **Global process registry:** adds discovery, namespace and hidden-state
  problems without a demonstrated need.
- **YAML lifecycle DSL:** duplicates R, creates parser/version obligations, and
  constrains user functions prematurely.
- **S4/R6 process hierarchy:** adds inheritance and construction cost without a
  proven polymorphism requirement.
- **Raw functions with `...` only:** too weak for preflight, provenance, field
  dependencies, or intelligible failures.

## Implementation boundary

The RNG, field, event, and time/census defaults above are implemented semantics.
Native deterministic execution remains deferred: use an independent
life-table or matrix expected-value oracle to test stochastic means under
matched assumptions.
