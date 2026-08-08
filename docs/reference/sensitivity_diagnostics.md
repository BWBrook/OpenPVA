# Sensitivity diagnostics

Stage 1 retains one diagnostic that is independent of the retired simulation
controller.

## Exported functions

- `summarise_sensitivity_prcc(ensemble_data, response_col = "p_extinction", parameter_cols = NULL)`

## PRCC diagnostic

`summarise_sensitivity_prcc()` computes parameter-wise partial rank correlation
coefficients (PRCC) for a selected response metric.

Supported inputs are deliberately direct:

- a draw-level data frame;
- a list containing that data frame as `per_draw`.

By default, parameter columns are numeric columns after excluding `draw_id`,
the response and standard per-draw summary metrics.

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

## Caveats and limits

- PRCC assumes monotonic relationships in rank space and can be unstable when
  parameters are highly collinear or have low variation.
- This diagnostic is a scaffold-level tool for decision support and should be
  interpreted alongside domain knowledge and scenario plausibility checks.
- The former OAT function mutated top-level fields on the retired scenario
  shape. It is not a Stage 1 public interface and will not be adapted before a
  process-native sensitivity design is specified.
