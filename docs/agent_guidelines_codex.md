# Agent Guidelines for Codex (and Other Automated Tools)

This document defines how automated coding agents (e.g. Codex CLI, ChatGPT-based tools) should operate when working in the **OpenPVA** repository.

The goal is to ensure that automated assistance respects the project’s architecture, style, and scope, and produces changes that are easy for humans to review and maintain.

---

## 1. Documents You Must Read First

Before proposing or applying any code changes, the agent should conceptually “load” the following documents:

- `docs/overview_openpva.md`
- `docs/architecture_core.md`
- `docs/dev_conventions_r.md`
- `docs/gapps_heritage.md`

These files explain:

- What OpenPVA is for  
- How the core architecture is structured  
- The R development conventions you must follow  
- The historical GAPPS design that inspires OpenPVA

Treat these as **non-optional context**.

---

## 2. Core Behaviour Principles

When operating in this repository, the agent must:

1. **Preserve architecture**  
   - Do not introduce new structural patterns that conflict with `architecture_core.md` without explicit instruction.
   - Respect the separation between core lifecycle modules, simulation controllers, and pipelines.

2. **Obey R conventions**  
   - Use `package::function()` style for all non-base functions.  
   - Never call `library()` or `require()` in files under `R/`, `_targets.R`, or tests.  
   - Never call `install.packages()` in any code except `bootstrap_env.R`.

3. **Minimise surprise**  
   - Prefer small, focused diffs over sweeping refactors.  
   - Do not change unrelated code when implementing a new feature or fix.

4. **Maintain transparency**  
   - Keep lifecycle logic explicit and readable.  
   - Avoid clever metaprogramming or opaque tricks.

5. **Stay within scope**  
   - Focus on the current development phase (core demographic modules and basic simulation).  
   - Do not start implementing advanced modules (e.g. full genetics, GUI) unless explicitly requested.

---

## 3. What You May Do

The agent is encouraged to:

- Implement or extend **core lifecycle modules**:
  - e.g. ageing, survival, breeding, birth, simple density dependence
- Implement or extend **simulation controllers**:
  - e.g. functions that run a population through a sequence of lifecycle processes for a number of years or runs
- Add or improve **tests** under `tests/testthat/`:
  - e.g. coverage for new lifecycle logic
- Refine **documentation** and Roxygen comments:
  - e.g. clarifying parameter descriptions, updating examples
- Adjust `_targets.R` to wire new functions into the pipeline:
  - e.g. adding a target that runs a basic simulation and summarises outputs

These actions must conform to the architecture and conventions already documented.

---

## 4. What You Must Not Do (Without Explicit Instruction)

The agent must **not**:

- Introduce new package dependencies casually  
  - Any new dependency requires:
    - Clear justification in code comments or documentation  
    - An update to `bootstrap_env.R`  
    - A note in `docs/dev_conventions_r.md` or another relevant doc
- Reorganise the project structure (e.g. move whole directories, rename top-level files)
- Implement large new subsystems (e.g. GUI front-ends, full genetic engines, optimisation frameworks) without being explicitly asked
- Change environment management patterns:
  - No edits to how `renv` is used, except when instructed
- Replace existing architectural patterns (e.g. switching away from lists for individuals) unless requested as a dedicated task

When in doubt, default to **conservatism**: fewer changes, less intrusion.

---

## 5. Implementing New Functions or Modules

When adding a new function or module, the agent should:

1. Place the function in an appropriate file under `R/`  
   - Create a new file if there is no suitable existing one.
2. Follow naming and style conventions:  
   - `snake_case` names  
   - Short, focused functions  
   - `package::function()` for non-base calls
3. Add a Roxygen header for exported functions:  
   - Title, description, `@param`, `@return`, `@export`
4. Add or update tests in `tests/testthat/`:
   - Cover typical use and edge cases
5. If necessary, wire the function into the workflow via `_targets.R`:
   - Add new targets that call the new function
   - Keep `_targets.R` declarative and tidy

The result should be a coherent, reviewable change that a human maintainer can quickly understand.

---

## 6. Editing Existing Code

When modifying existing functions or modules:

- Preserve function signatures unless there is a compelling reason to change them.
- If you must change an interface:
  - Update all call sites accordingly.  
  - Update tests and documentation.
- Do not introduce incompatible behaviour silently. If semantics change, document it in:
  - The function’s Roxygen comments, and/or  
  - A relevant `docs/` file (e.g. `architecture_core.md`)

Avoid “drive-by” edits. If a refactor is needed, it should be a clearly scoped, intentional task.

---

## 7. Handling Ambiguity and Uncertainty

If the agent encounters unclear intent or conflicting patterns:

- Prefer **local consistency**:
  - Follow the style used in the file you are editing, *unless* it conflicts with `dev_conventions_r.md`.
- If a design choice seems non-obvious:
  - Add a concise comment explaining the rationale, or  
  - Propose the alternative in a comment or documentation note, rather than implementing it outright.
- Do not guess at biological assumptions:
  - Keep biological logic simple and explicit.  
  - Leave parameterisation and biological nuance to human modellers unless specified.

The agent’s role is to be a careful assistant, not an autonomous designer.

---

## 8. Interaction with Tests and Pipelines

Whenever the agent makes non-trivial changes, it should:

- Ensure there are **tests** for new or modified logic.
- Keep `_targets.R` consistent:
  - Each target should remain understandable and minimal.
- Assume that a human will run:
  - `devtools::test()`  
  - `targets::tar_make()`  

The agent should therefore avoid introducing code paths that obviously break tests or pipelines (e.g. changing function names without updating references).

---

## 9. Phase Awareness

OpenPVA will evolve in phases. At the current stage, priority is on:

- Defining and stabilising core individual-based demographic modules.
- Establishing robust simulation patterns and simple density feedback.
- Solidifying coding conventions and basic documentation.

Genetics, spatial structure, and advanced decision-support modules are **planned but not yet the focus**. The agent should not “jump ahead” to implement whole subsystems without explicit instruction from the human maintainer.

---

## 10. Summary: Agent’s Role

In this repository, automated agents are expected to:

- Be disciplined, not creative for its own sake.
- Follow the documented architecture and conventions.
- Make small, targeted improvements that are easy for humans to review.
- Keep OpenPVA’s long-term maintainability in mind.

Think like a careful collaborator who understands they are working inside a larger, evolving framework—not a script that has to solve everything in one go.
