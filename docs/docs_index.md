# OpenPVA Documentation Index

This file lists the key documentation modules in `docs/` and their purpose.

Use it as a starting point when orienting yourself in the project.

---

## Core Conceptual Docs

- **overview_openpva.md**  
  High-level description of what OpenPVA is, why it exists, and what problems it is meant to solve.

- **architecture_core.md**  
  The core architectural model: individuals, populations, lifecycle modules, simulation controllers, and how `renv`/`targets` fit in.

- **gapps_heritage.md**  
  The conceptual heritage from GAPPS and which ideas are deliberately carried forward or left behind.

- **roadmap_and_scope.md**  
  Development phases, current focus, and what is in/out of scope at this stage.

---

## Development Conventions and Agent Guidance

- **dev_conventions_r.md**  
  R coding standards, package usage, environment management, and workflow conventions for OpenPVA.

- **agent_guidelines_codex.md**  
  Behavioural rules and expectations for automated coding agents (Codex, ChatGPT, etc.) working in this repo.

---

## Users and Use Cases

- **use_cases_and_personas.md**  
  The main user personas (practitioner, modeller, student) and canonical use cases that OpenPVA is designed to support.

- **q_and_a_interpretation.md**
  Living scientist-in-the-loop Q&A and interpretation log for human testing.

---

## Reference Contracts

- **reference/public_api.md**  
  Current exported API surface and removed legacy interfaces.

- **reference/output_schema.md**  
  Required structure of simulation and summary outputs used for regression tests.

- **reference/yaml_schema_v1.md**  
  YAML schema contract and migration notes.

- **reference/ci_profiles.md**  
  CI profile split (`ci-fast` and `ci-heavy-validation`) and local-equivalent
  command chains.

- **reference/release_automation.md**  
  Non-publishing release evidence automation workflow and script usage.

- **reference/migration_1x_to_2x.md**
  Summary of legacy interfaces intentionally removed from the current
  development line.

- **reference/spatial_genetic_outputs.md**
  Guidance on final-time vs time-series vs connectivity spatial/genetic
  summaries and interpretation caveats.

---

## This Index

- **docs_index.md**  
  You are here. A minimal overview of the documentation landscape.

If you are new to the project, a good reading order is:

1. `overview_openpva.md`  
2. `architecture_core.md`  
3. `gapps_heritage.md`  
4. `dev_conventions_r.md`  
5. `roadmap_and_scope.md`  
6. `use_cases_and_personas.md`  
7. `agent_guidelines_codex.md` (if you are an automated agent)
