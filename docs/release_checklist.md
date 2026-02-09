# Release checklist (OpenPVA)

A release is a tagged, reviewable state of the repo with reproducible behaviour.

## Preconditions
- [x] `docs/plan.md` current and honest
- [x] `docs/decisions.md` updated for major changes
- [x] `docs/interpretation_notes.md` updated for this release candidate
- [ ] Working tree clean; meaningful commits only

## Build & test
- [ ] `renv` restore works from clean checkout
- [x] Unit tests pass
- [x] Integration tests pass (YAML + scenario run at minimum)
- [x] Minimal `targets` pipeline run succeeds
- [x] Quarto demo renders (or defined minimal subset renders)

## Behavioural sanity
- [x] Toy scenarios produce sensible dynamics (no obvious pathologies)
- [x] EV/cat behaviour consistent with docs
- [x] Management (harvest/supplement) metrics appear sensible
- [x] Spatial/genetics scenarios still run (if included in release scope)

## Documentation
- [x] README up to date (install, quickstart, examples)
- [x] YAML schema documented (including any new fields)
- [x] Any breaking/deprecated changes documented

## Versioning
- [x] Version bumped appropriately (semver)
- [x] NEWS/CHANGELOG updated (if present)
- [ ] Tag created and release notes drafted

## Automation (non-publishing)
- [x] `scripts/build_release_evidence.sh` reproduces a release evidence bundle
- [ ] Maintainer review completed for latest generated bundle
