# OpenPVA living plan

## Authority and current objective

`docs/vision_and_scope.md` is the product authority. The current operational
programme has completed its three authorised Stage 3 migration tranches through
the accepted R-native lifecycle-process contract. The next decision is whether
to authorise a proposed Goal 007 pedigree/ancestry tranche; no Goal 007 work is
currently authorised.

The modeller defines the biological program. OpenPVA supplies execution,
reusable processes, scientific contracts, RNG/time/event provenance, validation
and reproducible analysis machinery.

## Current state

- Stage 0 was accepted and Stage 1 implemented the generic process seam.
- `scenario_spec()` and `run_scenario()` take a direct process list; the fixed
  dispatcher and `run_basic_simulation*()` surface are removed.
- Minimal age, survival, reproduction, generic introduction and census
  processes compose with project-defined observers or management processes.
- Birth and introduction processes explicitly declare created fields; missing
  downstream `patch_id` fails at preflight or runtime.
- YAML, targets, uncertainty/calibration execution, summaries and optional
  module scenarios are deliberately de-exported/deferred rather than adapted.
- Goal 003 supplies a synthetic, source-labelled and explicitly uncalibrated
  grizzly-like benchmark through ordinary process composition, with required
  scenario contrasts, annual survival variation, immigration/observation
  extensions and replicate-level summaries.
- Goal 004 replaces the disconnected density specification with an ordinary
  positioned global-abundance snapshot and one pure ceiling-style multiplier.
  Vital-rate composition remains explicit and modeller-owned; the accepted
  implementation is published at `122e8dd`.
- Goal 005 replaces controller-era spatial conveniences with explicit patch
  assignment, simultaneous event-emitting transitions and positioned full-
  domain patch counts. It is accepted and published at `003960a`.
- Goal 006 replaces the legacy supplementation helper and benchmark-specific
  creation loop with one source-labelled ordinary creator. Counts and complete
  newcomer state are modeller-owned; IDs and accounting remain engine-owned.
  It is accepted and published at
  `e7194c1bb524cd6726d5e1918b1ee200348adfa9`.
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

Implemented, accepted and published in Goal 003 as an illustrative synthetic fixture. Baseline,
alternative female-survival, targeted human-mortality and immigration
scenarios differ through process objects and parameters. The benchmark also
demonstrates annual survival variation, observation, mortality/reproduction
reordering, event accounting, stochastic expectation checks and reproducible
provenance. No value is an empirical grizzly default.

### Stage 3 — high-value module migration

The three authorised bounded tranches are implemented, accepted and published
through the same contract, with each obsolete surface removed rather than
adapted:

1. global density measurement and explicit vital-rate feedback (Goal 004,
   implemented, accepted and published);
2. patch-aware dispersal and patch-specific density (Goal 005, implemented,
   accepted and published);
3. generic exogenous introductions (Goal 006, implemented, accepted and
   published).

The next programme decision is whether to authorise a proposed Goal 007 for
optional pedigree/ancestry genetics. If authorised, pedigree and ancestry are
primary individual-based state; marker heterozygosity remains a separate
observable summary and must not define pedigree inbreeding. No Goal 007 packet
or implementation is claimed by this plan.

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
workstreams and should not be extended ahead of the current decision boundary.

## Stop rule

Do not create or begin the proposed Goal 007 pedigree/ancestry tranche, or move
to Stage 4 interface reconnection, without Barry's explicit authorisation.
Tags and releases require separate authority.
