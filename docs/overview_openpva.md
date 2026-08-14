# OpenPVA overview

OpenPVA is an open-R population-viability execution system. The modeller writes
the biological program as an ordered set of explicit processes; OpenPVA provides
validated state transitions, reusable processes, time and RNG control,
replication, provenance, diagnostics, and reproducible analysis machinery.

The authoritative mission and scope are in `vision_and_scope.md`.

## Why OpenPVA

Population viability analyses are structurally consequential. Whether survival
precedes reproduction, how mates are limited, how density acts, which sex is
modelled, or how immigration enters can change extinction estimates and
management conclusions. OpenPVA makes those choices visible and testable in R.

The project inherits a demonstrated idea from GAPPS: a general engine can track
individuals while allowing the modeller to sequence lifecycle and management
processes. OpenPVA modernises that idea through open code, ordinary R
composition, explicit contracts, versioned provenance, and reproducible
workflows. `gapps_heritage.md` distinguishes verified history from OpenPVA's
design choices.

## Intended workflow

1. State the scientific or management question and estimand.
2. Define population state, scales, observation process, and evidence-backed
   parameters.
3. Compose an ordered lifecycle from reusable and project-specific processes.
4. Validate required fields, written fields, time semantics, and special cases.
5. Run stochastic replicates and compare their means with an independent
   expected-value oracle where matched assumptions permit it.
6. Examine trajectories, events, uncertainty, diagnostics, and hindcasts;
7. compare scenarios at the decision scale and report limitations.

`targets`, `renv`, and reporting tools can orchestrate a reproducible analysis;
they are not part of the biological process protocol.

## Core objects

- `state`: population records, shared dynamic globals, and engine-managed
  identifier state;
- `context`: engine-owned, read-only run/time/process-occurrence information;
- process: a validated ordinary R component that transforms `state` using
  `context` and explicit parameters;
- result: the next `state` plus structured events;
- simulation output: trajectories, events, diagnostics, summaries, and
  provenance across runs.

The active contract is specified in `design/lifecycle_process_contract.md` and
implemented by the exported process/state/result constructors and generic
executor.

## Canonical reference

The minimal grizzly benchmark in
`design/canonical_grizzly_reference_model.md` tests the architecture against a
real scientific lineage: long-lived two-sex demography, dependent offspring,
stochastic vital events, human-caused mortality, survival scenarios, and
management-relevant outputs. It deliberately excludes unsupported parameter
defaults and unnecessary spatial or genetic detail.

## Current state

OpenPVA now executes community-defined processes without controller edits. The
built-ins cover age, survival, reproduction, generic exogenous introductions,
explicitly positioned global and patch-density snapshots, simultaneous
discrete dispersal and census; exact event/ID accounting, reproducible
replicate streams and downstream creation-field validation are enforced by the
engine. Introduction counts and complete newcomer state are modeller-owned,
while the engine allocates IDs and retains source/accounting provenance.
Density affects a rate only when the modeller composes the relevant pure
multiplier in that process callback. Maternal patch inheritance is a declared
birth-fixture rule, not hard-coded engine biology. Realised movement is
recorded in transition events rather than inferred from survivor histories.

Existing genetic, harvest/removal, uncertainty, calibration and reporting code
is future-migration source. It is not a privileged parallel runtime. Stage 3
next addresses pedigree-based genetics after Goal 006 introductions, before
Stage 4 reconnects analysis interfaces.
