# OpenPVA Documentation

This `docs/` directory contains the **design and governance documents** for the OpenPVA project.  
It complements the user-facing package documentation (function reference, vignettes) that will eventually live under a separate documentation site.

These markdown files are primarily aimed at:

- Core developers
- Contributors (including external collaborators)
- Automated coding agents (Codex, ChatGPT, etc.)

They describe what OpenPVA is, how it is architected, and how work in this repository should be carried out.

---

## Key Documents

- `overview_openpva.md` — What OpenPVA is and why it exists.
- `architecture_core.md` — Core architecture and design principles.
- `dev_conventions_r.md` — R coding and workflow conventions.
- `gapps_heritage.md` — Historical and conceptual background from GAPPS.
- `roadmap_and_scope.md` — Development phases and current scope.
- `use_cases_and_personas.md` — Intended users and canonical use cases.
- `agent_guidelines_codex.md` — Behavioural rules for automated agents.
- `docs_index.md` — Short index and suggested reading order.

For a quick orientation, start with `docs_index.md` and follow the recommended reading sequence.

---

## How These Docs Should Be Used

- **Humans:**  
  - Read these documents before making major changes to the architecture or conventions.  
  - Update them when design decisions change or new phases begin.

- **Automated agents:**  
  - Must treat these files as required context before editing code.  
  - Should obey the constraints and priorities expressed here.

These documents are part of the **contract** that keeps OpenPVA coherent as it grows.  
If you need to break with an existing convention, do so deliberately and update the relevant doc rather than silently diverging.
