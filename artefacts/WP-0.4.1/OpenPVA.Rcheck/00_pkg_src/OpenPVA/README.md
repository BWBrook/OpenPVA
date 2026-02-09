
# OpenPVA  
**An Open, Modular Framework for Population Viability Analysis**

![OpenPVA logo](OpenPVA.png)

[![Status: WIP](https://img.shields.io/badge/status-WIP-orange.svg)](docs/roadmap.md)  
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)  
[![R version](https://img.shields.io/badge/R-4.5%2B-blue.svg)](https://cran.r-project.org/)  
[![Reproducible](https://img.shields.io/badge/reproducible-yes-brightgreen.svg)](docs/workflow.md)  
[![Open Source](https://img.shields.io/badge/open--source-100%25-brightgreen.svg)](LICENSE)

---

## Overview

**OpenPVA** is a next-generation, open-source platform for conducting **Population Viability Analysis (PVA)**—the simulation and analysis of population dynamics, extinction risk, and management outcomes for structured biological populations.  

Inspired by the early vision of the original GAPPS (Generalized Animal Population Projection System), OpenPVA reimagines that philosophy with modern software architecture: fully **modular**, **extensible**, and **transparent**. It is designed for ecologists, conservation biologists, and decision scientists who need a flexible but rigorous tool to simulate population trajectories under a range of biological, genetic, environmental, and management scenarios.

OpenPVA is being developed as a long-lived, community-maintained framework rather than a one-off species model.

---

## Key Features

- Individual-based demographic engine with age/sex structure.
- Optional density feedback (ceiling K) and quota-based harvest.
- Replicated simulations with extinction metrics and mean trajectories.
- Lifecycle pipeline control via `lifecycle_steps` for custom sequencing.
- Scenario API (`scenario_spec()` / `run_scenario()`) with optional YAML loader (`read_scenario_yaml()`).

---

## Project Status and Roadmap

OpenPVA is under **active development**.

Current phase: **Phase 1 – Core Demographic Engine**  
(see `docs/vision_and_scope.md` and `docs/roadmap.md`)

Phase 1 focuses on the core demographic engine, density feedback, harvest, replicates, and scenario/YAML tooling. Genetics, spatial structure, decision-support tooling, and GUIs remain roadmap items for later phases.

---

## Repository Layout

Key top-level elements:

- `R/` – Core R code: individual/population representations, lifecycle modules, controllers.
- `_targets.R` – `targets` pipeline definition for running simulations and analyses.
- `bootstrap_env.R` – Environment bootstrap using `renv`.
- `tests/` – Unit tests (`testthat`).
- `docs/` – Design and governance docs for architecture, conventions, scope, and agent behaviour.
- `quarto/` – Quarto sources for the documentation site (rendered into `docs/` as needed).
- `inst/extdata/` – Packaged example inputs (e.g. demo YAML scenarios).
- `outputs/` – Generated outputs (via targets, not ad hoc scripts).

For a map of the internal documentation, see `docs/docs_index.md`.

---

## Getting Started (Developers)

### 1. Clone and initialise the environment

```bash
git clone https://github.com/BWBrook/OpenPVA.git
cd OpenPVA
Rscript bootstrap_env.R   # sets up renv and installs dependencies
```

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

### 4. Run a minimal scenario in R

```r
devtools::load_all(quiet = TRUE)

sc <- OpenPVA::scenario_spec(
  name = "readme_demo_r",
  n_runs = 5,
  n_years = 20,
  init_fun = function() OpenPVA::initialize_population(50),
  K = 80,
  harvest_quota = 2
)

res <- OpenPVA::run_scenario(sc)
OpenPVA::summarise_extinction(res$sim_output)
```

### 5. Run the same style scenario from YAML

```r
yaml_path <- file.path("inst", "extdata", "demo_density_harvest.yaml")
sc_yaml <- OpenPVA::read_scenario_yaml(yaml_path)
res_yaml <- OpenPVA::run_scenario(sc_yaml)
OpenPVA::summarise_extinction(res_yaml$sim_output)
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
* `docs/vision_and_scope.md`
* `docs/roadmap.md`
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
Email: [barry.brook@utas.edu.au](mailto:barry.brook@utas.edu.au)

---

## Quick start: run the basic example

```bash
Rscript -e "targets::tar_make()"
```

Inspect selected targets inside R using `targets::tar_read()`:

```r
# Extinction summaries and trajectories
targets::tar_read(sim_basic_reps_extinction_summary)
targets::tar_read(sim_basic_dense_harvest_extinction_summary)
traj <- targets::tar_read(sim_basic_dense_harvest_trajectory)
head(traj)

# File path for the mean trajectory plot
plot_path <- targets::tar_read(sim_basic_dense_harvest_trajectory_plot)
plot_path
```

## Scenarios and YAML

Define scenarios directly in R:

```r
sc <- OpenPVA::scenario_spec(
  name = "demo",
  n_runs = 20,
  n_years = 30,
  init_fun = function() OpenPVA::initialize_population(80),
  K = 60,
  harvest_quota = 3
)
res <- OpenPVA::run_scenario(sc)
OpenPVA::summarise_extinction(res$sim_output)
```

Or load a scenario from YAML (optional):

```r
yaml_path <- file.path("inst", "extdata", "demo_density_harvest.yaml")
sc_yaml <- OpenPVA::read_scenario_yaml(yaml_path)
res_yaml <- OpenPVA::run_scenario(sc_yaml)
```

YAML is a convenience for sharing scenarios; all functionality is accessible directly from R.
