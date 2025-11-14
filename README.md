# OpenPVA  
**An Open, Modular Framework for Population Viability Analysis**

[![Status: WIP](https://img.shields.io/badge/status-WIP-orange.svg)]()  
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)  
[![R version](https://img.shields.io/badge/R-4.3%2B-blue.svg)](https://cran.r-project.org/)  
[![Reproducible](https://img.shields.io/badge/reproducible-yes-brightgreen.svg)]()  
[![Open Source](https://img.shields.io/badge/open--source-100%25-brightgreen.svg)]()

---

## Overview

**OpenPVA** is a next-generation, open-source platform for conducting **Population Viability Analysis (PVA)**—the simulation and analysis of population dynamics, extinction risk, and management outcomes for structured biological populations. :contentReference[oaicite:2]{index=2}  

Inspired by the early vision of the original GAPPS (Generalized Animal Population Projection System), OpenPVA reimagines that philosophy with modern software architecture: fully **modular**, **extensible**, and **transparent**. It is designed for ecologists, conservation biologists, and decision scientists who need a flexible but rigorous tool to simulate population trajectories under a range of biological, genetic, environmental, and management scenarios.

OpenPVA is being developed as a long-lived, community-maintained framework rather than a one-off species model.

---

## Key Features (Planned)

- **Fully Modular Lifecycle Modelling**  
  Each stage of the life cycle (survival, reproduction, dispersal, etc.) is handled by interchangeable process modules.

- **Individual- and Population-Level Simulation**  
  Individual-based by design, with scope to support stage/matrix representations where useful.

- **Genetic and Demographic Integration**  
  Genetics (alleles, inbreeding, diversity) is treated as a first-class optional module, not an afterthought.

- **Spatial and Environmental Dynamics**  
  Planned support for patches/landscapes and time-varying environmental drivers.

- **Open Extensibility**  
  Contributors can add new modules, write custom demographic functions, or extend simulation logic via a documented API.

- **Transparent and Reproducible**  
  Built in R with script-based workflows, `renv` for environments, and `targets` for pipelines; no black boxes.

---

## Project Status and Roadmap

OpenPVA is under **active development**.

Current phase: **Phase 1 – Core Demographic Engine**  
(see `docs/roadmap_and_scope.md`)

Initial goals:

- A minimal working system simulating age-structured individual-based dynamics.
- Basic stochastic demography and survival/breeding logic.
- A modular architecture for lifecycle processes.
- A reproducible example for a stylised population (and later, classic systems such as grizzly bears).

Later planned modules include:

- Genetic modelling (inbreeding coefficients, alleles, drift).
- Spatial dynamics (patch structure, habitat linkage, landscape change).
- Calibration and validation tools (e.g. ABC-style workflows).
- GUI/shiny interfaces for non-coding users.

---

## Repository Layout

Key top-level elements:

- `R/` – Core R code: individual/population representations, lifecycle modules, controllers.
- `_targets.R` – `targets` pipeline definition for running simulations and analyses.
- `bootstrap_env.R` – Environment bootstrap using `renv`.
- `tests/` – Unit tests (`testthat`).
- `docs/` – Design and governance docs for architecture, conventions, scope, and agent behaviour.
- `quarto/` – Quarto sources for the documentation site (rendered into `docs/` as needed).
- `data/` – Input data and small example datasets.
- `outputs/` – Generated outputs (via targets, not ad hoc scripts).

For a map of the internal documentation, see `docs/docs_index.md`.

---

## Getting Started (Developers)

### 1. Clone and initialise the environment

```bash
git clone <this-repo-url>
cd openpva
Rscript bootstrap_env.R   # sets up renv and installs dependencies
````

Alternatively, in an R session:

```r
renv::restore()
```

### 2. Run the pipeline

Once the environment is ready:

```bash
Rscript -e "targets::tar_make()"
```

This will run the workflow defined in `_targets.R`, using the lifecycle modules in `R/`.

### 3. Run tests

Before pushing changes:

```bash
Rscript -e "devtools::test()"
```

---

## Coding Conventions (Summary)

Full details are in `docs/dev_conventions_r.md`. In brief:

* Use `snake_case` for functions and objects.
* Do **not** call `library()` or `require()` in package code or `_targets.R`.
* Use `package::function()` for all non-base functions.
* Keep lifecycle modules **pure**: no file IO, plotting, or global state changes.
* Document exported functions with Roxygen.
* Add tests for new behaviour under `tests/testthat/`.

---

## Design Heritage

OpenPVA draws heavily on the ideas in **GAPPS** (Generalized Animal Population Projection System):

* Scripted, modular lifecycle processes.
* Explicit stochasticity and density dependence.
* Integration of demography, genetics, and management.

For a concise summary of that heritage and what we are (and are not) copying forward, see `docs/gapps_heritage.md`.

---

## Contributing

OpenPVA is intended to be a **community platform**. Contributions may include:

* New demographic, genetic, spatial, or management modules.
* Improvements to the simulation controller or pipeline patterns.
* Documentation, teaching examples, and vignettes.
* Testing, validation, and benchmarking against classic PVAs.

Before contributing, please read:

* `docs/dev_conventions_r.md`
* `docs/roadmap_and_scope.md`
* `AGENTS.md` (if you are using an embedded agent)

Pull requests should describe:

* Which modules/files are affected.
* What tests you ran (`devtools::test()`, `targets::tar_make()`).
* Any changes to dependencies (`bootstrap_env.R`, `DESCRIPTION`).

---

## License

OpenPVA will be released under the **MIT License**, ensuring open use, modification, and distribution.

---

## Citation

A formal software paper is forthcoming. For now, please cite as:

> Brook, B. W. et al. (in prep). *OpenPVA: An open, modular platform for population viability analysis*.

---

## Contact

Lead developer: **Barry W. Brook**
With contributions from an emerging open-science community.

Email: [barry.brook@utas.edu.au](mailto:barry.brook@utas.edu.au)
Project codename: *RGAPPS*
