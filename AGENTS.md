# AGENTS.md

Guidance for coding agents working in this repository.

## What This Is

This is the public Jekyll site for Bennington Area Makers
([www.bamvt.com](https://www.bamvt.com)), a nonprofit in Bennington, Vermont.
Its active program is youth robotics; the robotics site itself is the sibling
`../robotics.bamvt.com` repository. Most of this site is the preserved archive of
BAM's earlier WordPress makerspace site. GitHub Pages builds and deploys it from
the root of `master`. See **Hosting and deployment** in `README.md` for DNS,
redirects, and the asset host.

## Repository Boundary

Everything committed here is published. Account administration, migration and
recovery notes, and other private working material belong in the private
`../robotics` repository (for example `operations/`), not here.

`resources/` holds the WordPress SQL and XML exports, media backups, migration
audits, and state filings. It is ignored by Git and excluded from the build. Read
it as source material when needed, but never commit it or copy its contents into
pages or `_data/`.

## Resuming Work

- Start with `git status --short --branch`, recent commits, and `git diff`.
  Preserve existing changes before switching branches.
- Check the associated PR's state and review comments before continuing a branch.

## Build and Preview

- Preview with `bundle exec jekyll serve --port 4002`. The robotics site uses
  port 4001; reuse an existing preview of this repository before starting another.
- Run `bundle exec jekyll build` to verify a change without a server. A clean
  build is the minimum check for content, layout, or Liquid changes.
- Run `ruby bin/tests/last_modified_test.rb` after changing `bin/last-modified`.

## Architecture

- `_layouts/default.html` holds the site's HTML, inline CSS, JavaScript, sidebar
  navigation, and footer. The navigation is a hard-coded list in that layout,
  reused in the footer; pages set `nav_section` to highlight a menu entry.
- `_layouts/event.html` and `_layouts/article.html` wrap archived events and posts.
- Root-level Markdown files are the current pages. `archive/original-home/` is
  the original WordPress homepage; `blog/` and `events/` are archive indexes.
- `_events/` (an output collection) holds 18 historical WordPress events, and
  `_posts/` holds the one retained article. Their permalinks match the original
  WordPress URLs; do not change them.
- `_data/event_venues.json` and `_data/event_organizers.json` supply event details
  by ID. `_data/legacy_content.json` feeds `_includes/archive-list.html`.
  `_data/legacy_ids.json` drives `assets/js/legacy-links.js`, which resolves old
  WordPress `?p=` and `?page_id=` links.
- `_data/migration.json`, `_data/media_files.json`, and `_data/media_archive.json`
  record the migration mapping and media hashes. Treat them as records, not
  content to edit.
- `wp-content/uploads/` keeps all recovered WordPress media at the original paths
  and bytes. Do not rename, recompress, or delete these files. New images go to
  the Cloudflare R2 bucket served at `https://assets.bamvt.com`.

## Conventions

- Every content page has a unique `description` of at most 155 characters. See
  **Search metadata** in `README.md`.
- Pages using the `default`, `event`, or `article` layout carry a
  `last_modified_at` timestamp. Run `bin/install-hooks` once per checkout; the
  pre-commit hook stamps affected pages. Stage changes and commit without
  path arguments. Metadata-only edits do not advance the date. See **Page update
  dates** in `README.md` for the rules, backfilling, and repairing missed updates.
  Keep `bin/last-modified`'s dependency rules and tests aligned with new includes
  and data files.
- `sitemap.xml` overrides the plugin template and emits `lastmod` only from
  `last_modified_at`. Do not substitute post dates, file times, or build time.
  Removed WordPress pages intentionally return 404: do not add redirects,
  `noindex`, or `robots.txt` blocks for them, and do not recreate attachment or
  taxonomy pages. See **Sitemap inclusion** and **WordPress migration**.
- Do not rename or remove the IndexNow key file (the root `<hex>.txt`).
  `bin/indexnow` must stay identical to robotics.bamvt.com's copy; see **IndexNow**.
- Keep `CNAME` set to `www.bamvt.com` and `_config.yml`'s `url` to
  `https://www.bamvt.com`.
- Archived events and the article are historical records. Fix markup, links, and
  metadata, but do not rewrite their substance or present them as current.
  Fabricated or trashed WordPress posts stay excluded.
- Markdown uses kramdown. Styles and scripts live in the layout, not separate
  bundles. Follow the theme colors described under **Layout and theme**.
- Repository-only files (such as this one and `README.md`) must be listed under
  `exclude` in `_config.yml`, or Jekyll publishes them.
- Keep this file and `README.md` aligned with changes to structure, tooling, and
  conventions. Keep unrelated edits out of a task.

## Key Files

| File | Purpose |
|------|---------|
| `_config.yml` | Site metadata, plugins, build exclusions, and the events collection |
| `_layouts/default.html` | Main HTML, CSS, JavaScript, navigation, and footer |
| `index.md` | Homepage; robotics programs and BAM overview |
| `about.md`, `get-involved.md`, `donate.md`, `contact.md` | Current organization pages |
| `_events/`, `_posts/` | Archived WordPress events and article |
| `_data/` | Event details, archive listings, and migration records |
| `_includes/organization-schema.html` | Homepage Schema.org nonprofit data |
| `sitemap.xml` | Sitemap template with explicit `lastmod` dates |
| `bin/last-modified`, `bin/install-hooks` | Page timestamp tooling |
| `bin/indexnow` | IndexNow submission script |
| `wp-content/uploads/` | Preserved WordPress media at original URLs |
