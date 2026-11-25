# R development conventions

`AGENTS.md` and the active scientific contracts are authoritative. These
conventions keep the implementation ordinary, inspectable and lean.

## Package code

- Put reusable code under `R/` and tests under `tests/testthat/`.
- Use `snake_case`; use a leading dot only for package-internal helpers.
- Prefer short ordinary functions and named lists over new class hierarchies or
  frameworks.
- Use `package::function()` for non-base calls. Do not call `library()` or
  `require()` under `R/`.
- Keep core processes free of file, plotting, option and global-environment side
  effects. RNG calls are allowed only within engine-scoped execution; processes
  never call `set.seed()`.
- Do not guess biological defaults. Rates, schedules, population composition,
  connectivity and management rules belong to the modeller or a named fixture.

## Process extensions

A lifecycle component is an ordinary `pva_process()` returning `pva_result()`.
Declare required and written fields, use the engine context, emit documented
events, and preserve exact accounting. A community process must compose without
editing a controller or registering a privileged name.

Birth and introduction processes declare every field they initialise and add
individuals only through `add_individuals()`. Rate functions are vectorised over
the living population and share one pre-process state, as documented in
`design/lifecycle_process_contract.md`.

## Documentation and tests

- Every export is documented in `scripts/rd_topics.R`; regenerate `man/` with
  `Rscript scripts/build_rd.R`, which builds usage from the functions' formals
  and fails on an undocumented export or argument. `roxygen2` is not used.
- `NAMESPACE` is maintained by hand.
- Add focused tests for behaviour, scientific invariants, accounting and RNG
  reproducibility in proportion to the change.
- Remove obsolete code with its exclusive tests and current documentation. Do
  not retain compatibility wrappers.
- Keep the package on base R: no syntax or functions newer than R 4.1.0.

Run:

```sh
Rscript scripts/run_tests.R
```

`scripts/run_tests.R` installs the working tree into a temporary library first,
so PSOCK workers load the same code as the parent. Build and check in a
temporary directory:

```sh
R CMD build --no-build-vignettes .
R CMD check --as-cran --no-manual OpenPVA_*.tar.gz
```
