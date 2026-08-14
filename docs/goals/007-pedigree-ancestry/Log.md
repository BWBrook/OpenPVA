# Goal 007 log

## 2026-08-14 - authorised start and contract lock

- Barry authorised the bounded pedigree/ancestry tranche, but not staging,
  commit, push, tag, release or publication.
- The repository started clean and converged at exact commit
  `e3bd94e8f950812373cbcdfdb8d2c059069f7dee` on `main...origin/main`.
- Repo-local authority, North Star, active architecture/lifecycle contracts,
  Goal 006, current plan/decisions and the birth, introduction, state, API,
  output and marker surfaces were inspected.
- The estimand is conditional pedigree IBD under an explicit founder base. The
  implementation uses numerator relationship `A` and therefore computes a
  newborn's `pedigree_F` as `A[mother,father] / 2`, not `A[mother,father]`.
- The selected production design is exact ancestor tracing through the
  `A = T D T'` decomposition. Parent row indexes, prior inbreeding and
  Mendelian-sampling variances are linear in pedigree size; contribution
  vectors are transient. No relationship matrix is retained.
- Pedigree remains optional. If enabled, every record must explicitly declare
  `base_founder` or `known_parentage`; partial/uncertain parentage is rejected.
- No scientific or architectural blocker was found. Implementation and focused
  tests are in progress.

## 2026-08-14 - core implementation and focused evidence

- Added optional complete pedigree state with explicit `base_founder` and
  `known_parentage` declarations, strict two-earlier-parent topology and exact
  numeric `pedigree_F` validation. Non-pedigree records, including the
  canonical grizzly fixture's partial maternal records, remain valid.
- Added public initialisation/validation, founder, newborn and known-parentage
  creator-field helpers plus tidy ledger and summary outputs. Birth and
  introduction composition uses existing callbacks and exact field
  declarations; known-parentage same-batch introductions fail.
- Production uses exact sparse ancestor contributions under `A = T D T'` with
  a linear ID/parent/F/D index. Public IDs are distinct from row positions and
  no relationship matrix, shared cache, class hierarchy or second population
  representation was added.
- Removed generic `alleles` and ambiguous `F`, all four marker-derived helper
  exports/implementations/help pages, the focused legacy marker test and the
  missing-F-as-zero fitness response without adapters.
- Dense independent numerator-relationship tabulation agrees over 30 generated
  pedigrees and all hand anchors: unrelated offspring 0; half-sib 0.125;
  full-sib and parent-offspring 0.25; first cousin 0.0625; factor-sensitive
  full-sib backcross 0.375.
- Focused pedigree suite: **105 passed, 0 failed, 0 warnings, 0 skipped**.
  Birth: **4/4**; introduction: **77/77**; grizzly: **106/106**.

## 2026-08-14 - material self-review and scaling repair

- The one focused review found redundant full-pedigree replays in per-newborn
  allocation/callback paths, duplicate interval preflight, unchanged process
  results and zero-birth creators. These were material scale defects.
- Vectorised stable-ID parent lookup, made parent contributions sparse, derived
  D linearly from the already validated creator pre-state, and reserved exact
  full-ledger coefficient verification for initial construction, explicit
  validation and actual lineage changes. Topology/type checks still run on all
  relevant state boundaries.
- Regression evidence proves age/census and zero-birth intervals cannot invoke
  full coefficient replay. An 800-record creator case appends a realised litter
  and remains exact.
- A fresh subprocess built **12,000 records**, **200 founders** and **12 shallow
  generations** with non-row public IDs. Exact initialisation took **7.955 s**;
  the retained matrix-free linear index was **433,072 bytes**; maximum RSS was
  **344,899,584 bytes** (below the declared 512 MB falsification bound); all
  coefficients were finite and in `[0,1]`. No elapsed-time assertion or
  performance framework was added.
- No second polish loop was started.

## 2026-08-14 - final gates

- Retained full suite: **584 passed, 0 failed, 0 warnings, 0 skipped**.
- Isolated `R CMD build --no-build-vignettes` succeeded. Isolated R 4.6.1
  `R CMD check --no-manual --no-build-vignettes` returned **Status: OK** on
  Apple Silicon macOS; the temporary build/check directory was removed.
- `git diff --check` passed. Retired definition/export/help scans, new public
  definition/export/help scans, controller/database/class and repository
  artefact scans were clean.
- `roxygen2` was absent from the project library, so help files were updated
  manually; package check verified documentation entries, usage and code/docs
  consistency. No dependency or environment change was made.
- The known `renv` out-of-sync advisory was observed and deliberately not
  reconciled. No staging, commit, push, tag, release or publication occurred.

Residual limits are deliberate: no marker loci, realised genomic IBD,
mutation/recombination/linkage, uncertain parentage, founder groups,
mate/mean-kinship management, fitness response, empirical calibration,
persistence or Stage 4 workflow reconnection.

## 2026-08-14 - public trust-boundary audit repair

- Independent audit reproduced a material trust-boundary defect after the
  scaling repair: public `execute_processes()` and `allocate_ids()` performed
  topology-only validation, so a raw or externally mutated state with a false
  but bounded `pedigree_F` could pass unchanged work.
- Restored exact coefficient validation at both public entry points. Added
  internal trusted execution and allocation helpers used only after exact
  replicate initialisation and by engine-owned birth/introduction continuation;
  realised lineage changes still trigger exact full-ledger validation.
- Direct regressions now reject an unrelated-founder child falsified from
  `pedigree_F = 0` to `0.25` through both public APIs. A call-count regression
  confirms a three-interval age/zero-birth/census scenario performs exactly one
  full initial pedigree audit rather than replaying it per interval/newborn.
- Post-repair focused evidence: pedigree **108/108**, process accounting
  **42/42**, birth **4/4**, introduction **77/77**. The known `renv` advisory
  remains deliberately unreconciled.
- Post-repair retained full suite: **587 passed, 0 failed, 0 warnings, 0
  skipped**. Fresh isolated R 4.6.1 build succeeded and package check returned
  **Status: OK**. `git diff --check` passed, the temporary check directory was
  removed, and no repository build/database artefact remains.

## 2026-08-14 - accepted; publication authorised

- Barry accepted Goal 007 after the bounded implementation, material repair
  and independent closure audit.
- Publication of the reviewed Goal 007 change set was authorised.

## 2026-08-14 - published

- The exact reviewed 42-path Goal 007 payload was committed as
  `17545d04ea8001b7b01f6dc4de509d7f7b685b7f` with message
  `feat: add exact pedigree ancestry` and pushed to `origin/main`.
- Fresh publication gates passed: retained full suite **587/587**, isolated R
  4.6.1 source build succeeded, and
  `R CMD check --no-manual --no-build-vignettes` returned **Status: OK**.
- The independent closure audit returned **ACCEPT** after directly verifying
  the public trust-boundary repair. `git diff --check`, exact staging and the
  temporary-artifact check were clean; the implementation payload contained
  1,843 insertions and 432 deletions with no unstaged residue.
- Push result was `e3bd94e..17545d0`; the live remote ref matched the full
  implementation commit. No tag or release was created.
- Goal 007 is closed. The next authorised activity is a bounded lean integration
  review of the completed Stage 3 tranche; no cleanup implementation or Stage 4
  reconnection is authorised by this record.
