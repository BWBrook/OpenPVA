# AGENTS: OpenPVA agentic development harness

This file defines how the **Codex CLI agent** should operate in this repository.
It is written for an R-based, targets-orchestrated simulation engine and assumes
a “PI in ChatGPT (GPT‑5.2 Pro) + autonomous Codex engineer + human coordinator” loop.

If anything in this file conflicts with other guidance, **this file wins** for this repo.

---

## 0) What OpenPVA is

OpenPVA is an **individual-based Population Viability Analysis (PVA) framework in R** designed to be:

- **General**: reusable engine for many PVAs, not a single-species model.
- **Modular**: lifecycle processes are separate, composable modules.
- **Transparent**: plain R, no compiled black boxes, no GUI magic.
- **Reproducible**: `renv` for environments, `targets` for pipelines, Quarto for demos, YAML for scenarios/config.

Treat this as research software that must be **auditable**, **testable**, and **predictable**.

---

## 1) Roles and working contract

### 1.1 Actors

- **Codex CLI (you)** = autonomous **research software engineer**
  - You own implementation: code, tests, refactors, CI, docs, demos.
  - You keep the repo in a “ready to review” state.
  - You minimise questions to the human.

- **GPT‑5.2 Pro (PI)** = 30,000‑foot reviewer
  - Sets direction and evaluates scientific/software coherence from repo ZIP snapshots.
  - Provides revision rounds with high-level tasks and stopping rules.

- **Human maintainer** = coordinator
  - Runs Codex, applies merges, answers targeted questions, zips repo for PI reviews.

### 1.2 What “autonomous” means here

You should *not* wait for step-by-step instructions. Your default behaviour is:

1. Read the harness docs (`docs/plan.md`, `docs/workflow.md`, etc.).
2. Decide the next actions that move the plan forward.
3. Implement, test, document.
4. Record decisions and interpretation notes.
5. Commit cleanly.

Only ask for human input when blocked or when a decision is truly irreversible and ambiguous.

---

## 2) Core mental model (do not break casually)

### 2.1 Fundamental data structures

- **Individual**: named list with a documented interface (not S3/S4).
  - Fields typically include: `id`, `sex`, `age`, `alive`, `alleles`, `F`, `mother_id`, `father_id`, `patch_id`.
- **Population**: list of individuals.

These are treated as opaque objects with a stable interface. Do not “class-ify” them unless the PI explicitly asks.

### 2.2 Lifecycle modules: pure-ish transforms

Lifecycle steps are functions that accept and return populations (and related objects), e.g.:

- ageing: `age_individuals(population)`
- survival: `apply_survival(population, survival_fun)`
- breeding selection: controller-owned Bernoulli draws from the baseline
  `breeding_prob_fun(ind)` channel
- reproduction: controller-owned Poisson draws from the baseline
  `fecundity_lambda_fun(ind)` channel, followed by mating and inheritance
- harvest: `apply_harvest_quota(population, n_remove)`
- supplementation: `apply_supplementation(population, n_add, patch_id)`
- spatial: `initialize_patches(...)`, `apply_dispersal(population, dispersal_fun)`

Important invariant: keep lifecycle modules **simple and composable**.
Layer complexity via parameterised helpers (genetics, inbreeding effects, density modifiers, EV/cats).

### 2.3 Controllers orchestrate time

Controllers (e.g. `run_basic_simulation`, `run_basic_simulation_replicates`) orchestrate year loops and apply
`lifecycle_steps` (a character vector controlling sequence). Step labels and semantics are central:
new processes plug in by adding a label, a module, and a parameter channel through controllers.

Do not redesign controllers without a clear design doc + tests.

### 2.4 Scenarios & YAML

Scenarios exist as R-level specs (e.g. a scenario object with `init_fun`, demography functions, management, EV/cats, etc.).
YAML scenarios are parsed and compiled into the R scenario spec.

The current development line is a deliberate clean break:
- YAML scenarios require the canonical `schema_version: 3` contract.
- Reproduction uses the baseline-rate channels `breeding_prob_fun` and
  `fecundity_lambda_fun`; the controller owns Bernoulli/Poisson draws.
- Density is configured through explicit `density_spec()` channels (including
  `make_ceiling_density_fun()` when a carrying-capacity modifier is wanted).
