# OpenPVA  
**An Open, Modular Framework for Population Viability Analysis**

[![Status: WIP](https://img.shields.io/badge/status-WIP-orange.svg)]()  
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)  
[![R version](https://img.shields.io/badge/R-4.3%2B-blue.svg)](https://cran.r-project.org/)  
[![Reproducible](https://img.shields.io/badge/reproducible-yes-brightgreen.svg)]()  
[![Open Source](https://img.shields.io/badge/open--source-100%25-brightgreen.svg)]()

---

## Overview

**OpenPVA** is a next-generation, open-source platform for conducting **Population Viability Analysis (PVA)**—the simulation and analysis of population dynamics, extinction risk, and management outcomes for structured biological populations.

Inspired by the early vision of the original GAPPS (Generalized Animal Population Projection System), **OpenPVA** reimagines that philosophy with modern software architecture: fully **modular**, **extensible**, and **transparent**. It is designed for ecologists, conservation biologists, and decision scientists who need a flexible but rigorous tool to simulate population trajectories under a range of biological, genetic, environmental, and management scenarios.

---

## Key Features

* **Fully Modular Lifecycle Modeling**
  Define each stage of the population life cycle (survival, reproduction, dispersal, etc.) using user-specified rules and interchangeable process modules.

* **Individual- and Population-Level Simulation**
  Choose between individual-based or stage-structured (matrix/IPM) simulation strategies depending on your modeling needs.

* **Genetic and Demographic Integration**
  Track alleles, relatedness, and inbreeding depression alongside demographic outcomes. Plug in genetic modules only when needed.

* **Spatial and Environmental Dynamics**
  Integrate time-varying landscapes, habitat maps, climate scenarios, and spatial population structures.

* **Open Extensibility**
  Add your own modules, write custom demographic functions, or extend simulation logic via a documented API.

* **Transparent and Reproducible**
  Built entirely in R with clean, script-based workflows. No black boxes. All assumptions and outputs are traceable and inspectable.

* **Decision Support and Scenario Analysis**
  Evaluate conservation interventions, test trade-offs, and explore outcomes using parameter uncertainty, sensitivity, and optimization routines.

---

## Roadmap

OpenPVA is currently under active development. The initial release (v0.1) will include:

* A minimal working system simulating age-structured individual-based dynamics
* Basic stochastic demography and survival/breeding logic
* A modular architecture for lifecycle processes
* A reproducible example using grizzly bear population data

Planned modules for future versions:

* Genetic modeling (inbreeding coefficients, alleles, drift)
* Spatial dynamics (patch structure, habitat linkage, landscape change)
* Bayesian calibration and ABC-style model validation
* GUI interface (via Shiny) for non-coding users
* Integration with decision-support frameworks

---

## Philosophy

OpenPVA is a **framework for thinking** about population dynamics in a structured, transparent, and reproducible way.

It is designed to **enable understanding, not obscure it**, and to allow researchers and practitioners to build models that reflect the real structure, uncertainty, and nuance of their systems.

We believe in models that are **insightful, not just predictive**—tools that help ask better questions, not just output numbers.

---

## Get Involved

OpenPVA is built to be a **community platform**. Once publicly released, we will welcome contributions from developers, modelers, educators, and domain experts. Contributions may include:

* New demographic or genetic modules
* Interfaces to external data or models
* Visualisation and output tools
* Translations, documentation improvements, teaching materials
* Core architectural enhancements

If you’re interested in collaborating or contributing, get in touch. We’re building something that’s meant to last.

---

## License

OpenPVA will be released under the **MIT License**, ensuring open use, modification, and distribution.

---

## Citation

A formal software paper is forthcoming. For now, please cite as:

> Brook, B. et al. (in prep). *OpenPVA: An open, modular platform for population viability analysis*.

Stay tuned for publication updates.

---

## Contact

Lead developer: **Barry W. Brook**
With contributions from an emerging open-science community.

GitHub: [github.com/yourrepo/openpva](https://github.com/yourrepo/openpva) *(placeholder)*
Email: barry.brook@utas.edu.au
Project codename: *RGAPPS*
