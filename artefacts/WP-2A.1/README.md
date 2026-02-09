# WP-2A.1 artefact bundle

Deprecation framework evidence (soft deprecations, once-per-session warnings,
compatibility retention).

## Evidence files

- `tests_targeted.log`
- `deprecation_runtime_demo.log`

## Key outcomes

- Targeted tests pass (`FAIL 0`, `WARN 0`, `PASS 55`).
- Soft-deprecation warnings emit once per session and can be suppressed via
  `options(openpva.deprecation_warnings = FALSE)`.
