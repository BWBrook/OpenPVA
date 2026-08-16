# R development conventions

`AGENTS.md` and the active scientific contracts are authoritative. These
conventions keep the implementation ordinary, inspectable and lean.

## Package code

- Put reusable code under `R/` and tests under `tests/testthat/`.
- Use `snake_case`; use a leading dot only for package-internal helpers.
- Prefer short ordinary functions and named lists over new class hierarchies or
  frameworks.
- Use `package::function()` for non-base calls. Do not call `library()` or
  `require()` under `R/`, tests or analysis scripts.
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

Birth and introduction processes declare every field needed downstream. State
changes within one built-in individual process use the shared pre-process state
contract documented in `design/lifecycle_process_contract.md`.

## Documentation and tests

- Every export has roxygen help; update generated `NAMESPACE` and `man/` files
  with its source.
- Add focused tests for behavior, scientific invariants, accounting and RNG
  reproducibility in proportion to the change.
- Remove obsolete code with its exclusive tests and current documentation. Do
  not retain compatibility wrappers.
- Preserve historical goal records, logs and artefacts unless a goal explicitly
  authorises archival cleanup.

Run:

```sh
Rscript scripts/run_tests.R
Rscript scripts/run_lint.R
```

Use an isolated temporary directory for package build/check. YAML, `targets`
and Quarto are possible Stage 4 analysis/configuration choices, but are not
current dependencies or scaffolds. Add one back only with an executable
consumer; none defines the lifecycle protocol or routine test gate.
