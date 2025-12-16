# OpenPVA plan and roadmap (agent-maintained)

> This file is a living roadmap. The Codex agent must keep it current.

## 1) Purpose

OpenPVA is a transparent, modular, reproducible individual-based PVA framework in R,
built around `renv` + `targets` + Quarto + YAML scenarios.

The aim is production-quality research software:
stable core API, documented scenario schema, strong tests, and reproducible demos.

## 2) Current status (to be filled by the agent)

- Repo structure summary:
- Core simulation/controller status:
- YAML scenario status:
- `targets` pipeline status:
- Quarto demos status:
- Tests status:
- Known failing tests / TODOs:

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
- **Most recent milestone progress**:
- **Immediate next steps**:
  1.
  2.
  3.
