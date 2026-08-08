# Public API

## Process Engine

- `pva_state()`
- `pva_process()`
- `pva_result()`
- `validate_processes()`
- `allocate_ids()`
- `execute_processes()`
- `scenario_spec()`
- `run_scenario()`

## Minimal Built-in Processes

- `age_process()`
- `survival_process()`
- `reproduction_process()`
- `census_process()`

## Retained Scientific Helpers

The package continues to export focused individual, demography-table, density,
spatial and genetic helper functions documented in their R help pages. They are
not privileged controller channels. Later goals may wrap high-value helpers as
conforming process constructors.

`summarise_sensitivity_prcc()` remains available for independent draw-level
tables. The defective legacy `apply_reproduction()` helper and the
controller-coupled `summarise_sensitivity_oat()` route are retired;
`reproduction_process()` is the active reproduction interface.

## Deferred Interfaces

The former fixed-label controller, `run_basic_simulation*()`,
`default_lifecycle_steps()`, YAML scenario loader, spatial/genetic scenario
constructors and controller-coupled uncertainty/calibration/reporting entry
points are not public Stage 1 interfaces. They will be reconsidered against the
accepted process contract in Stages 3-4, without compatibility adapters.
