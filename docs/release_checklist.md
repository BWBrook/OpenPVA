# Release checklist (OpenPVA)

A release is a tagged, reviewable state of the repo with reproducible behaviour.

## Preconditions
- [ ] `docs/plan.md` current and honest
- [ ] `docs/decisions.md` updated for major changes
- [ ] `docs/interpretation_notes.md` updated for this release candidate
- [ ] Working tree clean; meaningful commits only

## Build & test
- [ ] `renv` restore works from clean checkout
- [ ] Unit tests pass
- [ ] Integration tests pass (YAML + scenario run at minimum)
- [ ] Minimal `targets` pipeline run succeeds
- [ ] Quarto demo renders (or defined minimal subset renders)

## Behavioural sanity
- [ ] Toy scenarios produce sensible dynamics (no obvious pathologies)
- [ ] EV/cat behaviour consistent with docs
- [ ] Management (harvest/supplement) metrics appear sensible
- [ ] Spatial/genetics scenarios still run (if included in release scope)

## Documentation
- [ ] README up to date (install, quickstart, examples)
- [ ] YAML schema documented (including any new fields)
- [ ] Any breaking/deprecated changes documented

## Versioning
- [ ] Version bumped appropriately (semver)
- [ ] NEWS/CHANGELOG updated (if present)
- [ ] Tag created and release notes drafted
