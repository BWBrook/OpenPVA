# Goal 004 - Global density feedback

## Objective

Replace the disconnected controller-era density surface with the smallest
ordinary-process implementation of explicit global abundance measurement and
modeller-composed density feedback on vital rates.

## Required outcomes

1. A reusable ordinary process measures global living abundance at its exact
   lifecycle position, stores one declared snapshot in state, and emits a
   truthful engine-stamped event without changing population records or IDs.
2. A pure ceiling-style multiplier is exactly neutral at or below a positive
   user-supplied capacity and returns `capacity / n_alive` above it, including
   a defined zero-abundance result.
3. Survival, breeding and fecundity effects are expressed explicitly inside
   existing process callbacks. OpenPVA must not add privileged channels,
   controller branches, modifier registries or a density specification object.
4. A compact source-labelled synthetic extension demonstrates the contract
   without changing the five canonical Goal 003 scenarios or claiming an
   empirical grizzly capacity.
5. The controller-era `density_spec()`, `validate_density_spec()`,
   `.eval_density_multiplier()` and `make_ceiling_density_fun()` surfaces and
   their current tests/help are removed without aliases or adapters.
6. Current-facing plans record the accepted Stage 3 sequence: global density;
   patch-aware dispersal and patch density; generic introductions and
   supplementation; optional pedigree-based genetics.

## Scientific boundary

The ceiling multiplier is phenomenological vital-rate feedback. It is not a
hard population cap, an empirical carrying capacity, a guaranteed equilibrium,
or population truncation. The modeller owns the capacity, the affected vital
rates and the explicit composition of base, density and environmental terms.

Future genetics will treat pedigree and ancestry as primary individual-based
state. Marker heterozygosity is a separate observable summary and must not be
used as a surrogate definition of pedigree inbreeding.

## Acceptance evidence

- Exact zero, below-, at- and above-capacity multiplier cases and invalid inputs.
- Exact snapshot state/event semantics, no population/ID mutation, and failure
  when a declared consumer lacks its upstream snapshot.
- Neutral equivalence and independent expectation checks for survival,
  breeding-only, fecundity-only and combined reproduction feedback.
- A modeller-visible process-order falsification.
- Exact accounting, provenance, seeded repeatability and serial/fork identity.
- Focused and full tests pass; isolated package build and check succeed;
  intended public/retired surface scans and `git diff --check` are clean.

## Non-goals

Patch density, dispersal, supplementation, genetics implementation, YAML,
uncertainty, sensitivity, calibration, targets, Quarto/reporting, release
evidence, `renv` reconciliation, empirical calibration, compatibility layers
and engine redesign are outside this goal.

## Publication boundary

No staging, commit, push, tag or release is authorised by this goal.
