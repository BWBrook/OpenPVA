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
| Spatial patches/dispersal | Controller-era helpers and history-inferred connectivity | **Replaced in Goal 005** | Explicit domains, simultaneous ordinary processes, transition events and positioned patch counts |
| Newborn patch state | Former births omitted maternal `patch_id` | **Repaired by field contract** | Creator declares inheritance or initialization; missing downstream state fails |
| Genetics/inbreeding | Optional allele state plus heterozygosity-derived `F` | **Replace scientific core** | Pedigree/ancestry as primary IBM state; marker heterozygosity remains a separate observable summary |
| Management actions | Harvest and supplementation are privileged labels | **Retain biology, redesign composition** | Ordinary processes, repeatable/reorderable like any lifecycle event |
| YAML scenarios | Canonical schema configures existing fixed simulator | **Defer lifecycle expansion** | Keep current inputs during architecture work; do not add a process DSL |
| `targets`/`renv`/Quarto | Reproducible workflow machinery | **Retain outside engine** | Analysis orchestration and reporting, not process protocol |
| Uncertainty/sensitivity/calibration helpers | Broad analysis support | **Retain, defer expansion** | Reconnect after canonical engine acceptance; do not drive architecture |
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

Global density is published in Goal 004. Goal 005 implements explicit patch
domains, simultaneous transition events and positioned full-domain patch
counts; introductions and pedigree genetics remain later tranches.

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

Do not begin introductions or pedigree genetics until Goal 005 passes its
bounded acceptance review.
