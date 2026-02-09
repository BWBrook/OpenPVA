# OpenPVA plan and roadmap (agent-maintained)

> This file is a living roadmap. The Codex agent must keep it current.

## 1) Purpose

OpenPVA is a transparent, modular, reproducible individual-based PVA framework in R,
built around `renv` + `targets` + Quarto + YAML scenarios.

The aim is production-quality research software:
stable core API, documented scenario schema, strong tests, and reproducible demos.

## 2) Current status (to be filled by the agent)

- Repo structure summary:
  - Repository has a coherent R-package layout with lifecycle modules, scenario compilers, targets pipeline, and Quarto demo content.
  - First artefact bundle convention is now established at `artefacts/WP-0.3.1/`.
- Core simulation/controller status:
  - `run_basic_simulation()` and `run_basic_simulation_replicates()` execute successfully in smoke checks.
  - Reproduction design lock is complete (`WP-0.5.1`) and baseline probability/lambda APIs are in place (`WP-0.5.2`, `WP-0.5.3`).
  - Controller reproduction draws + reproduction EV/cat pathway are implemented (`WP-0.5.4`) with legacy compatibility preserved.
  - Density decision lock is complete (`WP-1.1.1`) and R-level density channel integration is complete (`WP-1.1.2`) with compatibility adapters retained.
- YAML scenario status:
  - YAML ingestion is present (`read_scenario_yaml()`), with demo files under `inst/extdata/`.
  - YAML schema v2 contract is implemented, with schema v1 retained and migration/adaptation coverage.
  - Optional top-level `seed` support is available for deterministic replicate outputs.
  - Density YAML schema support is implemented via optional `density` block with legacy `K`/`K_patches` compatibility retained.
- `targets` pipeline status:
  - Core targets remain runnable; heavy full-store runs are best treated as dedicated checks.
  - Replicate/scenario targets now use explicit seeds for stable artefacts.
- Quarto demos status:
  - Quarto project render path is stabilized and renders to `outputs/quarto_site`.
  - Demo snippets now include explicit seeds for deterministic example outputs.
- Tests status:
  - Canonical suite passes via `devtools::test()` (`461` pass, `0` fail).
  - Regression coverage now includes density API/channel behavior and legacy density compatibility.
- Package check status:
  - Tarball-based `R CMD check --no-manual --as-cran` passes with `0` errors and `0` warnings (`3` notes documented in `artefacts/WP-1.1.2/00check.log`).
- Known failing tests / TODOs:
  - No known failing tests in canonical invocation.
  - Priority queue is active; next unchecked item is `WP-1.2.1`.

## 3) Definition of Done for the next “reviewable milestone”

A milestone is “reviewable” when:

- `renv::restore()` works from a clean checkout (or equivalent documented process).
- Tests run and pass (or failures are explicitly documented + justified).
- `targets` pipeline runs cleanly (or a defined minimal subset).
- Quarto demo(s) render (or a defined minimal subset).
- The milestone has:
  - a short log entry in `docs/log/`,
  - interpretation notes in `docs/interpretation_notes.md`,
  - any key design choices recorded in `docs/decisions.md`.

## 4) Workstreams

### W1 — Core engine reliability
- Maintain invariants: individual/population representations, lifecycle module interfaces, controller semantics.
- Improve error messages and input validation where needed.
- Add regression tests for key engine behaviours.

### W2 — Scenario and YAML stability
- Keep legacy YAML compatible.
- Document schema and precedence rules (demography/management blocks overriding shorthand).
- Add tests for YAML parsing + scenario compilation + simulation run.

### W3 — Documentation and demos (Quarto)
- Ensure `quarto/basic_demo.qmd` remains runnable and reflects current APIs.
- Add short “How to” sections for:
  - demography tables,
  - EV/cats,
  - genetics,
  - spatial,
  - management comparisons.

### W4 — Testing and CI
- Maintain fast unit tests + a small set of integration tests.
- If CI exists, ensure it runs:
  - checks/tests,
  - minimal `targets` run,
  - optional Quarto render smoke test.

### W5 — Reproduction refactor (P5: semantics + EV)
Goal: move from “boolean breeder + realised counts” toward “baseline probabilities/means + controller draws”.
Deliverables (in order):

