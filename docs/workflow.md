# OpenPVA workflow: artefact review and iteration

OpenPVA is not “just code”; it produces stochastic simulation artefacts.
Therefore we require an **Artefact Review Cycle** analogous to scientific result-checking.

This workflow is mandatory for the Codex agent.

## 1) What counts as an artefact?

- simulation outputs (summary tibbles, extinction summaries),
- YAML scenario behaviour,
- targets pipeline outputs,
- Quarto demo render outputs (figures/tables),
- test outputs,
- documentation pages.

## 2) Cycle: Build sanity → Domain sanity → Interpretation → Iteration

### Step A — Build sanity (technical)
For significant changes (especially refactors), run:

- package/test checks (as appropriate for repo structure),
- unit tests and integration tests,
- at least a minimal `targets` run,
- Quarto render smoke test if feasible.

Record in `docs/interpretation_notes.md`:
- what was run,
- pass/fail,
- any warnings that matter.

### Step B — Domain sanity (PVA behaviour)
Create/maintain a small set of deterministic “toy” scenarios and check:

- probabilities remain within bounds [0,1],
- no `NA`/`NaN` propagation in summary outputs,
- population size and extinction behave sensibly under:
  - zero EV/cats vs non-zero EV/cats,
  - no management vs harvest/supplementation,
  - no dispersal vs Markov dispersal,
  - genetics on/off (if included).

These sanity checks should be encoded as tests where possible.

### Step C — Interpretation (what the artefacts are telling you)
For each meaningful change:

- inspect key output columns (e.g. EV multipliers, catastrophe indicators, harvested/supplemented counts),
- inspect at least 1–2 plots from the demo pipeline (mean trajectories, occupancy, etc.),
- write notes in `docs/interpretation_notes.md`:
  - what changed,
  - what behaviour you observed,
  - what seems suspicious,
  - follow-up actions.

### Step D — Iteration
If behaviour is suspicious or inconsistent:
- add missing tests,
- adjust implementation,
- rerun the cycle.

Do not “paper over” suspicious outputs with narrative.
Fix or explicitly document limitations.

## 3) How this connects to other docs

- `docs/plan.md` — update whenever you change milestone scope, APIs, or priorities.
- `docs/decisions.md` — record non-trivial design choices.
- `docs/log/*` — chronological record of what you did and why.
- `docs/questions_for_human.md` — only when blocked.

## 4) CI profile usage

OpenPVA CI is split into two validation profiles:

- `ci-fast`: pull request and `main` push gate (lint + tests + package check).
- `ci-heavy-validation`: scheduled/manual workflow for heavier reproducibility
  checks (`targets`, Quarto render, schema/seed regressions, and `--as-cran` check).

Profile definitions and local command equivalents are documented in
`docs/reference/ci_profiles.md`.
