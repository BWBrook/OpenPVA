# OpenPVA Roadmap (Codex autonomy primitive)

## 1) Opening contract

When the human maintainer says **“Follow the roadmap”**, the Codex CLI agent must:

1. Open this file (`docs/roadmap.md`).
2. Select the **first unchecked** Work Package (WP) in the **Priority Queue** (top-to-bottom, strictly).
3. Complete that WP **end-to-end** (implementation + tests + docs + artefacts).
4. Mark the WP checkbox as completed (`[x]`) **in this file** and commit the change alongside the WP’s work.
5. Repeat until a **Milestone/Review Gate** requires stopping for PI review.

Priority changes are allowed **only** if:
- A rationale is recorded in `docs/decisions.md`, and
- A log entry is added in `docs/log/` describing the reorder and why.

If the Priority Queue is empty (all WPs are checked), Codex must **stop** and report that more work must be promoted into the queue.

---

## 2) Work Package Definition of Done (WP‑DoD)

A WP is **Done** only when all of the following are true:

- **Acceptance criteria** for the WP are met and validated.
- **Tests**:
  - All relevant unit/integration tests pass locally.
  - Any new behaviour has tests (or an explicit, documented reason why testing is not feasible).
- **Docs**:
  - Updated user‑facing documentation exists for any new/changed behaviour.
  - At minimum: a config/reference doc (e.g., YAML or function contract) **and** an “interpretation of outputs/assumptions” note (see `docs/interpretation_notes.md`).
- **Artefact Review Cycle** completed and logged:
  - A WP‑scoped artefact bundle exists under `artefacts/<WP-ID>/` (or `artefacts/release_<...>/` for release work).
  - The bundle contains evidence appropriate to the WP (e.g., check summaries, rendered demo outputs, example runs).
  - A short sanity‑inspection note is recorded (either in the WP artefact folder README or in `docs/interpretation_notes.md`).
- **Schema discipline**:
  - If the **YAML schema** changes: bump `schema_version`, implement a migration, and add migration tests.
  - If the **output schema** changes: document the change and add/adjust regression tests.
- **Repo hygiene**:
  - No stray debug prints, no commented‑out experiments, no broken links in docs.
  - CI remains green (or is updated as part of the WP so it becomes green).

---

## 3) Priority Queue (strict order)

### Line 0.3.x — MVP (buildable, testable, documented baseline)
- [ ] WP-0.3.1 — Bootstrap smoke-check + fill baseline run logs
- [ ] WP-0.3.2 — Package metadata hardening + generate man pages
- [ ] WP-0.3.3 — README quickstart correctness (remove placeholders; runnable snippets)
- [ ] WP-0.3.4 — CI baseline: R CMD check + tests + lint quality gate
- [ ] WP-0.3.5 — Quarto demo/site renders successfully (no broken nav; non-conflicting output dir)

### Line 0.4.x — Beta (schema + reproducibility contracts)
- [ ] WP-0.4.1 — YAML schema contract v1: introduce `schema_version` + validation + migration for legacy YAML
- [ ] WP-0.4.2 — Output schema contract: document + add regression tests for key returned objects
- [ ] WP-0.4.3 — Deterministic RNG interface: optional `seed` support for replicates + demos

### Line 0.5.x — Beta (reproduction refactor + reproduction EV)  **[contains large WPs]**
- [ ] WP-0.5.1 — DECISION: reproduction semantics + compatibility/deprecation policy
- [ ] WP-0.5.2 — New demography API: breeding probability (`p_breed`) functions + table builder (compat wrappers kept)
- [ ] WP-0.5.3 — New demography API: fecundity mean (`lambda`) functions + table builder (compat wrappers kept)
- [ ] WP-0.5.4 — Controller refactor: move reproduction draws into controller + reproduction EV/cat support **[Large]**
- [ ] WP-0.5.5 — YAML schema v2: reproduction semantics + `reproduction_ev` + migrations + tests **[Large]**
- [ ] WP-0.5.6 — Docs & demo refresh for reproduction refactor (README + Quarto + interpretation notes)

