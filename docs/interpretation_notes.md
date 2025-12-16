# Interpretation notes (artefact behaviour)

Purpose: record what the software artefacts *actually do* after changes.
This is not a diary; it’s a “what I saw when I ran it” record.

For each major change, create an entry.

---

## Entry template

### [YYYY-MM-DD] [Short title, e.g. “Repro EV scaffold added”]

- **Change summary**:
  - …
- **Artefacts inspected**:
  - Tests: (what ran, pass/fail)
  - Targets: (what ran, pass/fail)
  - Quarto: (what rendered, pass/fail)
  - YAML scenarios: (which, pass/fail)
- **Observed behaviour**:
  - Bullet points: what changed in outputs; any surprising patterns.
- **Domain sanity**:
  - Are probabilities bounded?
  - Any suspicious extinction dynamics?
  - Any implausible growth/explosions?
- **Follow-up tasks**:
  - [ ] …
  - [ ] …

---

## Summary (maintained by agent)

A short running summary of:
- what the current engine supports reliably,
- what is known to be brittle or incomplete,
- what the next milestone is.
