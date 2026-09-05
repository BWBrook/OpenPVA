# OpenPVA successor handover

Live repository state verified: 2026-09-05.

## Project in one sentence

> The modeller defines the biological program; OpenPVA supplies the execution
> engine, reusable processes, scientific contracts, and reproducible analysis
> machinery.

OpenPVA is intended to be a modern, open-R descendant of the GAPPS
construction philosophy: a modeller composes an explicit ordered biological
program from ordinary R processes, while the engine provides reliable
execution, state and event contracts, RNG control, accounting, provenance and
analysis support. It is not a fixed lifecycle, black-box risk calculator, GUI,
or new modelling language.

## Start here

Work directly in `/Users/bwbrook/git/OpenPVA`. Read, in order:

1. `AGENTS.md` (highest-authority repository contract)
2. `docs/vision_and_scope.md` (North Star)
3. `docs/architecture_core.md`
4. `docs/design/lifecycle_process_contract.md`
5. `docs/plan.md` (current operational state)
6. `docs/goals/011-woodhen-modeller-vertical-slice/Goal.md`
7. `docs/goals/011-woodhen-modeller-vertical-slice/Log.md`

The `chief_of_staff` and `goal_composer` repositories, named action-agent
threads, and their mandatory packet/thread rituals are retired machinery. Do
not use them to bootstrap current work. Historical goal records in this repo
remain useful evidence, but current work should use the simplest proportionate
planning surface it needs.

Two current-facing documents contain dated programme-status paragraphs:

- `docs/vision_and_scope.md` still stops its current-decision narrative at
  Goal 007;
- `docs/design/realignment_gap_map.md` still has a stop rule written before
  Goal 010 was accepted.

Their product and architectural principles remain valid. For live status,
prefer this note, `docs/plan.md`, Git state and the active goal log.

## Live repository state

- Branch: `main`
- Goal 011 commit: `6a0c8e6` (`feat: add Woodhen modeller vertical slice`)
- Upstream: `main...origin/main`
- Goals 001-011: accepted and published
- Expected checkout state: clean, with no additional local or remote branches
  and no linked worktrees beyond `/Users/bwbrook/git/OpenPVA`

This handover is committed immediately after Goal 011, so its own documentation
commit is the expected `main` tip. Verify `git status --short --branch` and
`git log -3 --oneline` rather than treating any recorded tip as immutable.

## Architecture already established

Stages 1-3 and the pre-Stage 4 cleanup established one lean product surface:

- a lifecycle is a direct ordered list of validated `pva_process` objects;
- a process declares parameters, required fields and written fields, and
  returns state plus structured events;
- the engine owns interval time, replicate identity, stable IDs, L'Ecuyer-CMRG
  streams, failure context, event stamping, accounting and provenance;
- population identity is append-only; birth and introduction must initialise
  every field required downstream;
- serial and fork execution use preassigned replicate streams and must agree;
- census position is explicit, and stochastic means are checked against an
  independent life-table or matrix expectation where assumptions match;
- built-ins cover age, survival, reproduction, census, density snapshots,
  patch transitions/density and generic exogenous introductions;
- optional genetics is exact pedigree ancestry from declared founders and
  parents, not heterozygosity used as a proxy for inbreeding;
- the synthetic grizzly model is an acceptance benchmark, not a calibrated
  management model.

Do not restore the former fixed biological dispatcher, privileged lifecycle
labels, compatibility adapters, a second aggregate population representation,
or controller-owned biological defaults. YAML, `targets`, Quarto, a registry,
plugin framework, S4/R6 hierarchy, GUI and generic workflow framework remain
unearned until a concrete consumer demonstrates need.

## Goal 011: current review surface

Goal 011 asks whether an ordinary R modeller can build a useful PVA outside the
package using only the installed public API. The model project under
`inst/examples/woodhen/` translates the 1980 Lord Howe Island woodhen recovery
comparison from `rPVA` commit `8727caa` into three common-start, 40-year
scenarios:

