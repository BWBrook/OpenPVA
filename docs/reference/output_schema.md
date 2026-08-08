# Process-engine output schema

## `run_scenario()`

Returns:

- `scenario`: the validated process-based scenario;
- `sim_output$runs`: ordered list of replicate results;
- `sim_output$events`: all structured event rows;
- `sim_output$census`: the subset of explicit census events;
- `sim_output$provenance`: root seed, replicate streams and process plan.

Each run contains:

- final `state` and `population`;
- ordered `events` and `census` rows;
- optional `population_history` snapshots;
- initial/final stream provenance and the declared process plan.

## Event Core

Every event has:

- `run`;
- `time`;
- `process_index`;
- `process_name`;
- `process_occurrence`;
- `phase` (`initial` or `interval`);
- `event_type`.

Processes supply `event_type` and a non-negative integer aggregate `value` for
accounting events. They may add documented scalar columns such as `cause` or
observer metrics. The engine rejects process attempts to write its provenance
columns.

## Time

Interval `t` covers `t -> t + 1`; every process in that list sees and reports
`time = t`. An explicitly requested starting observer reports `time = 0` with
`phase = initial`, distinct from an interval-zero census.

## Reproducibility

`run_scenario()` records a preassigned L'Ecuyer-CMRG stream for each replicate.
For a fixed root seed and software environment, serial and supported forked
execution return identical ordered state, events and provenance.
