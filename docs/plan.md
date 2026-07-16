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
    artefact bundles through `artefacts/WP-2B.6/`.
- Core simulation/controller status:
  - `run_basic_simulation()` / `run_basic_simulation_replicates()` support
    optional `record_population_history` capture for time-series spatial/genetic
    summaries.
  - Reproduction uses a single explicit baseline-rate pathway:
    `breeding_prob_fun` + `fecundity_lambda_fun` with controller-owned draws.
  - Density is configured explicitly through `density_spec()` and
    channel-specific YAML `density` blocks.
- YAML scenario status:
  - YAML ingestion (`read_scenario_yaml()`) now targets a single canonical
    `schema_version: 3` with explicit demography, density, management, and
    uncertainty blocks.
  - Packaged spatial/genetic scenario trio added under `inst/extdata/`:
    fragmented, connected, and asymmetric flow regimes.
- `targets` pipeline status:
  - Core targets remain runnable; smoke runs are used as reproducibility gates
    in artefact cycles and CI-heavy profile.
  - Default demo targets are intentionally smoke-sized for laptop-friendly
    fresh-checkout validation rather than heavy ensemble benchmarking.
- Quarto demos status:
  - Quarto project renders to `quarto/_site`.
  - Demo now includes spatial/genetic interpretation workflow guidance:
    endpoint vs time-series vs connectivity diagnostics.
- Tests status:
  - The canonical suite is green under R `4.6.1` (`532` pass, `0` fail,
    `0` warn, `0` skip).
  - Regression coverage targets retained controller behaviour, canonical YAML,
    spatial/genetic summaries, output contracts, and seeded reproducibility.
  - Package-native test entrypoint is `Rscript scripts/run_tests.R`, avoiding
    an unnecessary hard dependency on `devtools` for fresh restores.
  - The current Mac/CI reproducibility baseline is Homebrew R `4.6.1`; see
    `docs/log/053_r461_macos_ci_readiness_closure.md`.
- Package check status:
  - Tarball-based `R CMD check --no-manual --as-cran` passes with `0` errors
    and `0` warnings (`2` known notes; see
    `artefacts/release_1.0.0-rc4/00check.log`).
- Known failing tests / TODOs:
  - No known failing tests in canonical invocation.
  - Priority Queue is currently exhausted through `WP-2B.6`; next execution
    requires roadmap promotion of additional WPs.

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
- Keep one canonical YAML schema and document it clearly.
- Tighten function resolution to OpenPVA-owned names or explicit `pkg::fun`.
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
4. Keep the retained public surface clean and explicit.
5. Extend YAML schema for reproduction EV once semantics are stable.
6. Update demos + add tests ensuring the current path behaves as expected.

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
  - The R `4.6.1` baseline closure is implemented and validated locally after
    completion of `WP-2B.6`. The queue remains exhausted, and publication is
    awaiting independent review and orchestrator acceptance.
- **Most recent milestone progress**:
  - Completed `WP-0.3.1` through `WP-2B.6`, including:
    - bootstrap baseline and artefact/log scaffolding,
    - reproduction/density API stabilization with compatibility layers,
    - spatial/genetic output expansion from final-time summaries to
      run/year/patch time-series and connectivity diagnostics,
    - seeded regression gates for spatial/genetic snapshot slices,
    - domain-sanity spatial/genetic scenario pack in `inst/extdata/`,
    - Quarto and reference-doc upgrades for scientific interpretation workflow,
    - uncertainty ensembles, sensitivity diagnostics, bounded calibration, and
      performance/documentation hardening through `Line 2B.x`.
  - Refreshed the local and CI reproducibility baseline to R `4.6.1` without
    changing package compatibility (`R >= 4.6.0`) or model behaviour; fresh
    evidence is in `artefacts/release_1.0.0-rc4/`.
- **Immediate next steps**:
  1. Complete independent review of the local baseline commits and the `rc4`
     evidence bundle.
  2. Push the accepted closure to `origin/main` after orchestrator acceptance;
     tag, release-note, and maintainer-release work remain separate open items.
  3. Promote a new roadmap tranche only after baseline publication is closed.