1. no intervention;
2. pig control;
3. pig control plus captive breeding and releases.

Important translation decisions:

- The female-equivalent source state becomes explicit female and male
  individuals.
- Source female recruitment is converted to total offspring before an explicit
  50:50 sex draw.
- One-to-one mate availability and annual territory occupancy are explicit.
  At most `K` pairs breed; surplus mature birds remain visible floaters instead
  of being deleted by the source model's hard ceiling.
- Annual conditions, territory assignment and scheduled capture remain
  project-local processes. One consumer has not earned generic APIs for them.
- The combined programme records capture of up to four pairs and release of 13
  pairs in each of three years (78 birds total).
- Every record retains mother and father IDs. Exact pedigree reconstruction is
  tested on a short matched run, but long-horizon coefficients are not computed
  because genetics does not yet affect fitness and the cost was disproportionate.
- No aggregate `F`, lethal-equivalent, purging or inbreeding-fitness effect is
  imposed.
- The model is historically grounded and illustrative. It is not recalibrated,
  contemporary management advice, or a numerical reproduction of rPVA/GAPPS.

Validation was recorded on 2026-08-16. The live diff remained the same intended
tranche, and the full tests, lint and environment status were run again at the
2026-09-05 publication boundary:

- 22 focused Woodhen tests passed;
- the full suite passed 505 assertions with no failures, warnings or skips;
- lint, `git diff --check` and `renv::status()` were clean;
- a fresh R 4.6.1 source-package check completed with status `OK`;
- an installed-package run from `/tmp` completed eight replicates per scenario;
- all 24 replicate accounting rows reconciled and pair capacity was never
  exceeded;
- the combined scenario recorded exactly 78 introductions and 8 removals;
- the reloadable RDS retained 112,975 known-parentage records and was about
  838 KB.

The small smoke ensemble produced horizon extinction estimates of 0.625, 0
and 0 for the three scenarios. Treat these only as workflow evidence with large
Monte Carlo error, not management estimates or a ranking of the intervention
scenarios.

Material residuals, not Goal 011 blockers:

- stable-ID territory assignment is reproducible occupancy bookkeeping, not a
  behavioural model of competition, tenure or pair bonds;
- complete individual and parent ledgers make large ensembles comparatively
  slow;
- ecological parameters and environmental variation are inherited teaching
  assumptions rather than a fresh empirical calibration.

## Recommended continuation

Goal 011 is accepted and published. Inspect commit `6a0c8e6` and its evidence
directly when deeper context is needed; do not reopen it or rerun successful
gates ceremonially unless code changes or a specific risk warrants it.

After Goal 011, keep Stage 4 consumer-led. Do not generalise the Woodhen result
bundle or its local processes from one example. Select a second biologically
distinct external model that stresses a different real modeller need, then
promote only repeated friction into core API. A management-removal or spatial
case would be more informative than prematurely restoring YAML, orchestration
or reporting. Treat the Woodhen runtime as a measured performance signal, but
profile before redesigning the engine.

## Working style and skills

Barry wants an assertive senior scientific collaborator: make reversible
technical decisions, challenge weak science or over-engineering, protect his
attention for consequential scientific and strategic choices, and report at a
meaningful synthesis point rather than after every internal step.

Use these personal skills when applicable:

- `/Users/bwbrook/.codex/skills/twilight-laboratory/SKILL.md` for staged
  scientific programmes, decision boundaries, native subagent use, evidence
  review and the 80/20 reporting horizon;
- `/Users/bwbrook/.codex/skills/kill-your-darlings/SKILL.md` for periodic lean
  audits of code, tests, CI, dependencies and dormant abstractions.

Core discipline: rigour at scientific decision boundaries, proportional
engineering everywhere else. Perform the meaningful implementation and its
risk-matched checks, conduct one serious review/repair pass, and stop when
further work is mostly polish. Publication and consequential scientific choices
still require the authority stated in the live request.
