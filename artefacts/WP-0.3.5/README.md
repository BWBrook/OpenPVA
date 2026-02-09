# WP-0.3.5 artefact bundle

This bundle captures Quarto site render stabilization evidence for `WP-0.3.5`.

## Changes validated

- Quarto output directory moved to `outputs/quarto_site` (no overwrite of authored `docs/*.md`).
- Navbar reduced to existing rendered pages (`index.qmd`, `about.qmd`) to avoid broken links.
- Project render list constrained to existing pages for deterministic smoke rendering.

## Render evidence

- Command: `quarto render quarto`
- Result: success (`render_post.log`)
- Output index: `outputs/quarto_site/index.html`
- Rendered file manifest: `site_files.txt`
