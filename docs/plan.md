# OpenPVA living plan

## Authority and current objective

`docs/vision_and_scope.md` is the product authority. The sole operational
programme is to build the canonical grizzly benchmark on the implemented
R-native lifecycle-process contract.

The modeller defines the biological program. OpenPVA supplies execution,
reusable processes, scientific contracts, RNG/time/event provenance, validation
and reproducible analysis machinery.

## Current state

- Stage 0 was accepted and Stage 1 implemented the generic process seam.
- `scenario_spec()` and `run_scenario()` take a direct process list; the fixed
  dispatcher and `run_basic_simulation*()` surface are removed.
- Minimal age, survival, reproduction and census processes compose with
  project-defined observers or management processes.
- Birth and introduction processes explicitly declare created fields; missing
  downstream `patch_id` fails at preflight or runtime.
- YAML, targets, uncertainty/calibration execution, summaries and optional
  module scenarios are deliberately de-exported/deferred rather than adapted.
- The published test/CI/release evidence remains useful historical baseline
  evidence, but it does not select the next product tranche.

## Locked target defaults

- Ordered ordinary R process objects with explicit parameters,
  requirements/writes, and state-plus-events results.
- One preassigned L'Ecuyer-CMRG stream per replicate; sequential lifecycle
  draws; serial/parallel equality; no process-level `set.seed()` or initial
  per-process substreams.
- Reserved and typed core fields plus ordinary named contributed attributes;
  birth/introduction must initialize every downstream-required field.
- Engine event columns `run`, `time`, `process_index`, `process_name`, and
  `event_type`; aggregate default, opt-in individual detail, unsuppressible core
  accounting events.
- Step `t` denotes interval `t -> t+1`; time advances after the list; census is
  an explicitly positioned observer apart from an optional initial `t = 0`
  census.
- An independent life-table/matrix expected-value oracle validates stochastic
  means. Native deterministic execution and a second fractional population
  representation are deferred.
- No compatibility adapters, DSL, registry, plugin framework, dependency-
  injection system, or S4/R6 process hierarchy.

## Staged realignment

### Stage 0 — strategic acceptance (complete)

Barry reviews the North Star, evidence, canonical benchmark, lean contract and
gap map as one package. The remaining decision is strategic acceptance and
authority to implement Stage 1, not selection among reversible mechanics.

### Stage 1 — generic execution seam (implemented; Goal 002 review surface)

1. Add focused tests reproducing the fixed-dispatch and newborn-`patch_id`
   failures.
2. Implement validated process/result constructors and the single generic
   ordered execution loop.
3. Implement the locked RNG, field, event and interval/census contracts.
4. Port only the minimal grizzly demographic processes.
5. Repair newborn initialization through downstream field validation.
6. Remove the obsolete dispatcher and update affected callers without
   compatibility adapters.

Acceptance: a project-defined observer or management process runs without a
controller edit; accounting and serial/parallel reproducibility pass; simulated
means match an independent expected-value oracle within stated Monte Carlo
error.

### Stage 2 — canonical grizzly benchmark

Implement baseline, alternative female-survival and targeted human-mortality
scenarios. Demonstrate process reordering, observation, immigration,
order-falsification, stochastic calibration, event accounting and reproducible
provenance. Do not present empirical grizzly defaults without a separate
parameter-evidence goal.

### Stage 3 — high-value module migration

Port density, dispersal, supplementation and optional genetics through the same
contract. Remove privileged channels as each is replaced. Test output
equivalence only where semantics intentionally remain the same.

### Stage 4 — workflow reconnection

Reconnect YAML compilation, uncertainty, sensitivity, calibration, targets and
reporting after the process engine and grizzly benchmark are accepted. YAML
remains parameter configuration, not a lifecycle language.

## Historical accomplishments

Earlier work established a functioning R package, schema-v3 scenarios,
rate-based reproduction, channel-specific density, spatial/genetic summaries,
uncertainty and calibration helpers, reproducible targets/Quarto workflows, and
published R 4.6.1 CI evidence. Detailed status and validation remain in the
historical roadmap, decisions, logs and artefacts. They are not active
workstreams and should not be extended ahead of Stages 1–2.

## Stop rule

Do not begin another horizontal feature family, release exercise, or interface
platform before Stages 1–2 pass. Publication, tags and releases require separate
authority.
