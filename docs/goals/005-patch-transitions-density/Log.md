# Goal 005 log

## 2026-08-09 - authorised start

- Barry accepted patch transitions and patch-specific density as the next
  Stage 3 tranche.
- Starting state was clean `main...origin/main` at published Goal 004 commit
  `122e8dd`.
- Repo-local authority and the current process, density, spatial, reproduction,
  public API and test surfaces were inspected.
- The existing generic process contract appears sufficient; any need to modify
  the core engine will trigger a pause rather than scope expansion.
- Publication remains unauthorised.

## 2026-08-09 - core implementation and focused acceptance

- Replaced patch initialisation with an explicit-only contract over an ordered
  positive-integer domain. Empty populations and empty declared patches are
  valid; fractional, missing, non-positive and unknown identifiers fail.
- Added `dispersal_process()` with living/eligibility filtering, simultaneous
  decisions against one pre-process state, strict destination validation and
  aggregate `patch_transition` events including diagonal retention.
- Added `markov_dispersal_process()` over a domain-aligned row-stochastic
  matrix. Entries and row sums are validated without normalisation; no
  empirical/default matrix is supplied.
- Added `patch_density_snapshot_process()` with full-domain keyed counts and
  zero-count events, plus `patch_density_multiplier()` for exact keyed
  count/capacity validation through the accepted ceiling multiplier.
- Removed without adapters the old apply/default/Markov dispersal helpers,
  three fixed regimes, two convenience initialisers and their exported help.
- Deleted the 515-line `R/spatial_summary.R` history-inference suite. Current
  reference and design documents now treat process events as movement evidence.
- The process engine and demographic production code were not changed.
- Initial focused spatial suite: **71 passed, 0 failed, 0 warnings, 0 skipped**.

## 2026-08-09 - focused self-review and repair

- Reviewed state ownership, simultaneous callback semantics, transition
  aggregation, creation-field preflight, keyed density lookup and stochastic
  provenance against the Goal 005 contract.
- Found no production architecture, accounting or scientific-contract defect.
- Added missing decisive evidence for empty-population patch snapshots and
  exact deterministic Markov identity/swap matrices, and added a clear error
  for malformed initial population records.
- No second review loop was started under the 80/20 stop policy.

## 2026-08-09 - final gates

- Focused spatial suite: **80 passed, 0 failed, 0 warnings, 0 skipped**.
- Retained full suite: **411 passed, 0 failed, 0 warnings, 0 skipped**.
- Isolated `R CMD build --no-build-vignettes`: succeeded.
- Isolated `R CMD check --no-manual --no-build-vignettes`: **Status: OK** under
  R 4.6.1 on Apple Silicon macOS.
- The isolated temporary directory was removed.
- `git diff --check` passed. The exact public-surface check found all five
  intended spatial functions and none of the eight retired exports; active
  R/tests/NAMESPACE/help/current-doc scans found no stale retired call sites.
- Historical decisions, logs, NEWS and artifacts retain former names for
  provenance. The deferred Quarto demo also retains old calls and was not run;
  Stage 4 reconnection must rewrite it rather than motivating adapters.
- No staging, commit or push was performed.

Deliberate residual limits are discrete patch labels, one transition per
declared process position and phenomenological local density feedback. There is
no continuous landscape, distance/path/cost/mortality model, empirical
connectivity default, spatial summary convenience layer, supplementation,
gene-flow inference or pedigree implementation. The pre-existing `renv`
out-of-sync advisory was not reconciled.

## 2026-08-09 - narrow acceptance-audit repair

- The acceptance audit found that the Markov destination closure captured its
  construction-time domain and matrix while separate mutable values were
  exposed in `process$params`. Inspected parameters could therefore diverge
  from executed biology and a mutated matrix was not revalidated.
- The effective Markov domain and matrix now live together in
  `process$params$destination_model`, and the destination draw consumes that
  bundle at execution. A process-level `validate_params` function revalidates
  the domain, matrix shape/dimnames/probabilities/row sums and agreement with
  the process domain during normal process and scenario validation.
- The modeller's original `params` remain unchanged in `process$params$model`
  and are still passed to the eligibility callback. No engine or generic
  process abstraction was added.
- Regression tests prove that an invalid mutated matrix fails process and
  scenario validation, a valid changed matrix controls realised transitions,
  and a mismatched effective domain fails.
- `patch_density_multiplier()` now requires exactly one `patch_id` before
  normalisation; zero- and multiple-value inputs have explicit regression
  tests.
- Focused spatial suite: **89 passed, 0 failed, 0 warnings, 0 skipped**.
- Retained full suite: **420 passed, 0 failed, 0 warnings, 0 skipped**.
- Fresh isolated build succeeded and fresh isolated package check returned
  **Status: OK** under R 4.6.1; the temporary directory was removed.
- This repair remained unstaged and unpublished.

## 2026-08-09 - accepted; publication authorised

- Barry accepted Goal 005 after the narrow acceptance-audit repair.
- Publication of the reviewed Goal 005 change set is authorised.
- This entry records authority only; no publication commit is claimed here.
