# Design: density dependence module (future work)

Status: PLACEHOLDER (start after reproduction refactor stabilises)

## Goal

Replace survival-only K scaling with a modular density system that can scale multiple vital rates:
- survival
- breeding probability
- fecundity mean

Must work with:
- EV/cats multipliers,
- reproduction refactor,
- spatial structure (patch N),
- management (harvest/supplement).

## Candidate interface sketch

A density module provides one or more functions that accept state and return scaling factors, e.g.:

- `density$survival(state) -> scale`
- `density$breeding(state) -> scale`
- `density$fecundity(state) -> scale`

Where `state` might include:
- global N
- patch N
- optional age structure summaries

## Open design questions

- What minimal state is required (global N only vs patch N vs age structure)?
- How should density interact with patch K and global K?
- How do we express density in YAML (simple forms first, extensible later)?

## Deliverables

- a minimal interface
- at least one implemented density function
- tests + demo scenario
