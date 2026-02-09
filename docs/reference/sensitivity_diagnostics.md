# Sensitivity Diagnostics (WP-2B.4)

This page documents the bounded sensitivity diagnostics added for Line 2B.

## Exported functions

- `summarise_sensitivity_prcc(ensemble_data, response_col = "p_extinction", parameter_cols = NULL)`
- `summarise_sensitivity_oat(scenario, oat_spec, metric_fun = NULL, metric_name = "p_extinction", seed = NULL)`

## PRCC diagnostic

`summarise_sensitivity_prcc()` computes parameter-wise partial rank correlation
coefficients (PRCC) for a selected response metric.

Supported `ensemble_data` inputs:

- list from `summarise_ensemble_outputs()` (uses `$per_draw`),
- object from `run_scenario_ensemble()` (internally summarized),
- draw-level data frame.

Default `parameter_cols` behavior:

- for `run_scenario_ensemble()` outputs, uses names from
  `uncertainty_spec`,
- otherwise uses numeric columns after excluding standard per-draw summary
  metric columns and `draw_id`.

Output columns:

- `parameter`
- `prcc`
- `p_value`
- `n_obs`
- `n_controls`
- `abs_prcc`

Interpretation:

- Positive PRCC means the response tends to increase when the parameter
  increases, after controlling for the other included parameters.
- Negative PRCC means the response tends to decrease.
- `abs_prcc` provides relative strength in this local/ensemble context.

## OAT elasticity diagnostic

`summarise_sensitivity_oat()` runs one-at-a-time perturbations around a bounded
baseline.

`oat_spec` format (named list by scenario field):

- required: `baseline`, `delta`
- optional: `lower`, `upper`

For each parameter, the function evaluates:

- low value: `baseline - delta` (clamped to bounds)
- high value: `baseline + delta` (clamped to bounds)

Output columns:

- `parameter`
- `metric_name`
- `baseline_value`, `low_value`, `high_value`
- `baseline_metric`, `low_metric`, `high_metric`
- `local_slope`
- `elasticity`
- `pct_change_low`, `pct_change_high`

## Caveats and limits

- PRCC assumes monotonic relationships in rank space and can be unstable when
  parameters are highly collinear or have low variation.
- OAT is local sensitivity around selected baselines; it is not a global
  sensitivity method.
- Elasticity can be undefined when baseline parameter or baseline metric is
  zero; these rows are reported as `NA`.
- These diagnostics are scaffold-level tools for decision support and should be
  interpreted alongside domain knowledge and scenario plausibility checks.
