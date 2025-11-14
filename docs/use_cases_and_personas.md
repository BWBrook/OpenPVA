# Use Cases and Personas

This document outlines the main **user personas** and **use cases** that OpenPVA is designed to support.

It is intended to guide design decisions and help contributors (including automated agents) prioritise features and interfaces that serve real users.

---

## 1. Personas

### 1.1 Conservation Ecologist (Practitioner)

**Profile:**

- Background in ecology and conservation biology.
- Comfortable reading and modifying simple R scripts, but not a software engineer.
- Uses PVA as one tool among many (field data, GIS, expert elicitation).

**Needs:**

- Clear, well-documented examples.
- Ability to run standard PVAs with modest editing (e.g. change rates, number of years, carry capacity, initial population).
- Transparent assumptions: must be able to explain model structure in reports and management plans.
- Robust, reproducible workflows to support decisions, not exploratory code fragments.

**OpenPVA implications:**

- Provide simple, self-contained example scripts and pipelines.
- Avoid unnecessarily complex interfaces for basic tasks.
- Keep defaults conservative and clearly documented.

---

### 1.2 Quantitative Modeller / PVA Specialist

**Profile:**

- Strong statistical and modelling background (R, possibly C++/Python).
- Has used or developed custom PVA models in the past.
- Interested in exploring new dynamics, comparing models, or extending existing frameworks.

**Needs:**

- A flexible engine that can be extended with new processes (e.g. custom density dependence, alternative mating systems).
- A clear architecture that does not fight back when modified.
- Integration with other tools (targets, Bayesian frameworks, spatial data).

**OpenPVA implications:**

- Keep core modules small and composable.
- Maintain clean function interfaces and minimal hidden state.
- Document extension points and expected interfaces for new modules.

---

### 1.3 Student / Early-Career Researcher

**Profile:**

- Learning PVA and quantitative conservation.
- Some R experience, often from coursework or self-study.
- May be tasked with building or understanding a PVA as part of a project or thesis.

**Needs:**

- Teaching-focused examples that illustrate basic PVA concepts (stochasticity, density dependence, extinction risk).
- Simple, readable code rather than highly optimised internals.
- Clear linkage between textbook PVA concepts and OpenPVA modules.

**OpenPVA implications:**

- Provide teaching vignettes and small, annotated examples.
- Prefer clarity over cleverness in core examples.
- Make it easy to “open the hood” and see how things are done.

---

## 2. Canonical Use Cases

These use cases should inform what we implement and how we test it.

### 2.1 Recasting a Classic Large Mammal PVA

**Example:** Grizzly bear or similar long-lived mammal.

**Description:**

- Age-structured, sex-structured individual-based model.
- Annual time steps.
- Survival and reproduction depend on age and sex.
- Density regulation via harvest or ceiling K.

**Goals:**

- Demonstrate that OpenPVA can reproduce the behaviour of a classic PVA.
- Provide a reference implementation for long-lived mammals.

**Design implications:**

- Ensure lifecycle modules can handle age/sex structure cleanly.
- Provide a simple harvest/density feedback module.
- Make stochasticity explicit in survival and reproduction.

---

### 2.2 Small Island Bird with Management Interventions

**Example:** A threatened island bird with limited habitat.

**Description:**

- Small population size with high extinction risk.
- Management options: predator control, translocation, supplementation.
- Environmental variation in food supply affecting carrying capacity.

**Goals:**

- Show how to test alternative management strategies.
- Integrate simple density dependence and management actions.

**Design implications:**

- Support multiple management modules (e.g. removal, addition of individuals).
- Provide scenario comparison patterns (e.g. tar targets for different scenarios).
- Keep management logic explicit and parameterised.

---

### 2.3 Teaching Example: Minimal Age-Structured Population

**Example:** Hypothetical species with three age classes.

**Description:**

- Simple demographic parameters: fixed survival and fecundity rates.
- Stochasticity turned on and off to illustrate its effects.
- No spatial or genetic structure.

**Goals:**

- Provide a clean entry point for honours/masters students.
- Illustrate key PVA concepts:
  - Deterministic vs stochastic trajectories.
  - Demographic vs environmental variation.
  - Extinction risk estimation via repeated runs.

**Design implications:**

- Ensure the API allows easy toggling of stochasticity.
- Provide simple plotting and summary tools (via separate helper modules).
- Keep the example code short and heavily commented.

---

### 2.4 Extending the Engine with a Custom Module

**Example:** A modeller wants to implement an Allee effect in survival.

**Description:**

- Baseline survival already implemented.
- Modeller writes a new survival function that:
  - Reduces survival at low densities.
  - Integrates with existing population representation and controller.

**Goals:**

- Show that OpenPVA is genuinely extensible, not fixed-function.
- Provide a template for writing and plugging in new modules.

**Design implications:**

- Keep population representation and process interfaces stable.
- Demonstrate how to swap out modules in the simulation controller.
- Document the expected structure of process functions clearly.

---

## 3. How Personas and Use Cases Should Influence Design

When making design decisions or implementing new features:

- Ask which persona and use case you are serving.
- Avoid making the engine harder to understand for the Practitioner and Student in order to marginally optimise for the Specialist.
- Use canonical use cases as **regression tests**:
  - New changes should not break the ability to express and run these scenarios cleanly.

OpenPVA should be a tool that:

- Practitioners can trust and run.
- Specialists can extend without friction.
- Students can learn from without being overwhelmed.

Keep those three groups in mind whenever you touch the code.
