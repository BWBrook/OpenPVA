# Goal 008 log

## 2026-08-14 - authorised start and contract lock

- Barry authorised Goal 008 after accepting the bounded Stage 3 lean review;
  Goal 009 remains a separate later tranche and publication is not authorised.
- The repository started clean and converged at
  `276c56811df3463435f07c6bcd577af7c611cb1f` on `main...origin/main`.
- Repo-local authority, the lifecycle contract, Goals 002 and 004-007, active
  engine/demography/creator/pedigree code, callers, help and focused tests were
  inspected before implementation.
- The selected design uses one pre-process value inside survival/reproduction
  and one plain execution-local metadata list. It adds no hidden cache,
  controller branch, framework or population representation.

## 2026-08-14 - core implementation and focused evidence

- Survival now stages all decisions against one pre-state and applies deaths
  together. Reproduction gives all callbacks the same pre-state/population,
  advances only the scalar allocator while staging records, then appends all
  newborns together in existing deterministic RNG and ledger order.
- `offspring_sex` is required. The former implicit 50:50 sampling was removed;
  the synthetic grizzly fixture now owns its explicit sampling callback and
  other active callers declare their rule.
- Public execution/allocation retain exact state validation. Actual replicate
  initial state is validated exactly, and any change to pedigree identity,
  parentage, status, coefficient or sex triggers exact full-ledger validation.
- Process structure, occurrence plan and required creator fields are prepared
  once per scenario execution; the field plan is checked once per actual
  replicate initial state. Runtime requirement, result, write, creation and
  accounting validation remains active each process/interval.
- The trusted allocator retains non-negative count, scalar positive `next_id`
  and overflow checks without rescanning the population per newborn.
- Initial focused evidence: pre-state/allocator **25/25**, scenario **12/12**
  and pedigree **109/109**, with no failures, warnings or skips.
- Per-newborn pedigree helper calls still reconstruct transient ancestry from
  the common pre-state. Avoiding that generically would require callback-
  specific memoisation or hidden state, so it remains an explicit residual.

## 2026-08-14 - full evidence and stop

- The combined process/scenario/density/grizzly/introduction/pedigree surface
  passed **461/461** assertions with no failures, warnings or skips.
- The retained full suite passed **617/617** in **36.4 seconds**, with no
  failures, warnings or skips. No tests were removed or pruned. For context,
  the prior Goal 007 publication run took 70.0 seconds; current density and
  grizzly contexts took 14.4 and 10.4 seconds respectively.
- Isolated R 4.6.1 `R CMD build --no-build-vignettes` succeeded and
  `R CMD check --no-manual --no-build-vignettes` returned **Status: OK** on
  Apple Silicon macOS. The temporary `/tmp/openpva-goal008.Aneev9` directory
  and all build/check products were removed.
- `git diff --check` and active-caller/default/compatibility scans passed. Every
  executable `reproduction_process()` caller supplies `offspring_sex`; no
  constructor fallback remains. No repository build/check artefact was created.
- One focused self-review found no material defect and no repair loop was
  started. The controller-free seam, exact accounting, sequential RNG,
  serial/fork identity, density, patch, introduction and pedigree contracts
  remain protected.
- The known `renv` out-of-sync advisory was observed and deliberately not
  reconciled. No staging, commit, push, tag, release or publication occurred.

## 2026-08-14 - material trusted-result audit repair

- Independent review found one material gap in the trusted result boundary:
  skipping repeated pedigree topology work also allowed a process to remove a
  structurally required field such as `alive`, report matching death accounting
  and escape immediate rejection because `alive` is correctly not a lineage
  coefficient change.
- Added one cheap field-presence pass for every pedigree-enabled process result.
  Every record must retain `id`, `sex`, `alive`, both parent IDs,
  `pedigree_status` and `pedigree_F`; existing core scalar/type checks remain
  authoritative. This does not rebuild pedigree topology or coefficients.
- Added a direct falsification process that removes `alive` and emits matching
  death accounting. It now fails at the process result boundary. Ordinary
  mortality still changes only `alive` values and does not trigger exact
  ancestry reconstruction; actual identity, sex, parentage, status or
  coefficient changes remain exactly audited.
- Post-repair focused evidence: pre-state **25/25** and pedigree **112/112**.
  A call-count regression proves ordinary certain mortality performs one exact
  public-entry ancestry audit and no result-boundary coefficient replay.
- Post-repair retained full suite: **620 passed, 0 failed, 0 warnings, 0
  skipped** in **36.7 seconds**. Fresh isolated R 4.6.1 build succeeded and
  `R CMD check --no-manual --no-build-vignettes` returned **Status: OK**.
  Temporary products were removed; no further polish pass was started.
