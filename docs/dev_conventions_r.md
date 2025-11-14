# R Development Conventions for OpenPVA

This document defines the R coding and workflow conventions for the OpenPVA project.  
All contributors and automated agents must follow these rules.

The aims are:

- Reproducibility
- Transparency
- Modularity
- Ease of review and extension

The conventions below supersede any earlier guidance that relied on the `import` package.  
From now on, we use **`package::function()` style** for all non-base functions.

---

## 1. Project Structure

Key elements:

- `R/` — all package functions and internal helpers
- `_targets.R` — pipeline definition using the `targets` package
- `bootstrap_env.R` — initialises `renv` and installs required packages
- `tests/` — unit tests using `testthat`
- `docs/` — design, architecture, and usage documentation
- `data/` — input data, small example datasets
- `outputs/` — generated results and figures (via targets, not ad hoc scripts)

No analysis logic should live in top-level ad hoc scripts; code belongs in `R/` and is orchestrated through `targets`.

---

## 2. Packages, Imports, and Namespaces

### 2.1 General principles

- **Never** call `library()` or `require()` in functions under `R/`, in `_targets.R`, or in tests.
- **Never** call `install.packages()` inside functions, targets, or package code.
- Use **`package::function()`** for all non-base/non-recommended package functions.
- Use base and recommended functions (`base`, `stats`, `utils`, `methods`, etc.) directly, without qualification.

The only exceptions:

- `bootstrap_env.R` may call `install.packages()` and `library()` or `renv::init()` as needed to create or restore the environment.

### 2.2 Using `package::function()` style

For any function that comes from a CRAN or GitHub package, call it explicitly via `package::function()`:

```r
my_helper <- function(x) {
  x |>
    dplyr::filter(!is.na(value)) |>
    dplyr::mutate(scaled = value / max(value, na.rm = TRUE))
}
```

Guidelines:

- Do **not** attach packages with `library()`.
- Do **not** use `import::from()` or `import::here()`; the `import` package is no longer part of the standard toolchain.
- Repeated `package::function()` calls are acceptable; readability and explicitness are preferred over shaving a few characters.

### 2.3 Base and recommended functions

Functions from base and recommended packages can be used directly:

```r
runif(10)        # from stats
seq_len(5)       # from base
sample(0:10, 1)  # from base
```

There is no need to prefix these with `stats::`, `base::`, etc.

---

## 3. Environment Management with `renv`

`renv` is used to pin package versions and make the project reproducible.

- `bootstrap_env.R` is the **only** script that should:
  - Call `renv::init()`
  - Call `renv::install()` or `install.packages()`
  - Load packages with `library()` if needed
- Do not modify `renv.lock` manually.
- Commit `renv.lock` and `.Rprofile` to version control.
- Ignore `renv/library` in `.gitignore`.

To reproduce the environment on a new machine:

1. Clone the repository.
2. Run `Rscript bootstrap_env.R` once, or call `renv::restore()` directly if `renv` is already installed.

---

## 4. Workflow Orchestration with `targets`

The `targets` package is used to define reproducible pipelines.

- `_targets.R` is the single entry point for pipeline definition.
- Use `targets::tar_option_set()` to declare required packages for the pipeline.
- Use `targets::tar_target()` to declare each step.

Example structure:

```r
targets::tar_option_set(
  packages = c("dplyr", "tibble", "purrr", "here")
)

list(
  targets::tar_target(
    pop0,
    initialize_population(n = 50)
  ),
  targets::tar_target(
    results,
    run_simulation(pop0)
  )
)
```

Guidelines:

- Targets should call functions defined in `R/`, not embed long pipelines inline.
- All file IO should be performed within targets, not inside core lifecycle modules.
- Use `format = "file"` for targets that produce files in `outputs/`.

---

## 5. Function Design and Style

All OpenPVA functions must obey the following conventions.

### 5.1 Single responsibility

Each function should do **one** coherent thing. If a function:

- Spans many logical steps, or
- Manipulates unrelated concepts,

then split it into smaller helpers.

### 5.2 Naming

- Use `snake_case` for all function and object names.
- Use descriptive names (“`apply_survival`”, not “`f2`”).
- Avoid abbreviations unless they are standard in the field (`pva`, `sd`, `n_iter`).

### 5.3 Arguments

- Keep argument lists short and clear.
- Use `...` sparingly and only when forwarding arguments.
- Prefer explicit arguments for key model parameters (e.g. `n_years`, `n_runs`, `density_fun`).

### 5.4 Side effects

Core modules (especially lifecycle modules) should:

- Not write files
- Not produce plots
- Not modify global options or `.GlobalEnv`
- Not call interactive functions

All side effects belong in higher-level code (targets, vignettes, or dedicated reporting functions).

---

## 6. Documentation (Roxygen)

Every exported function in `R/` must have a Roxygen header:

- One-line title
- Short description
- `@param` tags for each argument
- `@return` description
- `@export` for functions that form part of the public API

Example:

```r
#' Apply survival to a population
#'
#' Updates each individual's alive status based on a survival probability function.
#'
#' @param population List of individual objects.
#' @param survival_fun Function that returns a survival probability for each individual.
#'
#' @return Modified population with updated `alive` status.
#' @export
apply_survival <- function(population, survival_fun) {
  # implementation
}
```

Internal helper functions (not exported) should still have at least a brief comment describing their purpose.

---

## 7. Testing

OpenPVA uses `testthat` for unit tests.

- Place tests in `tests/testthat/`.
- Each file should correspond to a conceptual area, e.g.:
  - `test_lifecycle_age.R`
  - `test_lifecycle_survival.R`
  - `test_init_population.R`
- Tests should cover:
  - Basic behaviour (e.g. ages increment correctly, survival probabilities applied as expected)
  - Edge cases (empty populations, all dead, invalid input)
  - Invariants (e.g. IDs remain unique, sexes remain valid)

Run tests with:

```r
devtools::test()
# or
testthat::test_dir("tests/testthat")
```

---

## 8. Linting and Style Checks

We aim for clean, consistent code.

- Use `lintr::lint_package()` to check style.
- Strive for zero “object_usage_linter” warnings (no unused variables or functions).
- Keep functions short and readable.
- Avoid deeply nested logic; prefer early returns or helper functions.

---

## 9. Typical Development Flow

1. **Update environment** (once per machine):
   - Run `Rscript bootstrap_env.R` or `renv::restore()`.
2. **Implement or modify functions** in `R/`.
3. **Add or update tests** in `tests/testthat/`.
4. **Run tests** and **lint** the code.
5. **Update `_targets.R`** if new steps are needed in the pipeline.
6. **Run `targets::tar_make()`** to execute the workflow.
7. Commit changes, including updated `renv.lock` and documentation where relevant.

---

## 10. For Automated Agents

If you are an automated coding agent interacting with this repository:

- Always read `docs/overview_openpva.md`, `docs/architecture_core.md`, and this file before making changes.
- Respect existing file layout and naming choices.
- Do not introduce new package dependencies without:
  - A clear justification
  - An update to `bootstrap_env.R`
  - Documentation in the relevant `docs/` file
- Prefer minimal, focused changes over large refactors.
- When adding new functions or modules:
  - Add tests
  - Add Roxygen documentation
  - Use `package::function()` for non-base calls
  - Ensure the code is stylistically consistent

OpenPVA is a framework intended to be understood, audited, and extended by others. Write code as if someone else will have to maintain it for the next decade.
