# WP-2B.6 performance profile

## Profiling setup
- Scenario source: `artefacts/WP-2B.3/yaml_uncertainty_examples/v3_uncertainty_params.yaml`
- Draws: 16
- Seed: 20260215
- Parallel cores: 2

## Results
- Serial elapsed seconds: 2.086
- Parallel elapsed seconds: 0.927
- Speedup (serial/parallel): 2.25
- Sampled parameters identical: TRUE
- All draw summaries identical: TRUE

## Interpretation
- Parallel execution preserves deterministic outputs under fixed seed.
- Speedup is bounded and hardware-dependent; this profile is a reproducible smoke benchmark, not a universal performance claim.
