# OpenPVA plan and roadmap (agent-maintained)

> This file is a living roadmap. The Codex agent must keep it current.

## 1) Purpose

OpenPVA is a transparent, modular, reproducible individual-based PVA framework in R,
built around `renv` + `targets` + Quarto + YAML scenarios.

The aim is production-quality research software:
stable core API, documented scenario schema, strong tests, and reproducible demos.

## 2) Current status (to be filled by the agent)

- Repo structure summary:
  - Repository has a coherent R-package layout with lifecycle modules,
    scenario compilers, targets pipeline, Quarto demo content, and staged
    artefact bundles through `artefacts/WP-2A.6/`.
- Core simulation/controller status:
  - `run_basic_simulation()` / `run_basic_simulation_replicates()` support
    optional `record_population_history` capture for time-series spatial/genetic
    summaries.
  - Reproduction baseline-rate APIs, controller draws, EV/cat channels, and
    compatibility wrappers are implemented and regression-tested.
  - Soft-deprecation framework for selected legacy reproduction wrappers is
    active and migration documented.
  - Density module is integrated across survival/breeding/fecundity channels
    with compatibility adapters retained.
- YAML scenario status:
  - YAML ingestion (`read_scenario_yaml()`) supports schema v1/v2/v3 with
    additive uncertainty blocks in v3, plus density blocks, deterministic
    seeds, mate requirement toggles, optional history capture, and lifecycle
    function hooks (including `dispersal_fun`).
  - Packaged spatial/genetic scenario trio added under `inst/extdata/`:
    fragmented, connected, and asymmetric flow regimes.
- `targets` pipeline status:
  - Core targets remain runnable; smoke runs are used as reproducibility gates
    in artefact cycles and CI-heavy profile.
- Quarto demos status:
  - Quarto project renders to `outputs/quarto_site`.
  - Demo now includes spatial/genetic interpretation workflow guidance:
    endpoint vs time-series vs connectivity diagnostics.
- Tests status:
  - Canonical suite passes via `devtools::test()` (`649` pass, `0` fail).
  - Regression coverage includes spatial/genetic time-series helpers,
    connectivity diagnostics, deprecation behavior, YAML scenario-pack
    compatibility, output contracts, and seeded snapshot slices.
- Package check status:
  - Tarball-based `R CMD check --no-manual --as-cran` passes with `0` errors
    and `0` warnings (`3` known notes; see `artefacts/WP-2A.6/00check.log`).
- Known failing tests / TODOs:
  - No known failing tests in canonical invocation.
  - Priority Queue has been extended with `Line 2B.x` and now continues from
    `WP-2B.4` (after completing `WP-2B.1` through `WP-2B.3`).

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
  - Priority Queue extended to `Line 2B.x`; `WP-2B.1` through `WP-2B.3`
    completed, active execution startpoint is `WP-2B.4`.
- **Most recent milestone progress**:
  - Completed `WP-0.3.1` through `WP-2A.6`, including:
    - bootstrap baseline and artefact/log scaffolding,
    - reproduction/density API stabilization with compatibility layers,
    - spatial/genetic output expansion from final-time summaries to
      run/year/patch time-series and connectivity diagnostics,
    - seeded regression gates for spatial/genetic snapshot slices,
    - domain-sanity spatial/genetic scenario pack in `inst/extdata/`,
    - Quarto and reference-doc upgrades for scientific interpretation workflow.
- **Immediate next steps**:
  1. Execute `WP-2B.4` (sensitivity diagnostics: PRCC + OAT elasticity).
  2. Progress to `WP-2B.5` hindcast/calibration scaffold after diagnostics.
  3. Maintain artefact/log/decision discipline through the full `Line 2B.x`
     queue.
