# Log

## 2026-08-08 - Goal opened

- Barry accepted Goal 001 and authorised Stage 1.
- Starting repository: `main...origin/main` at `03d99b3` with the accepted,
  uncommitted Goal 001 documentation package (10 modified and 9 new files).
- Confirmed that fixed lifecycle labels currently cross the simulation
  controller, scenario/YAML surfaces, tests, targets and demonstrations.
- Chosen boundary: replace the direct R runtime and scenario surface with
  process objects; keep Stage 4 interface reconnection out of the new engine
  rather than introduce a compatibility adapter.
- No commit or push is authorised.

## 2026-08-08 - Implementation and acceptance

- Added ordinary-R state, process and result objects plus one generic ordered
  executor. The controller contains no biological process labels or branches.
- Replaced the public direct-R scenario route with an ordered process list and
  retired the fixed-label dispatcher, `run_basic_simulation*()` and
  `default_lifecycle_steps()` rather than retaining adapters.
- Added minimal age, survival, reproduction and census processes. Birth
  initialisation is owned by the reproduction process, and downstream required
  fields are validated both before execution and immediately after creation.
- The `patch_id` regression covers the missing-field preflight failure, a
  runtime process that lies about newborn fields, and a correct fixture that
  explicitly inherits maternal patch biology.
- RNG handling preassigns independent L'Ecuyer-CMRG streams and restores both
  `RNGkind()` and caller `.Random.seed` on success and error. Serial and real
  two-worker fork execution are byte-identical for ordered state, events and
  provenance.
- Seven focused acceptance areas cover RNG/restoration and serial-parallel
  identity; explicit time/census semantics; state, event and ID accounting;
  newborn fields; project-defined observer/management composition; and an
  independent one-interval expected-value oracle.
- Focused validation: `Rscript scripts/run_tests.R process` passed 25 tests
  with 0 failures, 0 warnings and 0 skips.
- Retained full suite: `Rscript scripts/run_tests.R` passed 161 tests with
  0 failures, 0 warnings and 0 skips. `renv` emitted its pre-existing
  out-of-sync advisory; no lockfile or environment reconciliation was in scope.
- Package validation under R 4.6.1: `R CMD build --no-build-vignettes` completed
  successfully, and `R CMD check --no-manual --no-build-vignettes` finished
  with `Status: OK`, including installation, load/unload, code, Rd, examples
  and package tests.
- `git diff --check` passed, and a production scan found no
  `lifecycle_steps` or `default_lifecycle_steps` in `R/`, `NAMESPACE` or
  `DESCRIPTION`.
- The package tarball and check directory created for validation were removed
  from the repository root after their results were recorded. Quarto,
  release-evidence and reproducibility automation were not run.

## Residual boundaries

- Stage 1 parallel execution uses `parallel::mclapply()` and therefore exposes
  a supported local fork path on Unix-alike platforms only. A cross-platform
  worker framework is deferred until a real interface requires it.
- YAML, spatial/genetic scenario constructors, and controller-coupled
  uncertainty, calibration and reporting entry points remain explicitly
  deferred to Stages 3-4. They were not translated through compatibility
  labels or expanded merely to preserve the obsolete controller surface.
- No empirical grizzly claim is made. The stochastic oracle is a bounded,
  matched synthetic one-interval data-generating process with an independent
  literal expectation and variance calculation.
- No commit or push was performed.

## 2026-08-08 - Narrow audit repair

The orchestrator's post-implementation audit identified four material contract
gaps. One bounded repair pass addressed them without reopening Stage 1.

- Locked the Stage 1 population representation as an append-only record ledger:
  existing positions and IDs are immutable, mortality/removal changes `alive`,
  and creators append consecutive engine IDs. Structural `population` writes
  are reserved for declared creators and no longer authorize undeclared changes
  to existing records.
- Added focused failures for an ID-only physical removal, record permutation,
  existing-ID mutation with neutral abundance, and same-ID wholesale record
  replacement. These checks do not depend on the presence of `alive`.
- `create_individual()` and `pva_state()` now validate integer-like ID, age,
  parent/patch ID and `next_id` inputs before coercion. Fractional and
  out-of-range values fail; accepted values retain exact integer types.
- Removed the defective legacy `apply_reproduction()` implementation and its
  public help/export rather than patching it. Its inseparable controller-only
  mate-limiting companion was removed with it. `reproduction_process()` remains
  the active reproduction route.
- Removed the controller-shaped OAT execution and public help/export rather
  than inventing process-parameter mutation. PRCC remains exported for direct
  draw-level tables or a list containing `per_draw`.
- Event records now reserve all engine-stamped fields, including `phase`, and
  reject duplicate names. Documentation now states that the process supplies
  `event_type`; the engine validates it and stamps run/time/phase/process
  position, name and occurrence.
- `roxygen2` was unavailable in the project environment, so source annotations,
  `NAMESPACE` and affected Rd pages were aligned directly. Package checking
  found no missing documentation or code/documentation mismatch.

### Audit validation

- Focused process suite: 58 passed, 0 failed, 0 warned, 0 skipped in 14.5 s.
- Retained full suite: 182 passed, 0 failed, 0 warned, 0 skipped in 14.8 s.
- Fresh isolated `R CMD build --no-build-vignettes` succeeded under R 4.6.1.
- Fresh isolated `R CMD check --no-manual --no-build-vignettes` completed with
  `Status: OK`, including installation, load/unload, code, Rd and package tests.
- `git diff --check` passed. Public-surface scans confirmed the three retired
  helpers are absent from `NAMESPACE`, production definitions and active Rd,
  while `reproduction_process()` and `summarise_sensitivity_prcc()` remain
  exported.
- The production zero-label scan again found no `lifecycle_steps` or
  `default_lifecycle_steps` in `R/`, `NAMESPACE` or `DESCRIPTION`.
- Temporary build/check outputs were removed after their evidence was recorded;
  no repository artefact was retained.
- The existing `renv` out-of-sync advisory remains outside this goal; no
  environment or lockfile reconciliation was attempted.
- Quarto, release-evidence and reproducibility automation were not run. No
  commit, push, stage, reset, clean or stash operation was performed.