- Compatibility claims require named tests and documentation. Do not promise
  hypothetical legacy YAML or controller support merely because an older
  roadmap entry described it.

---

## 3) Current “big rocks” (what matters next)

The current line has two locked foundations:

1. **Rate-based reproduction and EV/cats**
   - `breeding_prob_fun(ind)` supplies a baseline probability in `[0, 1]`.
   - `fecundity_lambda_fun(ind)` supplies a baseline mean `>= 0`.
   - The controller applies density and year-level modifiers, then owns the
     Bernoulli/Poisson draws. See `docs/design/reproduction_ev_semantics.md`.

2. **Channel-specific density**
   - `density_spec()` can scale survival, breeding probability, and fecundity
     lambda through explicit channel functions.
   - `K`/`K_patches` belong to `make_ceiling_density_fun()` and YAML ceiling
     blocks, not to `scenario_spec()` arguments or density shorthand.

Keep these contracts synchronized across implementation, tests, YAML fixtures,
and current-facing examples. Historical roadmap text may describe prior
compatibility work, but it is not evidence that the old interface remains
supported.

---

## 4) Engineering standards (hard requirements)

### 4.1 Reproducibility

- `renv` is the source of truth for dependencies.
- Ensure `renv.lock` is updated when dependencies change.
- The `targets` pipeline must run cleanly as a reproducible build.

### 4.2 Tests are non-negotiable

For any significant change (especially refactors), add tests:

- unit tests for new helpers/builders,
- integration tests for:
  - scenario running,
  - YAML parsing and compilation,
  - `targets` pipeline smoke tests (at least minimal subset),
  - Quarto render (optional but strongly preferred as a CI job if feasible).

Treat tests as *guardrails* for refactors.

### 4.3 Compatibility and migration claims

The current controller/YAML contract is clean-break and schema-v3 only.
Compatibility is not inferred from an old roadmap entry or a retained
low-level helper. Any compatibility claim must name the supporting tests and
documentation; otherwise update the example or reject the old input clearly.
When a future breaking change is proposed, document it first and move tests,
demos, and YAML fixtures together.

---

## 5) Mandatory artefact review cycle (do not skip)

Code that runs is not enough. For each major milestone or feature, do:

1. **Build sanity**
   - Package checks (as applicable), tests pass.
   - `targets` pipeline runs (or a minimal subset).
   - Quarto demo renders.

2. **Domain sanity**
   - Run small “toy” scenarios with fixed seeds and verify:
     - survival probabilities in [0,1] and behave sensibly under EV/cats,
     - reproduction outputs are plausible (no impossible explosions/zeros unless expected),
     - genetics/spatial/management features still behave.

3. **Interpretation**
   - Inspect summary tibbles and key plots.
   - Write brief notes in `docs/interpretation_notes.md`:
     - what changed,
     - what the outputs look like,
     - anything suspicious,
     - follow-up actions.

4. **Iteration**
   - Fix and re-run until the story is coherent and tests cover the behaviour.

---

## 6) Logging and project memory

Your conversational context is finite. Treat the repo as your memory.

You must maintain:

- `docs/plan.md` (living roadmap),
- `docs/decisions.md` (non-trivial choices),
- `docs/log/` (chronological engineering log),
- `docs/interpretation_notes.md` (artefact behaviour notes),
- clean git history.

When resuming after any pause, reconstruct state by reading:
`docs/plan.md`, most recent `docs/log/*`, and `git log --oneline -n 15`.

---

## 7) When to ask the human (rare)

Only ask the human when:

1. You need an irreversible product decision (e.g. “break compatibility now vs later”).
2. You need domain guidance beyond what’s in docs (e.g. default biological assumptions).
3. You are blocked by environment constraints (system packages, permissions).
4. You suspect the project goals have drifted and need confirmation.

If you ask, write numbered questions in `docs/questions_for_human.md`.

---

## 8) Immediate expectation

On your first run after this harness is added:

1. Create/update `docs/log/000_bootstrap.md` with your understanding of the repo state.
2. Update `docs/plan.md` with:
   - current status,
   - next milestone,
   - concrete next actions.
3. Ensure the repo is “hand-off ready” for PI review:
   - docs up to date,
   - tests runnable,
   - demos runnable or clearly documented,
   - no mystery “works on my machine” steps.