### Line 1.0.0 — General Availability (stabilize + release)
- [ ] WP-1.0.1 — Stabilize public API + semver/release policy + 1.0.0 versioning
- [ ] WP-1.0.2 — Release candidate artefact bundle + reproducibility evidence pack

---

## 4) Detailed Work Package specs

## WP-0.3.1 — Bootstrap smoke-check + fill baseline run logs

**Outcome**  
A trustworthy “starting point” record exists: the repo can be bootstrapped from a clean checkout, the current tests and a minimal demo run complete (or failures are clearly documented), and the baseline behaviour is captured in the repo logs.

**Scope**
- In scope:
  - Run a clean bootstrap cycle (environment + tests + minimal demo run) and record what happened.
  - Populate `docs/log/000_bootstrap.md` with real information.
  - Create a first entry in `docs/interpretation_notes.md` describing observed artefacts/behaviour.
  - Establish the `artefacts/` convention (create folder if absent) and store evidence.
- Out of scope:
  - Refactoring or feature work beyond what is required to make the smoke-check complete.
  - Large API changes.

**Acceptance criteria**
- `docs/log/000_bootstrap.md` is filled with:
  - timestamp/date,
  - environment notes (OS, R version, key tooling availability),
  - what was executed and the results (pass/fail),
  - a short “next actions” list.
- `docs/interpretation_notes.md` contains a dated entry summarising:
  - at least one toy scenario run (baseline) and what outputs looked like,
  - any obvious pathologies or surprises (or explicitly “none observed”).
- A WP artefact bundle exists at `artefacts/WP-0.3.1/` containing:
  - session info (R + package versions),
  - a brief test summary,
  - evidence of a minimal demo run (e.g., saved output objects or a small rendered figure).

**Artefact evidence**
- `docs/log/000_bootstrap.md` updated
- `docs/interpretation_notes.md` updated
- `artefacts/WP-0.3.1/` folder exists with evidence files

**Stop condition**
- Stop when the acceptance criteria above are met and the WP‑DoD is satisfied; do not “clean up more” beyond that.

---

## WP-0.3.2 — Package metadata hardening + generate man pages

**Outcome**  
OpenPVA behaves like a real R package: metadata is complete (no placeholders), roxygen documentation is generated and committed, and `R CMD check` passes for the current feature set.

**Scope**
- In scope:
  - Complete and correct `DESCRIPTION` (no placeholder text; correct dependencies; URLs).
  - Ensure roxygen2 outputs are present in-repo (`man/`).
  - Add missing standard release files required for production packaging (e.g., `NEWS.md`, `inst/CITATION`).
- Out of scope:
  - Implementing new modelling features.
  - Reproduction refactors or schema changes.

**Acceptance criteria**
- `DESCRIPTION` contains:
  - a non-placeholder, complete Description field,
  - correct `Authors@R` (real email or explicit decision to omit),
  - `URL` and `BugReports` fields if a public repo exists (or documented “TBD” policy in decisions),
  - accurate `Imports`/`Suggests` aligned with actual usage.
- `man/` exists with help files for exported functions (generated by roxygen2).
- `R CMD check` completes with **0 errors, 0 warnings** (notes acceptable only if documented and justified).
- `NEWS.md` exists with an initial entry describing the current baseline release line (0.3.x).
- `inst/CITATION` exists (even if minimal) so users can cite the package.

**Artefact evidence**
- `DESCRIPTION` updated
- `man/` directory added
- `NEWS.md` added
- `inst/CITATION` added
- `artefacts/WP-0.3.2/` includes an `R CMD check` summary/log excerpt and session info

**Stop condition**
- Stop when check passes and documentation artefacts are committed; do not expand scope into CI or docs site work.

---

## WP-0.3.3 — README quickstart correctness (remove placeholders; runnable snippets)

**Outcome**  
The README becomes a reliable “front door”: it provides a correct mental model, a working quickstart, and examples that match the current API and artefacts.

