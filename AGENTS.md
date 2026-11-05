# AGENTS.md

Guidance for coding agents working in this repository.

## What This Is

This is the public Jekyll site for Bennington Area Makers
([www.bamvt.com](https://www.bamvt.com)), a nonprofit in Bennington, Vermont.
Its active program is youth robotics; the robotics site itself is the sibling
`../robotics.bamvt.com` repository. Most of this site is the preserved archive of
BAM's earlier WordPress makerspace site. GitHub Pages builds and deploys it from
the root of `master` (robotics.bamvt.com uses `main`). See **Hosting and deployment** in `README.md` for DNS,
redirects, and the asset host.

## Repository Boundary

Everything committed here is published. Account administration, migration and
recovery notes, and other private working material belong in the private
`../robotics` repository (for example `operations/`), not here.

`resources/` holds the WordPress SQL and XML exports, media backups, migration
audits, and state filings. It is ignored by Git and excluded from the build. Read
it as source material when needed, but never commit it or copy its contents into
pages or `_data/`. Jekyll loads every file under `_data/` regardless of Git
ignore rules, so never place private data there, even in an ignored subdirectory.

## Resuming Work

- Start with `git status --short --branch`, recent commits, and `git diff`.
  Preserve existing changes before switching branches.
- Check the associated PR's state and review comments before continuing a branch.

## Build and Preview

- Preview with `bundle exec jekyll serve --port 4002`. Port **4000 does not work
  in the maintainer's setup**, so never use bare `jekyll serve`. The robotics site
  uses 4001 and live reload on 35729; if you add `--livereload` here, also pass a
  different `--livereload-port` (for example 35730). Reuse an existing preview of
  this repository before starting another.
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

- New pages need `layout: default`, `title`, `description`, and
  `last_modified_at` front matter. Add a main-menu entry by editing `nav_items` in
  `_layouts/default.html`. Start the body with one `# Title`, then `##` sections
  and `###` subsections; the `event` and `article` layouts supply the `h1`, so
  their bodies start at `##`.
- The mailing address appears in the footer of `_layouts/default.html`,
  `contact.md`, `donate.md`, `index.md`, and `_includes/organization-schema.html`.
  The EIN is in `donate.md`. Update every copy when these change.
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

## Editorial Guidance

BAM and Bennington Area Robotics share an institutional voice. Follow the
**Editorial Style Guide** in `../robotics.bamvt.com/README.md`. In particular:

- Write clearly and warmly without being intimate, parental, or presumptuous.
- State expectations concretely; avoid slogans, scolding, and inferred motives.
- Treat members, students, families, volunteers, and donors as capable partners.
- Keep fundraising copy confident and active, but never obscure costs,
  restrictions, or how funds will be used.

## Sister Repository

`../robotics.bamvt.com` shares this site's sidebar layout, timestamp tooling,
sitemap approach, and IndexNow script, and its `AGENTS.md` and `README.md`
document the same conventions in more depth. Consult it for precedent, but check
this repository's README where the two differ: the sites' layouts, navigation
(hard-coded here, `_data/navigation.yml` there), and `bin/last-modified` rules
are not identical. Robotics content changes belong in that repository.

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
