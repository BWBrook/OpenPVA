# Runbook

## Work boundary

Work only in the files named by Goal 001. Preserve all unrelated and inherited
changes. If another author changes an in-scope file, re-read and integrate rather
than overwrite.

## Evidence rules

- Prefer primary application papers, reports, manuals, and theses.
- “Used GAPPS” requires evidence of an actual configuration or run; software
  reviews and bibliography mentions are labelled separately.
- Do not infer commands or capabilities from filenames or recollection.
- Record inaccessible sources and acronym collisions.
- Separate observed source content, synthesis/inference, and OpenPVA design choice.

## Documentation checks

```sh
git diff --check
rg -n "Phase 1|current focus|fixed sequence|roadmap_and_scope" \
  docs/vision_and_scope.md docs/overview_openpva.md docs/architecture_core.md \
  docs/docs_index.md docs/README_docs.md docs/plan.md
git diff --name-only
git diff --stat
git status --short --branch
```

Check internal Markdown targets with a read-only path-existence script. Check DOI
and public URLs only for metadata/reachability; do not download artefacts.

## Prohibited checks

No R, `renv`, tests, checks, `targets`, Quarto, build, lint, release, commit, or
push commands.

## Stop rule

After one focused diff review and repair pass, stop when further edits are
stylistic and no longer change the product or scientific decision.