**Scope**
- In scope:
  - Remove placeholder content (e.g., “...” fragments) and fix broken markdown sections.
  - Ensure quickstart covers:
    - installing/restoring deps,
    - running tests,
    - running a basic scenario (R and YAML).
  - Align README claims with actual implemented behaviour.
- Out of scope:
  - Adding new features just to make the README more impressive.
  - Writing long-form tutorials (belongs to Quarto site).

**Acceptance criteria**
- README contains:
  - a clear install/dev setup section aligned with `renv`,
  - at least one minimal R example using `scenario_spec()` + `run_scenario()`,
  - at least one YAML example using `read_scenario_yaml()` + `run_scenario()`,
  - no placeholder ellipses that break code comprehension.
- Any code in the README is consistent with current exported function names and argument semantics.

**Artefact evidence**
- `README.md` updated
- `artefacts/WP-0.3.3/` contains evidence that the README examples were sanity-run (e.g., captured outputs or a short “example run” note)

**Stop condition**
- Stop when the README is coherent and examples match reality; avoid “polishing forever”.

---

## WP-0.3.4 — CI baseline: R CMD check + tests + lint quality gate

**Outcome**  
Every change is automatically validated: CI runs package checks and tests, and basic linting prevents obvious style/quality regressions.

**Scope**
- In scope:
  - Add CI that runs:
    - `R CMD check` (at least on Ubuntu; ideally on Windows + macOS too),
    - unit/integration tests,
    - linting (`lintr`) with an explicit config.
  - Make CI status visible (badge optional but recommended).
- Out of scope:
  - Coverage reporting (can be added later).
  - Running full targets pipelines in CI (may be too heavy; defer unless quick).

**Acceptance criteria**
- `.github/workflows/` exists with a workflow that:
  - restores dependencies in a reproducible way (`renv`-based),
  - runs `R CMD check` and fails on errors,
  - runs `testthat` as part of check,
  - runs `lintr` and fails on lint errors (with a repository-local config).
- CI passes on the default branch for at least one OS runner.

**Artefact evidence**
- `.github/workflows/<...>.yml` added
- `.lintr` (or equivalent) added
- `artefacts/WP-0.3.4/` contains a link or captured CI run summary (and any configuration notes)

**Stop condition**
- Stop when CI is reliably green and gating PRs/merges; do not expand into Quarto deployment.

---

## WP-0.3.5 — Quarto demo/site renders successfully (no broken nav; non-conflicting output dir)

**Outcome**  
Documentation rendering is not broken: the Quarto project renders successfully using only the pages that exist, and the output location does not clobber the repo’s `docs/` source markdown.

**Scope**
- In scope:
  - Make `quarto/_quarto.yml` consistent with actual `.qmd` files.
  - Ensure `quarto render` succeeds.
  - Ensure output directory is clearly defined and does not overwrite hand-written docs.
- Out of scope:
  - Writing a full tutorials/reference site (beyond minimal stubs needed to render).
  - Automated publishing (GitHub Pages) unless trivial.

**Acceptance criteria**
- Quarto render completes successfully for the project.
- The navbar only references pages that exist (or minimal stubs are added so links resolve).
- The rendered output directory is explicit and does not overwrite repo-authored `docs/*.md`.

**Artefact evidence**
- `quarto/_quarto.yml` updated (and any new `.qmd` stubs added if needed)
- `artefacts/WP-0.3.5/` contains proof of a successful render (render log excerpt + sample output files list)

**Stop condition**
- Stop once the site renders; do not expand into re-writing all documentation.

---

## WP-0.4.1 — YAML schema contract v1: introduce `schema_version` + validation + migration for legacy YAML

**Outcome**  
YAML scenarios are versioned and validated: the project can evolve the schema without silently changing meaning, and legacy YAML remains supported via explicit migration.

**Scope**
- In scope:
  - Define an initial YAML `schema_version` (v1).
  - Update `read_scenario_yaml()` to:
    - read/validate `schema_version`,
    - treat missing version as legacy (`0`) and migrate to v1.
  - Add validation errors that are actionable and specific.
  - Update demo YAML files to include `schema_version: 1`.
