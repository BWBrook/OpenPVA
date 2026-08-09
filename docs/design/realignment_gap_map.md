# Realignment gap map

## Decision frame

The question is not whether current features work. It is which current
responsibilities support the North Star and which architecture prevents a
modeller-defined biological program.

## Classification

| Area | Current evidence | Decision | Target |
|---|---|---|---|
| Individual/population helpers | Flexible lists and many tested lifecycle helpers | **Retain, then simplify** | Reuse behind explicit state and field contracts; avoid parallel representations without need |
| Seeded replicate execution and provenance | Established controller-owned seeded workflows | **Retain, redesign boundary** | Engine owns RNG/context; processes consume approved RNG service |
| Lifecycle configuration | Six allowed labels: age, survival, dispersal, breeding/births, harvest, supplementation | **Redesign** | Direct ordered list of validated third-party processes |
| Controller dispatcher | Conditional branch for every biological step | **Remove after replacement** | One generic process execution loop; no compatibility dispatcher |
| Reproduction coupled step | Mating, breeding draws and births concentrated in controller helpers | **Redesign incrementally** | Separate reusable processes or one composite process that still satisfies public contract |
| Density channels | Former survival/breeding/fecundity specification was disconnected from execution | **Replace** | Positioned ordinary abundance snapshots plus pure functions explicitly composed by the modeller |
| Spatial patches/dispersal | Useful optional functionality | **Retain, repair** | Conforming processes with field declarations and birth initialization |
| Newborn patch state | `create_individual()` call omits maternal `patch_id` | **Repair first implementation tranche** | Birth process initializes every downstream-required field; regression fixture |
| Genetics/inbreeding | Optional allele state plus heterozygosity-derived `F` | **Replace scientific core** | Pedigree/ancestry as primary IBM state; marker heterozygosity remains a separate observable summary |
| Management actions | Harvest and supplementation are privileged labels | **Retain biology, redesign composition** | Ordinary processes, repeatable/reorderable like any lifecycle event |
| YAML scenarios | Canonical schema configures existing fixed simulator | **Defer lifecycle expansion** | Keep current inputs during architecture work; do not add a process DSL |
| `targets`/`renv`/Quarto | Reproducible workflow machinery | **Retain outside engine** | Analysis orchestration and reporting, not process protocol |
| Uncertainty/sensitivity/calibration helpers | Broad analysis support | **Retain, defer expansion** | Reconnect after canonical engine acceptance; do not drive architecture |
| Release/compatibility adapters | Historical clean-up burden and contradictory decisions | **Remove when touched** | No backwards-compatibility preservation for realignment |
| Canonical empirical model | No accepted end-to-end benchmark | **Add** | Minimal grizzly benchmark and extension fixtures |

## Current defects and risks

### Fixed vocabulary

`R/lifecycle_pipeline.R` validates only six strings and
`R/simulation_core.R` dispatches them via conditional branches. Users can reorder
known events but cannot add a process without editing the controller. This is a
configurable fixed simulator, not yet a programmable PVA engine.

### Spatial newborn defect

`R/lifecycle_reproduction.R` creates newborns without maternal `patch_id`.
Patch density, occupancy and connectivity summaries can therefore omit or
misclassify newborns. This is code-read evidence; no test was run in this
documentation goal. The first implementation tranche must reproduce the defect
with a focused test before repair.

### Feature breadth before reference fidelity

Spatial, genetic, uncertainty and calibration capabilities arrived before a
canonical empirical acceptance model. Their existence is valuable, but they
cannot establish coherent lifecycle semantics or scientific credibility by
feature count.

### Contract contradictions

The decision log contains historical compatibility commitments that conflict
with the active clean-break policy. New decisions supersede those commitments
for the realignment; historical records remain for provenance.

## Shortest staged realignment

### Stage 0 — strategic acceptance (complete)

Review the North Star, canonical benchmark, lean contract and staged scope as a
single package. RNG, field/birth, event-detail and time/census mechanics are
locked target defaults; Barry's remaining decision is whether to accept the
strategy and authorise Stage 1.

### Stage 1 — generic execution seam and defect repair (implemented)

- Add focused tests reproducing fixed-dispatch and newborn-patch failures.
- Implement validated process/result objects and a generic ordered execution
  loop.
- Port only the minimal grizzly demographic processes.
- Repair newborn field initialization through the contract, not a patch-only
  special case.
- Remove the obsolete dispatcher; do not retain adapters.

Acceptance: a project-defined observation or management process runs without
controller edits, accounting fixtures pass, and stochastic means agree with an
independent life-table/matrix expected-value oracle within Monte Carlo error.

### Stage 2 — canonical grizzly benchmark

- Implement baseline and alternative female-survival/human-mortality scenarios.
- Add expected-value oracle, stochastic calibration, order-falsification, and
  event-accounting checks.
- Produce an inspectable, source-labelled reference analysis with no claim of
  empirical calibration.

Acceptance: all extension demonstrations in the canonical-model document pass.

### Stage 3 — migrate high-value existing modules

Port global density, patch-aware dispersal/patch density, generic
introductions/supplementation and optional pedigree genetics in that order.
Remove privileged controller channels as each is replaced. Validate output
equivalence only where semantics are intentionally unchanged.

### Stage 4 — reconnect interfaces and analyses

Reconnect YAML scenario compilation, uncertainty, sensitivity, calibration,
`targets`, and reporting to the accepted process engine. Keep YAML as parameter
configuration unless repeated real use establishes a need for a lifecycle DSL.

## Deferred work

- continuous landscapes and range-shift modelling;
- production calibration or integrated observation models;
- GUI and non-R plugin discovery;
- optimisation/POMDPs;
- large-scale performance redesign;
- full historical GAPPS syntax reproduction.

## Stop rule

Do not begin another horizontal feature tranche until Stages 0–2 establish the
programmable process seam and canonical scientific benchmark.
