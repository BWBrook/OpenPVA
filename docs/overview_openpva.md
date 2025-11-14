# OpenPVA Overview

## What is OpenPVA?

OpenPVA is an open‑source, modular framework for **Population Viability Analysis (PVA)** implemented in R. It is designed to simulate the dynamics and extinction risk of structured populations under demographic, genetic, environmental, and management processes.

OpenPVA’s core aim is to provide a **transparent, extensible, and reproducible** platform that conservation biologists and quantitative ecologists can both *use* and *extend*. It is intended to be a long‑lived, community‑maintained infrastructure project, not a one‑off model for a single species.

---

## Conceptual Lineage: From GAPPS to OpenPVA

OpenPVA is conceptually inspired by the original **GAPPS** (Generalized Animal Population Projection System) developed in the 1980s by Richard Harris. GAPPS was one of the earliest general PVA engines, notable for:

- Individual‑based simulation of wildlife populations
- A **declarative, script‑like language** for lifecycle processes (BREED, MATE, LITTER, SURVIVE, HUNT, etc.)
- Explicit, user‑defined stochasticity and density dependence
- Integration of **genetics** (alleles, inbreeding, depression) with demography

However, GAPPS was constrained by its era: DOS, DBF files, closed distribution, limited spatial structure, and no modern reproducibility practices.

OpenPVA is a **re‑imagining**, not a re‑implementation. It preserves GAPPS’s best ideas—modular lifecycle processes, individual‑based flexibility, genetics–demography integration—while rebuilding everything on a modern, open, R‑centric foundation.

---

## Why Another PVA Tool?

Many PVA tools already exist (VORTEX, RAMAS, steps, poems, RangeShiftR, etc.). OpenPVA is not trying to replace them all; instead, it aims to fill a specific gap:

- VORTEX and RAMAS are powerful but **closed‑source** and GUI‑bound.
- Matrix/IPM packages (popbio, popdemo, IPMpack) are open but **focused on demography only**.
- Newer frameworks (steps, RangeShiftR, poems) are open and flexible, but each has a particular emphasis (spatial dynamics, eco‑evolutionary range shifts, pattern‑oriented ensembles).

OpenPVA’s niche is to be a **general, modular, individual‑ or stage‑based PVA engine** that:

- Integrates demography, genetics, spatial structure, and management in one coherent framework
- Is implemented entirely in open R code
- Is architected from the outset for extension by contributors via modules and pull requests
- Emphasises **clear lifecycle logic** and **explicit process composition**, rather than hiding assumptions inside a GUI

---

## Core Design Goals

OpenPVA is built around a few non‑negotiable principles:

1. **Modularity**
   - Each process (e.g. ageing, survival, breeding, dispersal, genetics, harvest) is implemented as a separate module.
   - Modules can be swapped, extended, or combined without rewriting the engine.

2. **Transparency**
   - All model logic is in plain R scripts.
   - No black‑box binaries, no undocumented side‑effects.
   - Simulation workflows are orchestrated via `targets`, and environments pinned via `renv`.

3. **Reproducibility**
   - Analyses can be cloned, restored, and re‑run on any machine.
   - Simulation pipelines are declarative and version‑controlled.

4. **Extensibility**
   - New lifecycle processes, density‑dependence functions, genetic models, or spatial dynamics can be added by contributors.
   - The API is designed so external modules can plug into the engine cleanly.

5. **Dual Audience: Users and Developers**
   - Conservation practitioners should be able to run standard PVAs with minimal R code.
   - Quantitative modellers should be able to extend or replace modules for advanced work.

---

## What OpenPVA Is (and Is Not)

**OpenPVA *is*:**

- A general‑purpose PVA framework in R
- A simulation engine for structured populations (individual‑ or stage‑based)
- A platform for integrating demography, genetics, spatial structure, and management actions
- A community‑oriented project intended to grow via contributions and peer review

**OpenPVA is *not*:**

- A single‑species model or a publication‑specific script
- A point‑and‑click GUI program (though interfaces may be added later)
- A black‑box risk calculator where assumptions are hidden from the user
- A replacement for every existing PVA tool; it is one powerful tool in a broader ecosystem

---

## Project Status

At this stage (early development):

- The repository structure, coding conventions, and reproducibility tooling (renv + targets) are being established.
- Core R modules for individual representation, ageing, survival, and breeding are under development.
- Genetics, spatial dynamics, and decision‑support modules are planned but not yet implemented.
- Documentation and internal design notes are being written to guide future contributors and automated coding agents.

---

## How to Think About OpenPVA (for Agents and Contributors)

When modifying or extending OpenPVA:

- Always think in terms of **modular lifecycle processes** that operate on a population state.
- Preserve transparency: favour clear, explicit code over clever illusions.
- Assume that future users will:
  - Want to understand the assumptions,
  - Want to plug in their own modules,
  - And may not be expert programmers.

The goal is not just to “get a model running”, but to build an **extensible framework** that others can trust, inspect, and evolve.
