# Ecologist Q&A and Interpretation Notes

Purpose: capture Barry Brook's scientist-in-the-loop questions and the
corresponding technical/modeling responses during human testing of OpenPVA.

This is a living working document. It should accumulate:

- ecological/modeling sanity-check questions,
- software-behavior explanations,
- interpretation notes on outputs and artefacts,
- follow-up actions or issues discovered during review.

Use this file as a structured companion to interactive human testing.

---

## Working Conventions

- Each review session gets a dated section.
- Each question gets:
  - a short title,
  - Barry's question,
  - Codex's response,
  - any follow-up action.
- If a question reveals a bug, ambiguity, or documentation gap, record it
  explicitly under follow-up.
- If a question changes scientific interpretation rather than code, record that
  too.

---

## Session 1

Date: 2026-03-13
Focus: ecologist-facing walkthrough of the current OpenPVA development line.

### Q1. Human-testing protocol

- **Barry's question**:
  - How should we run the scientist-in-the-loop sanity-check phase?

- **Codex's response**:
  - We should work from the ecologist-facing surface inward:
    1. packaged YAML demos and simple R scenarios,
    2. summary outputs and plots,
    3. interpretation of demographic, density, management, spatial, and
       genetic behavior,
    4. any scientific or usability concerns exposed by those runs.
  - As questions arise, I will answer them, trace them back to the relevant
    code/doc paths when useful, and keep this file updated as the running
    record.

- **Follow-up action**:
  - Begin with a minimal demographic sanity-check run using one packaged demo
    scenario and inspect the core outputs from an ecologist's perspective.

---

## Open Questions Queue

- None yet. Add items here when a question needs a follow-up run, code change,
  documentation update, or scientific decision.
