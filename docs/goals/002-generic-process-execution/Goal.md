# Goal 002 - Generic process execution

## Objective

Replace the fixed lifecycle-label dispatcher with the smallest complete
ordinary-R process engine described by Goal 001. A modeller must be able to
compose, reorder and extend a biological program without editing OpenPVA's
controller.

## Required outcomes

1. Validated state, process and result objects implement the accepted field,
   event, time and context contracts.
2. One generic ordered loop executes all biological, management and observation
   processes.
3. Replicates use preassigned independent L'Ecuyer-CMRG streams and give
   identical results in serial and parallel while restoring caller RNG state.
4. Minimal age, reproduction, survival and census processes support the first
   grizzly-like demographic fixture without embedding empirical defaults.
5. Births and introductions fail immediately when they omit a field required
   downstream; a focused `patch_id` regression proves the repair.
6. A project-defined observer or management process composes without controller
   changes.
7. Population accounting, explicit census timing and an independent
   expected-value oracle are covered by focused tests.
8. The obsolete fixed-label dispatcher and its active call sites are removed,
   with no compatibility adapter.

## Scope

- Core process/state/result validation and execution.
- Minimal demographic and census process constructors.
- Generic R scenario construction and execution over a process list.
- Focused tests and current-facing documentation for this execution seam.
- Removal or explicit deferral of execution interfaces that still require the
  retired label dispatcher.

## Non-goals

- Empirical grizzly parameterisation or Stage 2 management scenarios.
- Migration of density, dispersal, supplementation, genetics, environmental
  variation, uncertainty, calibration, YAML or reporting workflows.
- A lifecycle DSL, registry, plugin manager, dependency injection, S4/R6
  hierarchy or deterministic population backend.
- Quarto, release-evidence or publication work.
- Commit, push, tag, release or other publication.

## Acceptance evidence

- Focused process, field, accounting, time/census, extension and RNG tests pass.
- A bounded stochastic fixture agrees with an independently calculated
  life-table/matrix expectation within a stated Monte Carlo tolerance.
- Serial and parallel replicated outputs are identical for the same root seed.
- `git diff --check` passes.
- The repository's proportionate full package test/check surface passes, or any
  unrelated inherited failure is recorded with exact evidence.
- Searches find no active `lifecycle_steps`, fixed-label dispatcher or
  controller biological branch in production R code.

## Authority and stopping rule

Barry accepted Goal 001 and authorised Stage 1. Reversible implementation
details are delegated. Pause only for a material scientific or product-scope
decision. Perform one focused self-review and repair pass, then stop when the
acceptance evidence is satisfied.