- Out of scope:
  - Reproduction EV YAML changes (reserved for 0.5.x).
  - Major restructuring of YAML beyond what’s needed for versioning.

**Acceptance criteria**
- YAML files in `inst/extdata/` include `schema_version: 1`.
- `read_scenario_yaml()`:
  - accepts YAML with `schema_version: 1`,
  - accepts legacy YAML without `schema_version` by migrating it (documented),
  - rejects unknown future versions with a clear error.
- Tests exist covering:
  - legacy YAML migration,
  - v1 validation failures (at least 2 representative error cases).

**Artefact evidence**
- Updated YAML demo files
- Updated YAML reference documentation (location of your choice under `docs/`)
- New/updated tests for YAML schema versioning
- `artefacts/WP-0.4.1/` includes a short migration evidence note (inputs → migrated structure)

**Stop condition**
- Stop once schema versioning + migration tests are in place; don’t extend schema content yet.

---

## WP-0.4.2 — Output schema contract: document + add regression tests for key returned objects

**Outcome**  
The core outputs become stable and test-protected. Users can rely on the structure of `run_basic_simulation*()` and `run_scenario()` results, and accidental breaking changes are caught automatically.

**Scope**
- In scope:
  - Document the output object shapes for:
    - `run_basic_simulation()`,
    - `run_basic_simulation_replicates()`,
    - `run_scenario()`,
    - key summaries (e.g., extinction summaries, trajectories).
  - Add regression tests for:
    - required columns and types in the per-year summary tibble,
    - presence/shape of `runs`, `summary`, `extinction` objects.
- Out of scope:
  - Adding new output fields just because.
  - Performance/benchmarking.

**Acceptance criteria**
- A documentation page exists describing output contracts and semantics (including units/meaning of fields).
- Tests fail loudly if required output columns/types disappear or change unexpectedly.
- Any “experimental” fields are explicitly labelled as such in docs.

**Artefact evidence**
- `docs/reference/output_schema.md` (or equivalent) added/updated
- Regression tests added/updated
- `artefacts/WP-0.4.2/` contains an example serialized output (small) or printed structure used for sanity

**Stop condition**
- Stop when output contracts are documented and protected by tests.

---

## WP-0.4.3 — Deterministic RNG interface: optional `seed` support for replicates + demos

**Outcome**  
Reproducibility becomes first-class: users can get repeatable results when they want them, and the demo pipeline/docs can be made deterministic to avoid confusing diffs.

**Scope**
- In scope:
  - Introduce an optional seeding mechanism for replicate runs (and/or scenario specs).
  - Ensure setting a seed yields identical results (within a fixed environment).
  - Update demos (`_targets.R`, Quarto) to use an explicit seed for stable outputs.
- Out of scope:
  - Cryptographic randomness guarantees.
  - Perfect cross-platform bitwise identity if R itself changes RNG implementations.

**Acceptance criteria**
- A user can provide a single `seed` (or equivalent) and obtain reproducible replicate summaries.
- Tests demonstrate determinism for a fixed seed (same outputs across two runs in the same session).
- Documentation explains how seeding interacts with:
  - replicates,
  - EV/cat stochasticity,
  - demographic stochasticity.

**Artefact evidence**
- Updated docs describing seeding
- Updated tests for determinism
- `artefacts/WP-0.4.3/` includes a small “before/after” determinism proof (two runs, identical digests or equivalent)

**Stop condition**
- Stop when deterministic behaviour is demonstrably available and documented.

---

## WP-0.5.1 — DECISION: reproduction semantics + compatibility/deprecation policy

**Outcome**  
A single, explicit design choice is recorded for reproduction refactor. The repo contains a decision describing the new semantics (probabilities/means + controller draws), the compatibility plan, and how YAML will evolve.

**Scope**
- In scope:
  - Finalise and record reproduction semantics decisions:
    - breeding specified as probability (`p_breed`),
    - fecundity specified as mean (`lambda`),
    - stochastic draws happen in the controller.
  - Define compatibility approach:
    - wrappers for legacy `breeding_fun`/`fecundity_fun`,
    - deprecation timeline and messaging.
  - Define how YAML v2 will represent the new semantics.
