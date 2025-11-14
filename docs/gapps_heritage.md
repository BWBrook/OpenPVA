# GAPPS Heritage

This document captures the conceptual heritage of **GAPPS** (Generalized Animal Population Projection System) and how it informs the design of **OpenPVA**.

The goal is not nostalgia. The goal is to extract and codify the ideas from GAPPS that are still powerful and relevant, and to use them consciously in a modern, open implementation.

---

## 1. What GAPPS Was

GAPPS was developed in the late 1980s by Richard Harris as a generalised wildlife population simulator, originally for **grizzly bears** and later applied to other large mammals. It was one of the first truly **general-purpose PVA engines**.

Key characteristics:

- **Individual-based** simulation (each animal tracked as a record)
- **Script-driven** lifecycle specification (commands like `BREED`, `MATE`, `LITTER`, `SURVIVE`, `HUNT`)
- **Stochastic processes** defined explicitly via functions such as `NRAND` (normal) and `URAND` (uniform)
- **Age and sex structure** handled flexibly through DBF tables
- **Genetics and inbreeding** built into the framework (`ALLELES`, `INBREED`, `GENETICS`, `DEPRESS`)
- **Management actions** modelled explicitly (harvest via `HUNT`, immigration via `IMMIGRATE`)

Technically, it relied on DOS-era tools: DBF files for storage, a custom parser, and 16‑bit executables. Conceptually, though, it was decades ahead of its environment.

---

## 2. How GAPPS Worked (Conceptually)

GAPPS models were specified using a simple but expressive **domain-specific language**. A typical script:

- Set up a run (`SETUP`, `RESEED`)
- Read in an initial population (`READ`)
- Optionally initialise genetic diversity (`ALLELES`)
- Loop over years (`BEGIN (YEAR(...))`)
  - Update stochastic modifiers with `SET` expressions
  - Apply lifecycle modules in sequence:
    - `BREED` → `MATE` → `LITTER` → `BIRTH` → `WEAN` → `SURVIVE` → `AGE`
  - Apply management (`HUNT`, `IMMIGRATE`, etc.)
  - Take censuses (`CENSUS`) and summaries (`SUMMARY`)
- Clear memory (`PURGE`) and repeat for multiple runs

Parameters for each module (e.g. survival, breeding, litter size) were defined in **age-specific DBF tables**, sometimes modulated by runtime variables. For example:

- A survival table might refer to symbols like `OSURV`, `ASURV`, which were set each year as functions of random normals and density.
- A harvest table might refer to a symbol `KILL` computed from `N - K`.

This created a **declarative but programmable** system: the script expressed *what the life cycle is* and *how rates are calculated*, while the engine executed that logic over individuals.

---

## 3. Why GAPPS Matters for OpenPVA

For OpenPVA, GAPPS represents:

- A **proof of concept** that a general PVA engine can be flexible, scriptable, and individual-based.
- A **design philosophy** that separates the core engine from user-defined lifecycle logic.
- An early example of integrating **genetics, demography, and management** in one modelling system.

Barry used GAPPS extensively in the 1990s (e.g. for grizzly bears and Soay sheep) and evaluated it alongside other PVA tools in his PhD work. Those experiences directly motivate the desire to revive and modernise the GAPPS approach.

---

## 4. Ideas We Are Deliberately Inheriting

OpenPVA is not a line‑for‑line reimplementation, but it does inherit several key ideas from GAPPS:

1. **Lifecycle as an explicit sequence of processes**

   The order of events matters (e.g. survival before or after reproduction). GAPPS exposed this to the user; OpenPVA will, too. We keep the notion of discrete lifecycle modules that can be sequenced and re‑ordered.

2. **Modular process blocks**

   Commands like `BREED`, `MATE`, `LITTER`, `SURVIVE`, `HUNT`, `IMMIGRATE` embodied distinct processes. OpenPVA will represent these as **separate R modules** that operate on a population state and can be swapped or extended.

3. **Symbolic expressions and shared variables**

   GAPPS used `SET` to define symbols (e.g. `K`, `EXTRA`, `ESBREED`, `OSURV`) that could be referenced by multiple modules and tables. In OpenPVA, this becomes a shared “simulation state” or parameters list that lifecycle modules can read and write, keeping logic explicit.

4. **Explicit stochasticity**

   Instead of ticking a box for “environmental stochasticity”, GAPPS required the user to write expressions like:

   - `ESBREED = 0.326 + 0.073 * RNORMF`
   - `OSURV = 0.89 + 0.098 * RNORMS`

   OpenPVA adopts this attitude: stochastic variation should be part of the model logic, not a hidden mode.

5. **Demography–genetics linkage**

   Modules such as `ALLELES`, `INBREED`, `GENETICS`, and `DEPRESS` allowed genetics to influence demography (e.g. inbreeding depression in breeding success). OpenPVA will treat genetics as a first‑class optional module, not an afterthought.

---

## 5. Constraints and Limitations We Are Leaving Behind

There are also aspects of GAPPS we **do not** intend to replicate:

- **DBF‑based input/output**: OpenPVA will use modern R data structures and formats (CSV, RDS, tibbles), not legacy DBF files.
- **Closed, binary distribution**: OpenPVA is fully open source, designed for inspection and extension.
- **DOS-era UI and tooling**: No need to emulate the old parser or file formats; we have R, Quarto, and modern text editors.
- **Hard constraints on spatial structure**: GAPPS had little explicit spatial modelling; OpenPVA will support patches and landscapes from the outset.
- **Lack of native pipeline/reproducibility tooling**: With `renv` and `targets`, we can now bake reproducibility into the architecture.

The goal is to **modernise the good ideas** rather than entomb the old implementation.

---

## 6. How GAPPS Shapes OpenPVA’s Design

Concrete design decisions in OpenPVA that trace back to GAPPS:

- **Lifecycle modules** (e.g. `age_individuals()`, `apply_survival()`, `determine_breeding()`) correspond to GAPPS commands (`AGE`, `SURVIVE`, `BREED`, etc.).
- The notion of **simulation state variables** (e.g. carrying capacity, density indices, random deviates) feeds into our design of shared state passed across modules.
- The insistence on **demographic plus genetic modelling** pushes us to keep genetics in scope, even if implemented in later phases.
- The ambition to handle **management actions** (harvest, supplementation, immigration) as explicit modules informs the way we plan harvest and translocation functions.

In all of this, the emphasis is on **user-visible logic**. If a model has a density feedback or inbreeding depression, it should be clear from the code, as it was in GAPPS scripts.

---

## 7. For Contributors and Agents: “Is This in the Spirit of GAPPS?”

When designing or modifying OpenPVA modules, a useful question is:

> Would this design make sense to someone who used GAPPS in the 1990s?

That does **not** mean mimicking DOS quirks. It means:

- Is the lifecycle logic visible and understandable?
- Are stochastic and density effects explicit in the code?
- Are modules clearly separated by biological process?
- Could another modeller adapt or extend this without guessing hidden behaviour?

If the answer is yes, you are probably aligned with the GAPPS heritage that OpenPVA wants to preserve.
