# AGENTS: OpenPVA repository contract

This file is the project-level instruction for automated agents in `BWBrook/OpenPVA`.

## Product North Star

> The modeller defines the biological programme; OpenPVA supplies the execution
> engine, reusable processes, scientific contracts, and reproducible analysis
> machinery.

OpenPVA is a modern, open-R descendant of the GAPPS construction philosophy—built
so conservation biologists (and their AI agents) can compose transparent,
inspectable, individual-based Population Viability Analyses in ordinary R.

## Core architecture (OpenPVA 2.0.0)

- **One unified, pure-base-R engine:** `NeedsCompilation: no`, `Depends: R (>= 4.1.0)`,
  and runtime `Imports` restricted to base/recommended packages (`codetools`,
  `parallel`, `stats`, `tools`, `utils`). Do not add `dplyr`, `tibble`, `renv`
  boilerplate, a lifecycle DSL, a global registry, an S4/R6 hierarchy, or a
  second compiled sidecar engine unless a measured, unavoidable bottleneck proves
  pure R inadequate.
- **Direct ordered process list:** A lifecycle is an ordinary ordered list of
  `pva_process()` objects declaring `requires`, `writes`, and `creates`. Community
  processes compose through the exact same public contract without controller edits.
- **Columnar living state:** `pva_population()` / `pva_state()` hold living
  individuals as equal-length vectors; dead/removed records move to an optional
  life-history ledger. Callbacks are vectorised over the living population and see
  a shared pre-process state.
- **Engine-owned invariants:** The engine owns interval time, consecutive IDs,
  preassigned per-replicate L'Ecuyer-CMRG RNG streams (bit-identical across
  serial, fork, and PSOCK workers; caller `.Random.seed` restored on explicit
  seeds), cohort-by-origin accounting, and exact conditional pedigree inbreeding
  (value-semantic dense kinship store up to `max_dense_kinship`, switching cleanly
  to sparse ancestor tracing in `R/ancestry.R` above that threshold).

## Development and verification rules

- **No backwards compatibility layers:** Remove obsolete paths and update callers,
  tests, help pages, and docs together.
- **Documentation without `roxygen2`:** Update `scripts/rd_topics.R` and run
  `Rscript --vanilla scripts/build_rd.R` to regenerate `man/*.Rd` from live
  function formals.
- **Qualified calls:** Use `pkg::fun()` for non-base calls under `R/`, `tests/`,
  and `inst/examples/`; keep species models (`inst/examples/grizzly/`,
  `inst/examples/woodhen/`) outside the exported package namespace.
- **Standard local checks:**
  ```sh
  Rscript --vanilla scripts/run_tests.R
  R CMD build --no-build-vignettes .
  R CMD check --as-cran --no-manual OpenPVA_*.tar.gz
  bash scripts/benchmark_gate.sh
  ```
- **Proportional rigour:** Protect likelihood/demographic maths, RNG parity,
  cohort accounting, pedigree oracles (`< 1e-13`), and CRAN check cleanliness
  (`0 errors, 0 warnings`). Do not turn the repository into a journal-manuscript
  project unless Barry explicitly triggers one.

## Delivery and authority

- Local commits and routine pushes to Barry's own repository are authorised
  reversible work (scan staged changes with `GIT_CONFIG_GLOBAL=/dev/null gitleaks protect --staged`
  before pushing).
- Obtain Barry's explicit approval before CRAN submission, Zenodo/GitHub release
  tagging, or external outreach.