- Out of scope:
  - Implementing the refactor itself (begins in WP-0.5.2+).

**Acceptance criteria**
- `docs/decisions.md` includes a dated decision entry that specifies:
  - the chosen semantics and why,
  - public API names,
  - backward compatibility strategy,
  - what counts as a breaking change and how it will be communicated.
- `docs/design/reproduction_ev_semantics.md` is updated to match the decision and includes at least one worked example.
- A `docs/log/` entry records that this decision was made and what WPs it unlocks.

**Artefact evidence**
- Updated `docs/decisions.md`
- Updated `docs/design/reproduction_ev_semantics.md`
- New `docs/log/` entry referencing this decision

**Stop condition**
- Stop once the decision is recorded and internally consistent; do not start implementing until it exists.

---

## WP-0.5.2 — New demography API: breeding probability (`p_breed`) functions + table builder (compat wrappers kept)

**Outcome**  
The codebase gains a clean breeding-probability interface: table specs and functions return probabilities in [0,1], ready for reproduction EV and controller-level draws—while legacy helpers continue to work via wrappers.

**Scope**
- In scope:
  - Introduce new exported functions for breeding probability (naming per WP-0.5.1 decision).
  - Provide table-based builder(s) for probability tables.
  - Provide wrappers/adaptors so existing logical breeding APIs remain usable (with deprecation warnings if appropriate).
  - Add tests for:
    - table validation,
    - probability bounds,
    - wrapper compatibility.
- Out of scope:
  - Controller refactor and EV mechanics (WP-0.5.4).
  - YAML v2 changes (WP-0.5.5).

**Acceptance criteria**
- New breeding probability builder exists and is documented.
- Probability tables support sex/age intervals and reject invalid overlaps/ranges.
- Legacy `build_breeding_fun_from_table()` behaviour remains available (via wrapper) with documented semantics.

**Artefact evidence**
- Updated `NAMESPACE`/roxygen docs and new `man/` entries
- New/updated tests covering probability semantics and wrappers
- `artefacts/WP-0.5.2/` includes a small demonstration (table → function → expected p values)

**Stop condition**
- Stop once probability interface is in place and legacy wrappers/tests pass.

---

## WP-0.5.3 — New demography API: fecundity mean (`lambda`) functions + table builder (compat wrappers kept)

**Outcome**  
The codebase gains a fecundity-mean interface: table specs and functions return mean offspring number (`lambda`), ready for EV on lambda and controller-level Poisson draws—while legacy realised-count helpers continue to work via wrappers.

**Scope**
- In scope:
  - Introduce new exported functions for fecundity mean (lambda) (naming per WP-0.5.1).
  - Provide table-based builder(s) for lambda tables.
  - Provide wrappers/adaptors so existing realised-count fecundity APIs remain usable (with deprecation warnings if appropriate).
  - Add tests for:
    - lambda validation (non-negative),
    - default behaviour when no match,
    - wrapper compatibility.
- Out of scope:
  - Controller reproduction draw refactor and EV (WP-0.5.4).
  - YAML v2 changes (WP-0.5.5).

**Acceptance criteria**
- New fecundity lambda builder exists and is documented.
- Lambda tables validate correctly and return expected lambdas for age/sex intervals.
- Legacy `build_fecundity_fun_from_table()` remains available (via wrapper) with documented semantics.

**Artefact evidence**
- Updated `man/` entries for new API functions
- New/updated tests for lambda semantics and wrappers
- `artefacts/WP-0.5.3/` includes a small demonstration (table → function → expected lambda values)

**Stop condition**
- Stop once lambda interface is in place and all wrapper/legacy tests pass.

---

## WP-0.5.4 — Controller refactor: move reproduction draws into controller + reproduction EV/cat support **[Large]**

**Outcome**  
Reproduction becomes conceptually parallel to survival: baseline probabilities/means come from demography, year-level EV/cats are applied in the controller, and stochastic draws (Bernoulli/Poisson) happen centrally—without breaking existing scenarios.

