# OpenPVA news

## OpenPVA 2.0.1

- `age_sex_rate()` now reports an error when a living individual's sex is
  absent from the table. Set `missing_sex = "zero"` to assign zero explicitly.
- `mate_from_field(stale = "unpaired")` lets a female skip breeding when a
  previous interval's mate is absent. Sires lost earlier in the birth
  interval retain their parentage under both policies.
- Dense pedigrees reuse calculations for full siblings and grow the matrix
  only as needed. A new benchmark checks exact kinship through the switch
  to ancestor tracing with related and inbred founders.

## OpenPVA 2.0.0

- The engine runs a direct ordered list of processes with declared
  `requires`, `writes` and `creates`. Population state is columnar. Dead
  individuals move to an optional life-history ledger. Callbacks receive the
  entire living population. Version 2.0.0 uses base and recommended packages
  on R 4.1.0 or later.
- Two-sex breeding requires a mate by default when a mate rule is supplied.
  Stored sire IDs survive intervening mortality. Bounded litters accept a
  lower limit and preserve the specified conditional mean.
- Initial parentage sets exact kinships. A value-based dense store and an
  ancestor calculation above `max_dense_kinship` support related founders
  and one unknown parent. The scalar drift proxy requires generation time.
- Staged survival uses the pre- and post-stage rates and supports entrants
  between stages without requiring a population field for random draws.
  Management and environmental processes cover pairing, ceilings, harvest,
  releases, catastrophes and density feedback.
- Risk summaries check every replicate and interval and share the year-zero
  rule. Strict validation reconciles entries and losses separately and
  validates each accounting receipt. Movement records realised patch flows.
- Socket workers inherit library paths and callback dependencies. Unseeded
  calls advance the caller's stream once. Ensemble caches track callback
  revisions, inputs and validation, with deterministic builder and summary RNG.
- Added a standalone grizzly maternal-care and harvest model and updated
  the woodhen model to use the survival rates of both sexes. Final states
  and individual ledgers are opt-in outputs.
- Removed `create_individual()`, `allocate_ids()`, `initialize_pedigree()`
  and the other record-list helpers. Use `add_individuals()` for creation,
  `age_sex_rate()` for rate tables and direct population counts for density.
- *Development provenance:* Designed, implemented, cross-audited, and hardened
  under Barry W. Brook's direction using independent multi-model sessions
  coordinated through `BWBrook/research-advisor`: initial 2.0.0 unified
  columnar pure-base-R architecture by Anthropic Claude Fable 5.2; release
  hardening, sparse ancestor pedigree (`R/ancestry.R`), PSOCK/R 4.1.0
  verification, and standalone grizzly example by OpenAI Codex (GPT-6 family);
  cross-critique and ancestor-compression pedigree design input from Google
  Gemini 4 Carbon (High); independent verification and adjudication by Google
  Gemini 4 Neon.

## OpenPVA 1.0.1 (development)

- Replaced the fixed biological dispatcher with a validated ordered process
  engine, explicit state/result/field/event contracts and reproducible
  replicate streams.
- Added a synthetic source-labelled grizzly benchmark and process-native global
  density, patch transition/density, generic introduction and optional exact
  pedigree-ancestry modules.
- Standardised built-in demographic decisions on one pre-process state and made
  offspring sex an explicit modeller callback.
- Retained strict compilers for modeller-supplied demographic tables while
  removing packaged biological schedules and silent unmatched-row defaults.
- Removed controller-era lifecycle mutators and the incompatible old-output
  summary, plotting, management, uncertainty, sensitivity and calibration
  stack without compatibility adapters.
- Simplified current API, delivery documentation and dependencies around the
  process-native product. Removed the obsolete Quarto project and dormant
  YAML/targets/reporting dependencies; Stage 4 will add tools back only with an
  executable consumer.
- Right-sized repeated test evidence and CI execution while retaining distinct
  scientific oracles, process-order, accounting, RNG and pedigree contracts.
- Added an installed-package Lord Howe Island woodhen modeller project with
  explicit sexes, territories and floaters, captive-programme receipts,
  retained parentage and reloadable replicate evidence.

This development line intentionally contains breaking changes. Historical
delivery records and artefacts remain in the repository as provenance.

## OpenPVA 1.0.0

- Established the first R package, seeded scenario, YAML, targets, Quarto,
  spatial/genetic and analysis prototypes.
- Published the R 4.6.1 Mac/CI readiness baseline and release-candidate evidence.

Those prototypes informed the current design but do not override the active
North Star or public API.