1. Design doc: `docs/design/reproduction_ev_semantics.md`
2. New interfaces:
   - `breeding_prob_fun` (or similar): returns p in [0,1]
   - `fecundity_lambda_fun` (or similar): returns λ ≥ 0
3. Controller path that applies year-level reproduction EV/cats and performs Bernoulli/Poisson draws.
4. Compatibility wrappers so legacy scenarios still run.
5. Extend YAML schema for reproduction EV once semantics are stable.
6. Update demos + add tests ensuring old and new paths behave as expected.

### W6 — Density module (post-refactor)
Goal: a pluggable density submodule that can scale multiple vital rates (survival, breeding, fecundity),
works with spatial structure, EV/cats, and management.
Deliverable starts with `docs/design/density_module.md`.

## 5) Milestones

### M0 — Baseline green build
Success criteria:
- `renv` restore works.
- Tests pass.
- Minimal `targets` run succeeds.
- Demo renders (or minimal subset).
- Docs/plan, docs/log, docs/decisions, docs/interpretation updated.

### M1 — Reproduction refactor design locked
Success criteria:
- `docs/design/reproduction_ev_semantics.md` exists and is coherent.
- Decision recorded in `docs/decisions.md` about interface approach and compatibility strategy.
- A small toy implementation exists behind a feature flag or alternate controller path (not breaking mainline yet).

### M2 — Reproduction refactor implemented + validated
Success criteria:
- New interfaces implemented.
- Controller draws moved into controller.
- Reproduction EV parameters supported (R-level).
- Legacy scenarios still run (or clear breaking-change notes if PI approved).
- Tests and demos updated.

### M3 — YAML reproduction EV support
Success criteria:
- YAML schema extended.
- YAML parser builds new interfaces.
- Tests cover YAML + reproduction EV + simulation behaviour.

### M4 — Density module (minimal viable)
Success criteria:
- Density modifiers interface implemented.
- At least one density function (e.g. ceiling/logistic) works for survival + reproduction.
- Tests and demos cover it.

## 6) Current phase and next steps (agent-maintained)

- **Current phase**:
  - Priority Queue execution complete through `WP-1.3.3`.
- **Most recent milestone progress**:
  - Completed `WP-0.3.1` through `WP-1.3.3`:
    - bootstrap baseline and artefact/log scaffolding,
    - package metadata hardening with clean `R CMD check` (0 errors/0 warnings),
    - README quickstart cleanup with runnable R and YAML examples and evidence runs,
    - CI baseline workflow with renv restore, lint gate, and tarball `R CMD check`,
    - Quarto project render stabilization with non-conflicting output location,
    - YAML schema v1 contract with legacy migration and version validation tests,
    - output schema contract docs and regression test coverage,
    - deterministic seed interface across replicates/scenarios/YAML with RNG restoration and regression tests,
    - reproduction semantics decision lock with compatibility policy,
    - new breeding probability and fecundity lambda APIs with legacy wrappers and tests,
    - controller-level reproduction draw pathway with reproduction EV/cat summary diagnostics,
    - YAML schema v2 reproduction semantics (`reproduction_ev` + migration/adaptation + v1/v2 coverage),
    - README + Quarto refresh documenting reproduction semantics, EV/cats, and YAML v1/v2 behavior,
    - semver/release policy lock + public API stability contract and `1.0.0` version bump,
    - release candidate evidence bundle (`artefacts/release_1.0.0-rc1/`) + checklist update,
    - density semantics decision lock (`DEC-005`) and implementation-ready design doc,
    - R-level density integration across survival/breeding/fecundity with compatibility coverage and artefact evidence,
    - YAML density schema support with parser tests, new packaged density v2 example, and migration/compatibility evidence,
    - CI profile split with explicit fast/heavy validation contracts and local-equivalent evidence capture,
    - reproducibility gate tightening with seeded snapshot regressions and expanded schema-output contract checks,
    - non-publishing release automation scaffold with scripted evidence generation,
    - reproduction feature extension with mate-required and mate-limited controls,
    - spatial/genetic final-time patch diversity summarization helper with regression coverage,
    - decision-support output expansion via final-abundance summaries and additive comparison metrics.
- **Immediate next steps**:
  1. Stop autonomous WP execution (Priority Queue exhausted).
  2. Await promotion of new WPs into `docs/roadmap.md` queue.
  3. Continue maintaining artefact/log/decision discipline for next line of work.
