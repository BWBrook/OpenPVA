# AGENTS: OpenPVA repository contract

This file is the highest-authority instruction for automated agents in this
repository. If another current-facing document conflicts with it, this file
wins. Historical roadmaps, decisions and logs record evolution; they do not
override the active North Star.

## Product authority

> The modeller defines the biological program; OpenPVA supplies the execution
> engine, reusable processes, scientific contracts, and reproducible analysis
> machinery.

Read before architecture or implementation work:

1. `docs/vision_and_scope.md`
2. `docs/architecture_core.md`
3. `docs/design/lifecycle_process_contract.md`
4. `docs/design/canonical_grizzly_reference_model.md`
5. `docs/design/realignment_gap_map.md`
6. `docs/goals/001-north-star-realignment/Goal.md`

`docs/gapps_heritage.md` supplies historical evidence, not an API to reproduce.

## Active architecture

OpenPVA's target is a programmable, inspectable PVA engine in R:

- a lifecycle is a direct ordered list of validated ordinary R process objects;
- processes declare parameters, required fields and written fields, and return
  state plus events;
- the engine owns time, replicate RNG streams, stable IDs, event collection,
  provenance and failure context;
- community processes compose through the public contract without controller
  edits or central registration;
- a minimal S3 tag may support printing or validation, but inheritance is not
  the protocol;
- there is no lifecycle DSL, global registry, plugin manager, dependency-
  injection framework, or S4/R6 process hierarchy.

The former six-label dispatcher has been removed. **Do not restore a fixed
label, controller biological conditional, privileged parameter channel, or
compatibility adapter.** All executable lifecycle work must compose through
the generic process seam.

Existing individual/population lists and scientific helpers may be retained
where they satisfy the target state, field, process, result and accounting
contracts. Do not redesign them speculatively.

## Scientific defaults for realignment

- Use one independently reproducible L'Ecuyer-CMRG stream per replicate,
  preassigned so serial and parallel execution match. Processes use ordinary R
  RNG calls but never `set.seed()`; the engine scopes and restores RNG state.
- Reserve and validate core engine field names and types. Ordinary named
  contributed attributes remain allowed. Birth and introduction processes must
  initialize every field required downstream or fail immediately.
- Processes declare `event_type`; the engine stamps `run`, `time`, phase,
  process position/name/occurrence and provenance. Accounting events cannot be
  suppressed. Aggregate detail is the default.
- Step `t` is interval `t -> t+1`. Processes and events use label `t`; time
  advances after the ordered list. Census is an explicitly positioned observer,
  apart from an optional initial census at `t = 0`.
- Use an independent life-table or matrix expected-value oracle to test
  stochastic means. Do not introduce a second aggregate/fractional population
  representation or native deterministic engine mode without demonstrated need.

## Development rules

- Work only within the explicitly authorised goal and paths. Preserve unrelated
  user or agent changes.
- Prefer the smallest ordinary-R implementation that satisfies the approved
  scientific contract. Avoid speculative abstraction and hidden state.
- Do not guess biological defaults. Parameter evidence, estimands, observation
  processes and inference scope belong to the modeller or named model fixture.
- No backwards-compatibility preservation is required. When an obsolete path is
  replaced, remove it and update its call sites, tests and current documentation
  together.
- Use `package::function()` for non-base calls under `R/`, tests and
  `_targets.R`; do not call `library()` or `require()` there.
- Do not call `install.packages()` outside `bootstrap_env.R`. New dependencies
  require explicit justification and environment updates.
- Add focused unit, integration, accounting and reproducibility tests for code
  changes. Validate real entry points in proportion to scientific risk.
- Keep `targets`, `renv`, Quarto and YAML as analysis/configuration machinery;
  they do not define the lifecycle protocol.

## Records and authority

Maintain `docs/plan.md`, `docs/decisions.md`, the active goal log, and relevant
scientific interpretation notes. The living plan must expose only current
operational work; completed roadmaps and logs remain historical.

Do not commit, push, release, or publish unless the current goal explicitly
authorises it. Ask Barry only for material scientific or strategic decisions,
not reversible implementation mechanics already settled by the active design.
