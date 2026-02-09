# Spatial-genetic outputs: usage and interpretation

This guide explains how to use OpenPVA spatial/genetic outputs for inference and
comparison workflows.

## Output families

OpenPVA now provides three complementary families of spatial/genetic outputs:

1. Final-time patch summaries.
2. Time-series patch summaries.
3. Connectivity/turnover diagnostics.

These answer different questions and should not be treated as interchangeable.

## 1) Final-time summaries

Helpers:

- `summarise_patch_occupancy_final(sim_output, n_patches, alive_only = TRUE)`
- `summarise_patch_genetic_diversity_final(sim_output, n_patches, alive_only = TRUE)`

Use when the decision question is endpoint-oriented, for example:

- "Which patches are most likely occupied at the end of the planning horizon?"
- "How different are final heterozygosity/F-hat patterns by management option?"

Strengths:

- compact and easy to compare across scenarios,
- useful for screening management alternatives.

Limitations:

- hides transient dynamics,
- does not reveal turnover pathways or year-to-year instability.

## 2) Time-series summaries

Helpers:

- `summarise_patch_occupancy_timeseries(sim_output, n_patches, alive_only = TRUE)`
- `summarise_patch_genetic_diversity_timeseries(sim_output, n_patches, alive_only = TRUE)`

Precondition:

- Simulations must be run with `record_population_history = TRUE`.

Use when the decision question is trajectory-oriented, for example:

- "Does a patch recover after temporary collapse?"
- "Is diversity steadily eroding or only fluctuating around a stable level?"

Strengths:

- exposes trend and volatility,
- supports event-timing analyses (colonization/extirpation timing, lag effects).

Limitations:

- larger output objects,
- requires explicit history capture at run time.

## 3) Connectivity and turnover diagnostics

Helper:

- `summarise_patch_connectivity_timeseries(sim_output, n_patches, alive_only = TRUE)`

Key outputs:

- `transitions` and `transitions_overall`: patch-to-patch movement counts and
  origin-conditional transition probabilities.
- `net_patch_change`: year-to-year patch abundance change (`delta_n_alive`).
- `turnover`: colonization/extirpation indicators.

Use when the decision question is mechanism-oriented, for example:

- "Are sink patches sustained by immigration?"
- "Does a corridor alternative increase movement symmetry?"

Interpretation caveat:

- Transition diagnostics track individuals present in consecutive years
  (ID-matched survivors). They do not represent total demographic flux,
  because births/deaths alter patch counts outside survivor transitions.

## Choosing the right output for a decision

- Endpoint decision (final-state ranking): start with final-time summaries.
- Stability/risk over time: use time-series summaries.
- Movement mechanism or corridor inference: use connectivity diagnostics.

In practice, use all three in sequence:

1. Screen with final-time summaries.
2. Stress-test shortlisted scenarios with time-series outputs.
3. Explain differences with connectivity/turnover diagnostics.

## Recommended comparison workflow

1. Run scenario sets with fixed seeds and `record_population_history = TRUE`.
2. Generate all three output families.
3. Compare directional consistency across metrics (occupancy, diversity,
   transition probabilities, turnover flags).
4. Record interpretation notes in `docs/interpretation_notes.md`.

## Scenario pack

The packaged YAML scenario set under `inst/extdata/` includes three spatial
regimes for this workflow:

- `demo_spatial_genetic_fragmented.yaml`
- `demo_spatial_genetic_connected.yaml`
- `demo_spatial_genetic_asymmetric.yaml`
