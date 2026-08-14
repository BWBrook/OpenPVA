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

## Goal 003 benchmark summary

`run_grizzly_benchmark()` adds `benchmark_summary` with:

- `trajectory`: run/time/phase census rows by sex, cub/yearling/independent
  status, eligible females and finite annual growth;
- `events`: run/time event totals retaining births, source-labelled
  introductions, natural and stratum-labelled human deaths, dependency
  transitions, environment,
  observation and census rows;
- `run_summary`: replicate-level final abundance, independent-female
  abundance, geometric finite growth, quasi-extinction flag and first crossing
  phase/time (including an initial-census crossing; growth is `NA` when the
  initial abundance is zero);
- threshold probability, Monte Carlo standard error, conditional crossing
  timing, parameter values/hash, process order, seed streams and software/R
  version in `provenance`.

The fixture's parameters are explicitly illustrative and uncalibrated.
The `human_mortality_probability` is a conditional hazard among target
individuals alive when that ordinary process executes; human-death events retain
exact age and a separate maturity-boundary age class.

## Goal 004 density extension

`grizzly_density_extension_scenario()` remains a generic `run_scenario()`
scenario. Its benchmark metadata records the illustrative capacity, snapshot
field, affected vital rates and explicit non-calibration statement. Each
interval adds one `density_snapshot` event with scalar `n_alive`; the same value
is available to later callbacks as `state$globals$density_n_alive`.

## Goal 005 spatial events

`dispersal_process()` and `markov_dispersal_process()` emit one aggregate
`patch_transition` row per realised origin/destination cell. Rows contain
`origin_patch_id`, `destination_patch_id` and integer `value`; diagonal rows
record eligible individuals retained in their origin patch. These events are
the movement ledger and replace connectivity inferred from survivor histories.

`patch_density_snapshot_process()` emits one `patch_density_snapshot` row per
declared patch with `patch_id` and integer `value`, including zeros. The same
ordered keyed counts are written to `state$globals$patch_density_counts` for
later ordinary processes.

## Goal 006 introduction events

`introduction_process()` emits `event_type = "introduction"` with a required
nonblank `source` and integer `value`. Without grouping there is one row for the
total positive addition. With `group_by`, one row is emitted for each realised
combination of declared newcomer fields; these rows replace the total row and
their values sum exactly to the records added. Zero additions emit no row.

All introduction rows retain the Event Core columns below. The synthetic
grizzly immigration extension uses process name `immigration` and source
`illustrative translocation`; its benchmark event summary retains that source.

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
