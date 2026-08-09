# Goal 004 log

## 2026-08-09 - authorised start

- Barry accepted density as the first Stage 3 tranche and clarified that
  future genetics should track pedigree rather than infer `F` from observed
  heterozygosity.
- Starting state was clean `main...origin/main` at published Goal 003 commit
  `b712bdb`.
- Repo-local authority and the live process, callback, density and validation
  surfaces were inspected. The existing declared `globals.*` field contract is
  sufficient; no core-engine change is required.
- Publication remains unauthorised.

## 2026-08-09 - core implementation and focused acceptance

- Added `density_snapshot_process()`, which writes the exact positioned living
  count to `globals.density_n_alive` and emits a `density_snapshot` event
  without population or ID mutation.
- Added pure `ceiling_density_multiplier(n_alive, capacity)` with exact neutral
  behavior at zero and at/below capacity and `capacity / n_alive` above it.
- Removed the controller-era density specification, evaluator and ceiling
  closure API without aliases, along with obsolete focused tests and help.
- Added `grizzly_density_extension_scenario()` as a non-canonical,
  source-labelled synthetic fixture. It explicitly composes the snapshot in
  baseline survival, breeding and fecundity callbacks; the five canonical
  Goal 003 scenarios remain on their unchanged construction path.
- Added analytic/binomial and compound Bernoulli-Poisson expectation tests,
  exact snapshot/order/accounting tests, neutral equivalence, missing-upstream
  failure, repeatability, event provenance and serial/fork identity.
- Focused density suite: **62 passed, 0 failed, 0 warnings, 0 skipped**.
- Current-facing design/API/plan/decision documents now record the accepted
  Stage 3 order and pedigree-first genetics direction.

## 2026-08-09 - focused self-review and repair

- Confirmed the core execution engine is unchanged: density is one ordinary
  `globals.*` writer and all consumers use the existing declared-field seam.
- Confirmed canonical Goal 003 scenario construction contains no density
  snapshot; the new grizzly fixture is a separate explicitly non-canonical
  constructor.
- The review found one material interpretation ambiguity: applying the same
  multiplier independently to breeding probability and fecundity makes their
  combined expected-birth effect multiplicative. Current design text and the
  fixture metadata now state this explicitly, and focused tests distinguish
  breeding-only, fecundity-only and combined expectations.
- No further review loop was started under the 80/20 stop policy.

## 2026-08-09 - final gates

- Focused density suite: **62 passed, 0 failed, 0 warnings, 0 skipped**.
- Retained full suite: **329 passed, 0 failed, 0 warnings, 0 skipped**.
- Isolated `R CMD build --no-build-vignettes`: succeeded.
- Isolated `R CMD check --no-manual --no-build-vignettes`: **Status: OK** under
  R 4.6.1 on Apple Silicon macOS.
- The isolated temporary build/check directory was removed.
- `git diff --check` and final intended-surface/artifact scans are recorded at
  handoff; no staging, commit or push was performed.

Residual limitations are deliberate. Capacity and all grizzly extension values
are synthetic and uncalibrated; the single snapshot is global and synchronous;
patch density, lags and density inference remain deferred. Historical records,
artifacts and the explicitly deferred Quarto/release-evidence entry points still
contain pre-realignment density names and were neither migrated nor run in this
goal. The pre-existing `renv` out-of-sync advisory was not reconciled.

## 2026-08-09 - narrow extension audit repair

- The audit identified an evidence gap rather than a production defect: the
  independent expectation fixtures tested the same scientific contract but did
  not directly exercise the callbacks shipped by
  `grizzly_density_extension_scenario()`.
- Added a direct callback oracle after the extension's real positioned `N = 10`
  snapshot with illustrative capacity `5` and neutral environment. The shipped
  callbacks return breeding `0.35`, fecundity `0.40`, dependent survival
  `0.39`, independent-female survival `0.465` and independent-male survival
  `0.455` exactly.
- Added a matched high-capacity run showing that, under the same seed, the
  shipped extension returns exactly the baseline final populations, census and
  non-density events after accounting for the expected process-index shift,
  while adding one snapshot event per run and interval.
- No production or public API change was required.
- Focused density suite: **74 passed, 0 failed, 0 warnings, 0 skipped**.
- Retained full suite: **341 passed, 0 failed, 0 warnings, 0 skipped**.
- Fresh isolated build succeeded and fresh isolated package check returned
  **Status: OK** under R 4.6.1; the temporary directory was removed.

## 2026-08-09 - accepted; publication authorised

- Barry accepted Goal 004 after the narrow extension audit repair.
- Publication of the accepted Goal 004 change set is authorised.
- This entry records authority only; no commit or push has yet been performed.