**Scope**
- In scope:
  - Implement controller-level reproduction draws using:
    - breeding probability (`p_breed`) and
    - fecundity mean (`lambda`).
  - Add year-level environmental variation and catastrophe modifiers for reproduction (exact distribution per decision).
  - Maintain backward compatibility by supporting legacy `breeding_fun`/`fecundity_fun` paths (or by adapting them internally).
  - Add tests that cover:
    - probability bounding to [0,1],
    - EV/cat toggles behaving as expected,
    - deterministic behaviour under a fixed seed (from WP-0.4.3),
    - male scarcity/monogamy edge cases remain sensible.
- Out of scope:
  - Redesigning density dependence beyond current K/K_patches behaviour.
  - New spatial/genetic features.

**Acceptance criteria**
- New reproduction pathway exists and is used by default for new-style scenarios.
- Legacy scenarios (including YAML v1 demos) still run and produce plausible outputs.
- Reproduction EV/cat parameters are:
  - documented,
  - validated,
  - included in summary outputs (at least as year-level multipliers/flags).
- Test suite includes coverage for reproduction EV/cat and key edge cases.

**Artefact evidence**
- Updated controller docs and output schema docs reflecting new reproduction fields
- Updated tests for the new pathway
- `artefacts/WP-0.5.4/` includes a small reproduction-EV demonstration run and a note interpreting results

**Stop condition**
- Stop when compatibility is preserved, tests are green, and reproduction EV/cat is demonstrably working; do not move on to YAML v2 until this is stable.

---

## WP-0.5.5 — YAML schema v2: reproduction semantics + `reproduction_ev` + migrations + tests **[Large]**

**Outcome**  
YAML becomes capable of expressing the new reproduction semantics and EV configuration, while older YAML continues to work via migrations. The schema is versioned and enforced.

**Scope**
- In scope:
  - Introduce YAML schema v2 changes needed for:
    - breeding probability tables (`p_breed`),
    - fecundity lambda tables (`lambda`),
    - reproduction EV/cat configuration (`reproduction_ev` block or equivalent).
  - Implement migration from v1/legacy to v2 where feasible (or provide clear deprecation path).
  - Bump `schema_version` to 2 when v2 features are used.
  - Add tests that cover:
    - v1 YAML still works,
    - v2 YAML works and maps into new controller params,
    - migration correctness and failure modes.
- Out of scope:
  - Adding unrelated schema features.
  - Density-module YAML.

**Acceptance criteria**
- `read_scenario_yaml()` supports:
  - `schema_version: 1` (legacy semantics) and
  - `schema_version: 2` (new reproduction semantics),
  - with explicit errors for unknown versions.
- Demo YAML files include at least one v2 example exercising reproduction EV.
- Migration tests exist and cover at least:
  - a v1 → v2 upgrade path, and
  - a deliberate invalid YAML case with a clear error.

**Artefact evidence**
- Updated `inst/extdata/` with v2 YAML example(s)
- Updated schema reference docs describing v2
- Migration and validation tests added/updated
- `artefacts/WP-0.5.5/` includes evidence runs for both v1 and v2 YAML examples

**Stop condition**
- Stop once both schemas are supported with tests and docs; do not proceed to extra schema features.

---

## WP-0.5.6 — Docs & demo refresh for reproduction refactor (README + Quarto + interpretation notes)

**Outcome**  
User-facing materials reflect the new reality: documentation and demos explain reproduction semantics and EV, show how to use the new YAML/R interfaces, and clearly describe legacy compatibility and any deprecations.

**Scope**
- In scope:
  - Update README to reflect new reproduction semantics and any deprecations.
  - Update Quarto demo(s) to include a reproduction EV example and show both YAML v1 and v2 behaviour (if both supported).
  - Add an interpretation-notes entry describing observed behavioural changes and any assumptions.
- Out of scope:
  - Major new modelling features.
  - Density-module tutorials.

