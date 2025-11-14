# Repository Guidelines

This file defines how embedded coding agents (e.g. Codex CLI, ChatGPT-based tools) must behave when operating in the **OpenPVA** repository.

These rules are a short, enforced summary of the more detailed guidance in:

- `docs/overview_openpva.md`
- `docs/architecture_core.md`
- `docs/dev_conventions_r.md`
- `docs/gapps_heritage.md`
- `docs/roadmap_and_scope.md`
- `docs/agent_guidelines_codex.md`

Agents are expected to “load” those documents conceptually before editing code.

---

## 1. Purpose and Scope

OpenPVA is an open, modular framework for **Population Viability Analysis (PVA)** in R. It is intended to be:

- Transparent
- Reproducible
- Extensible
- Community-maintainable

Agents are here to assist with **implementation**, not to redefine the architecture or scope.

Current development phase: **Phase 1 – Core Demographic Engine**  
(See `docs/roadmap_and_scope.md`.)

---

## 2. Hard Constraints

When editing this repo, agents **must not**:

- Call `library()` or `require()` in any file under `R/`, `_targets.R`, or `tests/`.
- Call `install.packages()` or manage the package library anywhere except `bootstrap_env.R`.
- Introduce new CRAN/GitHub dependencies without:
  - A clear justification in code comments or docs
  - Updating `bootstrap_env.R`
  - Updating relevant docs under `docs/`
- Change the project structure (moving/deleting top-level directories) without explicit instruction.
- Implement large new subsystems (full genetics, GUIs, optimisation frameworks, etc.) without being asked to do so.

All non-base functions from external packages must be called using **`package::function()`** style.

---

## 3. What Agents May Work On

Within Phase 1, agents are encouraged to:

- Implement or refine **core lifecycle modules**:
  - Ageing, survival, breeding-eligibility, simple birth/offspring logic
  - Simple density feedback (e.g. ceiling K, basic harvest/removal)
- Implement or refine **simulation controllers**:
  - Functions that apply a sequence of lifecycle processes over time
- Wire modules into the **`targets` pipeline** via `_targets.R`
- Add or improve **tests** under `tests/testthat/`
- Improve **Roxygen documentation** and internal comments (without changing semantics)

All changes must respect the architecture described in `docs/architecture_core.md` and the conventions in `docs/dev_conventions_r.md`.

---

## 4. Coding and Style Rules (Agent Summary)

- Use `snake_case` for all function and object names.
- Keep functions short and single-purpose.
- Use `package::function()` for all non-base calls.
- Avoid side effects inside core modules:
  - No file IO
  - No plotting
  - No global state modification

Example (OK):

```r
apply_survival <- function(population, survival_fun) {
  lapply(population, function(ind) {
    if (ind$alive) {
      prob <- survival_fun(ind)
      ind$alive <- stats::runif(1) < prob
    }
    ind
  })
}
```

---

## 5. Behaviour Around Tests and Pipelines

When making non-trivial changes, agents should:

* Ensure there are **tests** for new or modified logic:

  * Add files under `tests/testthat/` (e.g. `test_lifecycle_survival.R`).
* Keep `_targets.R` clean and declarative:

  * Each target calls functions defined in `R/`, not long inline pipelines.

Agents should assume that a human will run:

* `devtools::test()`
* `targets::tar_make()`

Therefore, avoid obvious breakage (e.g. renaming functions without updating call sites).

---

## 6. Handling Ambiguity

If requirements appear ambiguous:

* Prefer **local consistency** with the file being edited, as long as it does not contradict `docs/dev_conventions_r.md`.
* When a design choice is non-obvious:

  * Add a brief comment explaining the choice, or
  * Leave a `TODO` or note rather than silently guessing biological intent.

Do **not** invent biological behaviour or parameters without instruction; keep model logic simple and explicit.

---

## 7. Agent Role Summary

In this repository, agents are:

* **Careful collaborators**, not autonomous architects.
* Bound by the architecture, conventions, and roadmap in `docs/`.
* Expected to produce small, focused, reviewable changes.

If a proposed change conflicts with the documented design or scope, the safe choice is: **do not make it** without explicit human approval.
