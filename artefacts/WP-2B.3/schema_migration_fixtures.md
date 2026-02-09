# WP-2B.3 schema migration fixtures

## Fixture summary
- v1 input schema_version: 1
- v2 migrated schema_version: 2
- v3 migrated schema_version: 3
- v2 reproduction_ev keys: env_repro_p_sd, cat_repro_prob
- v3 uncertainty field present: FALSE

## Validation fixture
- schema_version 2 + uncertainty block is rejected with explicit guidance:
  - `YAML schema_version 2 does not support an uncertainty block; use schema_version: 3.`
