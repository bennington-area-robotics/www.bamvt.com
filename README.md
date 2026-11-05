# Bennington Area Makers website

Jekyll site for [bamvt.com](https://www.bamvt.com).

## Local preview

```sh
bundle install
bundle exec jekyll serve --port 4002
```

Open http://localhost:4002. This uses a separate port from the robotics site on 4001.

Run `bundle exec jekyll build` to check changes before publishing.

## Hosting and deployment

GitHub Pages publishes this repository from the root of the `master` branch.
Merge site changes into `master` and check the Pages deployment before verifying
production. Run `bundle exec jekyll build` before publishing.

- The canonical address is **https://www.bamvt.com**. GitHub Pages redirects
  `bamvt.com` to `www.bamvt.com`, with HTTPS enforcement enabled.
- Cloudflare manages DNS. The apex uses GitHub Pages' four published A records;
  `www` is a CNAME to `bennington-area-robotics.github.io`. Both use **DNS only**.
- Keep the production `CNAME` file set to `www.bamvt.com` and `_config.yml`'s
  `url` set to `https://www.bamvt.com`. Changing the custom domain in GitHub's
  Pages settings can commit a `CNAME` change directly to `master`; sync that
  change locally before publishing further changes.
- Cloudflare Redirect Rules send `test.bamvt.com`, `bamvt.net`, `bamvt.org`,
  and configured subdomains of the latter two to `https://www.bamvt.com`,
  preserving paths and query strings. Their source DNS records must remain
  **Proxied** for the rules to run. Manage these redirects in Cloudflare.
- Shared media is served from **https://assets.bamvt.com**, backed by Cloudflare
  R2. The homepage robotics photo uses this host. Migrated WordPress media
  remains in this repository under `wp-content/uploads/` to preserve old URLs.

After a deployment, check HTTPS, the apex redirect, navigation, and images.
Account administration, migration and recovery notes, and remaining WordPress
archive work are maintained separately in the private working repository.

References: [GitHub Pages custom domains](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site)
and [Cloudflare Redirect Rules](https://developers.cloudflare.com/rules/url-forwarding/single-redirects/create-dashboard/).

## Layout and theme

`_layouts/default.html` adapts the sidebar, reading area, mobile menu, and footer navigation from the sister robotics site. Page content lives in the root Markdown files.

The layout's CSS variables define a charcoal (`#1a1a18`) and sunflower yellow (`#f2c230`) theme on warm paper (`#fcfbf7`). Yellow marks navigation, buttons, and section rules; body links use deep ochre (`#765700`) for readable contrast. The mobile navigation remains available when JavaScript is disabled.

## WordPress migration

The homepage presents robotics as BAM’s active program. Earlier makerspace material remains available as history, including the original homepage at `/archive/original-home/`.

The migration initially preserved 41 published content records and 49 attachment pages. The October 2026 cleanup removes those attachment wrappers and 39 taxonomy, author, venue, and organizer pages. Their HTML URLs now return 404. All 425 recovered media files, including image sizes and the garden-workshop PDF, retain their original bytes and paths. The 18 historical events and gardening article remain available.

- Edit current pages in the root Markdown files, historical events in `_events/`, and the gardening article in `_posts/`.
- `_data/event_venues.json` and `_data/event_organizers.json` supply event details. Two organizer names that already appeared in a public event remain credited; their draft pages were not published.
- `_data/migration.json` records the original migration mapping for 90 content/media records, including wrappers since removed; `_data/media_files.json` records file sizes and SHA-256 hashes.
- Removed category, tag, author, venue, organizer, and attachment pages have no redirects or robots.txt blocks. Venue and organizer details remain on the event pages. `/how-you-can-help/` redirects to `/get-involved/`. The former event slug `/event/3-23-2020-personal-cybersecurity/` redirects to `/event/personal-cybersecurity/`. The small script in `assets/js/legacy-links.js` resolves retained WordPress page IDs and sends attachment IDs directly to the original media files. Removed venue and organizer IDs are absent from its data map. These query links require JavaScript on static hosting.
- Videos remain YouTube embeds. Historical registration forms and other external services remain links, with historical notices on the archive pages.

The owner confirmed the seven suspect maker-themed articles were fabricated. They and all other trashed posts remain excluded. SQL, XML, drafts, revisions, and private audit/recovery files stay under the ignored and build-excluded `resources/` directory. No WordPress theme or plugin code is imported.

Migration verification covered retained prose, original sitemap paths, internal links, media hashes, image decoding, PDF active-content checks, and browser rendering. The cleanup additionally checks sitemap canonicals, internal links, and 404 responses for removed pages. Five camera JPEGs have valid primary images but missing secondary-frame data in the recovered files; they are preserved unchanged. This covers the supplied exports and known media references, not unknown files from the hosting account. Embedded videos and third-party resources are not offline backups.

Legacy URL coverage applies to retained public records, recovered media, and stored prior slugs; the removed thin pages intentionally return 404. Redirect pages use Jekyll’s HTML redirects, not server-level HTTP 301 responses. Arbitrary calendar views, feeds, date archives, and undocumented historical paths are not exhaustively mapped; hosting access logs or an older URL inventory would be needed to audit those. Spam paths intentionally have no redirects.

## Sitemap inclusion

`jekyll-sitemap` submits 31 substantive HTML pages. The original homepage archive
remains included because it documents BAM's early activities and mission. The empty
attribution page and short calendar handoff keep their URLs but use `sitemap: false`.
The blog archive includes context for its preserved gardening announcement.

PDF downloads remain linked and available, but `_config.yml` excludes them from
the sitemap because static downloads have no self-referencing canonical metadata.
Do not recreate attachment or taxonomy wrappers, add `noindex` to retained pages,
or block removed URLs in `robots.txt`; crawlers need to see their 404 responses.

## Search metadata

Every content page, including archived events and the 404 page, has a unique
`description` of at most 155 characters. The layout uses it for the meta,
Open Graph, and Twitter descriptions. The homepage sets a shorter `seo_title`.

The homepage alone includes `_includes/organization-schema.html`, describing BAM
as Schema.org `NGO` with `Nonprofit501c3` status. `NonprofitOrganization` is not a
Schema.org type. The two robotics programs are suborganizations; `sameAs` contains
BAM's own Facebook group, not the teams' social profiles.

The local `sitemap.xml` overrides jekyll-sitemap's default template. It emits
`lastmod` only for an explicit `last_modified_at` that records a real content
change; absent that evidence, it omits the date. Do not fall back to Jekyll's
collection `date`, file modification times, or build time. Static downloads have
no lastmod. Existing sitemap exclusions remain in force.

## Page update dates

Pages using the `default`, `event`, or `article` layout carry a `last_modified_at`
ISO 8601 timestamp with a timezone. The layout shows it as "Last updated" below
the content, and the sitemap uses it for `lastmod`. Archived articles and events
keep their original dates; `last_modified_at` records when this site's copy last
changed.

Run `bin/install-hooks` once per checkout. The pre-commit hook runs
`bin/last-modified --staged`, which stamps affected pages in the index and updates
only the timestamp in their working copies, so partially staged edits stay partially
staged. Stage changes first and run `git commit` without file/path arguments; the
hook rejects path-limited commits. The installer preserves an existing hook and
explains how to integrate with it.

A content change is a change to the body or to front matter other than search and
routing metadata (`description`, `seo_title`, `sitemap`, `nav_section`,
`permalink`, `wordpress_id`, and `redirect_from`). Editing only those keys does not
advance the date. Changes to included content and the `site.data` files it reads
update the pages that include it; `archive-list.html` makes the blog and event
indexes depend on `_data/legacy_content.json`. Event pages depend on their own
entries in `_data/event_venues.json` and `_data/event_organizers.json`, not on
unrelated entries. Layouts, `organization-schema.html`, and `video.html` do not
advance dates.

`bin/last-modified --backfill` initializes missing timestamps from the latest
commit that changed a page's content or sources, skipping metadata-only commits.
The initial dates were set this way. New pages without history get the current time.

The **Page timestamps** GitHub workflow runs the tests and flags missing timestamps
and changed pages whose timestamps did not advance. For GitHub web edits, update
`last_modified_at` by hand; to repair missed updates locally, stage the content and
run `bin/last-modified --staged BASE`. `bin/last-modified --check BASE HEAD`
reproduces the check, and `ruby bin/tests/last_modified_test.rb` runs the tests.
The script is adapted from robotics.bamvt.com's `bin/last-modified`; the
page, include, data, and metadata rules differ, so the copies are not identical.

## IndexNow

`bin/indexnow` submits published pages to IndexNow, which shares submissions with
Bing, Yandex, Seznam, Naver, and Yep. Google does not use IndexNow; request
indexing for important pages through URL Inspection in Search Console instead.
Run the script after GitHub Pages has deployed a change:

```bash
bin/indexnow --dry-run --since 2026-11-01  # list sitemap pages changed since a date
bin/indexnow --since 2026-11-01            # submit them
bin/indexnow /events/ /blog/some-post/     # submit specific paths or URLs
bin/indexnow --all                         # submit every sitemap URL
```

The key is the single `<key>.txt` file in the repository root, published
unchanged at the site root; the script reads it and takes the host from `CNAME`.
This site's key differs from robotics.bamvt.com's. `--since` uses the sitemap's
`lastmod` dates, which the timestamp hook maintains (see **Page update dates**).
Submit only changed pages; repeated submissions of unchanged URLs can
be throttled. The same script is kept in `robotics.bamvt.com` and
`www.bamvt.com`; keep the copies identical.
