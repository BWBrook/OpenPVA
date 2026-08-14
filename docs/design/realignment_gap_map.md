# Realignment gap map

## Decision frame

The question is not whether current features work. It is which current
responsibilities support the North Star and which architecture prevents a
modeller-defined biological program.

## Classification

| Area | Current evidence | Decision | Target |
|---|---|---|---|
| Individual/population helpers | Explicit list records plus strict table compilers | **Retained and simplified** | Reuse behind explicit state and field contracts; avoid parallel representations |
| Seeded replicate execution and provenance | Engine-owned reproducible streams and context | **Implemented** | Preserve serial/fork identity and caller RNG restoration |
| Lifecycle configuration | Direct ordered process list | **Implemented** | Validate ordinary third-party processes without a DSL |
| Controller dispatcher | Removed in Goal 002 | **Removed** | One generic process execution loop; no compatibility dispatcher |
| Reproduction | Process-native staged births with explicit modeller callbacks | **Implemented** | Preserve common pre-state, creator and accounting contracts |
| Density channels | Former survival/breeding/fecundity specification was disconnected from execution | **Replace** | Positioned ordinary abundance snapshots plus pure functions explicitly composed by the modeller |
| Spatial patches/dispersal | Controller-era helpers and history-inferred connectivity | **Replaced in Goal 005** | Explicit domains, simultaneous ordinary processes, transition events and positioned patch counts |
| Newborn patch state | Former births omitted maternal `patch_id` | **Repaired by field contract** | Creator declares inheritance or initialization; missing downstream state fails |
| Genetics/inbreeding | Former optional allele state plus heterozygosity-derived `F` | **Replaced in Goal 007** | Exact optional pedigree ancestry is primary IBM state; a future marker module must be separate and ID-keyed |
| Management actions | Harvest and supplementation were privileged labels | **Migrate in bounded tranches** | Generic exogenous introductions are ordinary processes in Goal 006; harvest/removal remains later work |
| YAML scenarios | Former fixed-simulator schema retained only as history | **Rebuild later** | Parameter compilation in Stage 4; never a lifecycle DSL |
| `targets`/`renv`/Quarto | Reproducible workflow machinery | **Retain outside engine** | Analysis orchestration and reporting, not process protocol |
| Uncertainty/sensitivity/calibration | Former old-output helpers removed in Goal 009 | **Rebuild later** | Stage 4 analysis over current events/results; do not drive engine architecture |
| Release/compatibility adapters | Historical clean-up burden and contradictory decisions | **Remove when touched** | No backwards-compatibility preservation for realignment |
| Canonical empirical model | No accepted end-to-end benchmark | **Add** | Minimal grizzly benchmark and extension fixtures |

## Historical defects and current risks

### Fixed vocabulary (resolved)

Goal 002 removed the former six-string dispatcher. The generic ordered process
loop is now the sole active execution seam.

### Spatial newborn defect (resolved)

The creation contract now requires every field consumed downstream. Reproduction
can explicitly inherit maternal `patch_id` or initialise it through a modeller-
supplied rule; omission fails at preflight or immediately after creation.

### Feature breadth before reference fidelity

Spatial, genetic, uncertainty and calibration capabilities arrived before a
canonical empirical acceptance model. Spatial and pedigree concepts were
reimplemented through the process contract; the incompatible analysis stack was
removed. Historical evidence remains useful but cannot establish current
scientific credibility by feature count.

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

### Stage 2 — canonical grizzly benchmark (implemented)

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

Global density is published in Goal 004 and patch transitions/density in Goal
005. Goal 006 implements generic exogenous introductions and Goal 007
implements optional exact pedigree ancestry through the same creator, event,
field and RNG contracts.

### Stage 4 — reconnect interfaces and analyses

Rebuild YAML parameter compilation, uncertainty, sensitivity, calibration,
`targets`, and reporting over the accepted process/event/output contracts. Keep
YAML as parameter configuration, not a lifecycle DSL.

## Deferred work

- continuous landscapes and range-shift modelling;
- production calibration or integrated observation models;
- GUI and non-R plugin discovery;
- optimisation/POMDPs;
- large-scale performance redesign;
- full historical GAPPS syntax reproduction.

## Stop rule

Do not begin marker genetics, fitness responses or Stage 4 reconnection until
Goal 009 is accepted and its clean product boundary is published.
