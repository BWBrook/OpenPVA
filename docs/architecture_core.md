# OpenPVA core architecture

## Authority and status

`vision_and_scope.md` defines the product. This document explains the active
core architecture. `design/lifecycle_process_contract.md` is its normative
contract; later stages add scientific processes and reconnect workflows without
changing this execution seam.

## Architectural centre

OpenPVA executes an ordered biological program supplied by the modeller:

```text
model specification
  -> preflight validation
  -> engine executes ordered processes
  -> next state + structured events
  -> trajectories, diagnostics, summaries and provenance
```

The engine has no closed list of biological event types. Ageing, reproduction,
survival, dispersal, genetics, harvest, observation and a project-specific
process all compose through the same execution seam.

## Responsibilities

### Modeller

- scientific question, estimand and inference scale;
- population and observation models;
- process order and parameters;
- parameter evidence and uncertainty;
- validation, sensitivity and decision criteria.

### Engine

- validate process objects, parameters and field dependencies;
- hold run/time/process context read-only for processes;
- govern RNG, replication, stable identifiers and provenance;
- execute processes in declared order;
- collect events and attach failure context;
- enforce state/result and accounting contracts.

### Process

- implement one documented biological, management or observation transformation;
- declare required and written fields;
- use explicit parameters and engine context;
- return state plus events;
- avoid files, plotting, environment installation, hidden global state and time
  advancement.

### Analysis workflow

`targets`, `renv`, Quarto and project scripts orchestrate data preparation,
parameter estimation, simulation, diagnostics and reporting. They are consumers
of the engine, not lifecycle-process machinery.

## Core values

### State

Stage 1 state is a named list containing:

- `population`: an ordered list of persistent individual records;
- `globals`: deliberately shared dynamic model state;
- `next_id`: engine-owned identifier allocation.

Population identity is append-only: an existing record retains its list
position and `id`; death or removal changes `alive`; a birth or introduction
appends a record with the next consecutive engine ID. Physical deletion,
reordering, or mutation of an existing ID fails. A creator may declare the
structural `population` write needed to append, but changes to existing records
still require granular `population.<field>` declarations. Core names and exact
types are reserved and validated; ordinary named attributes remain allowed
without a central type registry. Birth and introduction processes must
initialize every downstream-required field or fail immediately.

### Context

Context contains run identity, interval time, `dt`, process
name/position/occurrence, replicate-stream provenance and failure identifiers.
It is read-only. This prevents a biological process from silently changing
execution semantics.

### Process and result

A process is an ordinary function wrapped with a small validated metadata list:
name, parameters, required fields and written fields. A result contains the next
state and structured events. A minimal S3 tag can improve printing and
validation; inheritance is not the protocol.

### Lifecycle

A lifecycle is a direct ordered list of processes. Processes can be added,
replaced, repeated, reordered or omitted subject to preflight and runtime
contracts. Third-party constructors return conforming objects; no controller
edit or registry entry is required.

## Scientific contracts

### Time and event order

Event order is model structure. Step `t` represents interval `t -> t+1`;
processes and events use label `t`, and time advances after the ordered list.
Apart from an optional initial `t = 0` census, a census is an ordinary observer
whose exact position defines pre/post-management semantics. There is no implicit
census.

### Randomness

The engine preassigns one independent L'Ecuyer-CMRG stream per replicate and
scopes/restores R RNG state. Processes use ordinary R RNG calls but cannot call
`set.seed()`. Sequential draws follow lifecycle order, so reordering is a model
change and may change downstream draws. Replicate preassignment must make serial
and parallel results identical. Per-process substreams are deferred.

### State and accounting

Each run/year must reconcile starting population, births, introductions, deaths
and ending population. IDs remain unique; required fields remain valid; no
process writes engine-owned context.

### Expected-value validation

Stage 1 remains a stochastic individual-based engine. It does not require a
second aggregate/fractional population representation or native deterministic
process mode. Under exactly matched assumptions, an independent life-table or
matrix expected-value oracle tests whether simulated means converge within
stated Monte Carlo error. Native deterministic execution is deferred until a
demonstrated scientific use requires it.

### Events and outputs

The process supplies `event_type`; the engine validates it and stamps `run`,
`time`, `phase`, `process_index`, `process_name`, and `process_occurrence`.
Optional fields include `individual_id`, `value`, and documented
process-specific columns. Aggregate detail is the default and individual detail
is opt-in, but core accounting events cannot be suppressed. Summary functions
remain outside biological processes and preserve replicate-level evidence.

## Optional domains

Density, spatial movement, genetics, management and observation are optional
processes over the same state. No feature is automatically scientifically
appropriate. Each process documents assumptions, required evidence, scale and
validation.

Patch-aware birth is a key invariant: if downstream processes require
`patch_id`, reproduction must initialize it according to a declared rule. The
Stage 1 preflight and immediate post-creation checks enforce that invariant.

## Extension and package boundary

A community package should need only to:

1. import the public process/result constructors and validators;
2. implement an ordinary R function;
3. declare requirements, writes and parameters;
4. test its transformation and event accounting;
5. return the process in a user's ordered list.

OpenPVA must not require community modules to register names globally, modify
the controller, submit to the core repository, or subclass a deep hierarchy.

## Current architecture gap

Current code validates six lifecycle labels and dispatches through conditional
branches. Reordering is supported, but extension is not. The retained,
redesigned, repaired and removed components are specified in
`design/realignment_gap_map.md`.

## Reference benchmark

`design/canonical_grizzly_reference_model.md` supplies the first acceptance
test. It covers structured two-sex demography, maternal dependency, stochastic
events, human-caused mortality, alternate ordering, expected-value oracle
checks, accounting events and extension without controller edits.

## Explicit exclusions

The target does not currently include a lifecycle DSL, registry, plugin manager,
dependency injection, S4/R6 hierarchy, GUI, or automatic scientific validation.
Those additions require demonstrated need after the simple contract succeeds.