**Acceptance criteria**
- README examples match the new API and do not rely on deprecated behaviours without calling that out.
- Quarto render remains successful (WP-0.3.5 stays true).
- Documentation clearly answers:
  - “How do I specify breeding and fecundity now?”
  - “How do reproduction EV/cats work?”
  - “What happens to my old YAML?”
- `docs/interpretation_notes.md` includes a new entry after the refactor describing observed differences.

**Artefact evidence**
- Updated README and Quarto `.qmd` files
- Updated YAML and output schema docs as needed
- `artefacts/WP-0.5.6/` includes rendered demo outputs or excerpts showing reproduction EV behaviour

**Stop condition**
- Stop once docs align with the new system and users are not surprised by silent semantic changes.

---

## WP-1.0.1 — Stabilize public API + semver/release policy + 1.0.0 versioning

**Outcome**  
OpenPVA is ready for a 1.0 contract: stable public APIs are declared, deprecations are coherent, semver/release policy is explicit, and the package is versioned and documented accordingly.

**Scope**
- In scope:
  - Define “public stable API” vs “experimental” functions and document it.
  - Finalise semver policy and release policy in `docs/decisions.md`.
  - Bump package version to `1.0.0` and write release notes in `NEWS.md`.
  - Ensure CI gates and `R CMD check` are clean.
- Out of scope:
  - Adding new modelling features.
  - Density module implementation.

**Acceptance criteria**
- `docs/decisions.md` contains an explicit release/semver policy entry.
- `NEWS.md` includes a 1.0.0 entry summarising key features and any breaking changes.
- `DESCRIPTION` version is `1.0.0`.
- CI is green and `R CMD check` is clean (no errors/warnings).

**Artefact evidence**
- Updated `docs/decisions.md`, `NEWS.md`, `DESCRIPTION`
- `artefacts/WP-1.0.1/` includes check summaries and a short “RC sanity” note

**Stop condition**
- Stop when the repo meets the DoD and is in a release-candidate state; do not start post‑1.0 features.

---

## WP-1.0.2 — Release candidate artefact bundle + reproducibility evidence pack

**Outcome**  
A concrete, reviewable release bundle exists: someone can inspect and reproduce the release candidate, including package build/check evidence and demo outputs.

**Scope**
- In scope:
  - Produce a release artefact bundle with:
    - built package artefact(s),
    - check logs/summaries,
    - rendered Quarto outputs,
    - at least one canonical toy-scenario run output.
  - Record what was produced and how to reproduce it.
- Out of scope:
  - Actual publishing to CRAN/GitHub releases (human maintainer responsibility).
  - Long-term archival strategy.

**Acceptance criteria**
- A folder `artefacts/release_1.0.0-rc1/` exists containing:
  - built package artefact(s) (or a documented pointer if too large),
  - check summaries/log excerpts,
  - rendered Quarto outputs (or a manifest/pointer),
  - toy scenario output objects and a short interpretation note.
- `docs/log/` contains a release-candidate log entry referencing the artefact bundle.
- `docs/release_checklist.md` is updated to reflect what was completed.

**Artefact evidence**
- `artefacts/release_1.0.0-rc1/` created
- `docs/log/` entry added/updated
- `docs/release_checklist.md` updated

**Stop condition**
- Stop once the artefact bundle is complete and reviewable; do not attempt publication steps.

---

## 5) Milestone / review gates (when Codex must stop)

Codex must stop and request a PI review ZIP under any of these conditions:

1. **After completing an entire line/milestone**:
   - After all WPs in **0.3.x**, stop for PI review.
   - After all WPs in **0.4.x**, stop for PI review.
   - After completing **WP-0.5.1** (the decision), stop for PI review **before** implementing the refactor.
   - After all WPs in **0.5.x**, stop for PI review.
   - After all WPs in **1.0.0**, stop for PI sign-off.

2. **After any Large WP** (marked **[Large]**), stop for PI review immediately.

3. **After any 4 completed WPs**, stop for PI review even if the line is not finished (to limit drift).

4. **If a WP reveals a breaking ambiguity** that cannot be resolved with local repo evidence:
   - Record the question in `docs/questions_for_human.md`,
   - Stop and request human/PI input.
