# Website Structure and Navigation — Design (Phase 2)

**Date:** 2026-08-13
**Scope:** Phase 2 of the prathmeshrmadhu.github.io revamp — information architecture, navigation, and URLs. Phase 1 (content) is complete and live. Phase 3 (visual design) is out of scope.

## Goal

Collapse a flat six-item navigation into four coherent sections, make every URL match its label, and remove theme scaffolding the site does not use.

## Why

Phase 1 left the site with six top-level nav items of wildly uneven substance: Publications (21 entries) and Selected Work (6 entries) carry real weight, while Talks (3 entries, newest February 2020), Teaching (3 entries, newest April 2020), and Blog (4 posts) each occupy the same visual prominence. Two nav labels also disagree with their URLs — "Selected Work" lives at `/portfolio/` and "Blog Posts" lives at `/year-archive/`, the latter being a theme implementation detail leaking into the address bar. Separately, six theme pages are publicly reachable but absent from nav, two of which render nothing at all.

## Decisions

Each of these was chosen explicitly by the user on 2026-08-13.

1. **Publications, Talks, and Teaching merge into one Research section** — grouped, not deleted. Nav drops from six items to four.
2. **Research is a single page with three inline sections**, not a hub of links. A researcher arriving from a paper reaches the publication list in one click with no intermediate menu.
3. **All URLs are renamed to match their labels**, with `redirect_from` preserving every old URL.
4. **All six orphaned theme pages are deleted**, along with the talkmap assets.
5. **Case studies get an explicit manual order**, strongest-measured first.
6. **The 2011 Jharna tuition entry is dropped**; both 2020 FAU talks are kept.
7. **The Research page gets a substantial framing paragraph**, so that it is a document with a point of view rather than a duplicate of the CV's collection listings.

## Architecture

### URL map

| Nav label | URL | `redirect_from` |
|---|---|---|
| Selected Work | `/work/` | `/portfolio/` |
| Research | `/research/` | `/publications/`, `/talks/`, `/teaching/` |
| Blog | `/blog/` | `/year-archive/`, `/wordpress/blog-posts/` |
| CV | `/cv/` | — |

`jekyll-redirect-from` is verified working on this site: it is listed in `_config.yml` `plugins:`, `_site/about/index.html` builds locally from `about.md`'s `redirect_from`, and both `https://prathmeshrmadhu.github.io/about/` and `/about.html` return HTTP 200 live.

Note that `/wordpress/blog-posts/` is an **existing** redirect already declared in `_pages/year-archive.html`. It must be carried onto the new blog page, not dropped.

Individual entry pages are untouched. All 21 publications, 6 case studies, 3 talks, and 2 remaining teaching entries keep their current permalinks. Only the four index pages change.

### File structure

**Create:**
- `_pages/research.md` — framing paragraph plus three collection sections
- `_pages/work.html` — renamed from `portfolio.html`, with sorted loop
- `_pages/blog.html` — renamed from `year-archive.html`

**Delete:**
- `_pages/publications.md`, `_pages/talks.html`, `_pages/teaching.html` (merged into `research.md`)
- `_pages/portfolio.html`, `_pages/year-archive.html` (replaced by renames)
- `_pages/category-archive.html`, `_pages/tag-archive.html`, `_pages/page-archive.html`, `_pages/collection-archive.html`, `_pages/sitemap.md`, `_pages/talkmap.html`
- `talkmap/` directory, `talkmap.py`, `talkmap.ipynb`
- `_teaching/personal-coaching-2014.md`

**Modify:**
- `_data/navigation.yml` — six items to four
- `_config.yml` — remove `talkmap_link` (line 22) and the `category_archive:` / `tag_archive:` blocks (lines 288–293)
- `_includes/footer/custom.html` — remove the `/sitemap/` link, keep the file
- `_pages/about.md` — update the three "Where to go next" links to the new URLs
- `_portfolio/*.md` (all six) — add `order:` front matter

`_pages/404.md` is kept.

### Research page structure

```
layout: archive
title: "Research"
permalink: /research/
redirect_from: [/publications/, /talks/, /teaching/]

<framing paragraph — see below>

## Publications        (archive__subtitle)
  intro line linking FAU page + Google Scholar
  {% for post in site.publications reversed %} archive-single.html

## Talks
  {% for post in site.talks reversed %} archive-single-talk.html

## Teaching
  {% for post in site.teaching reversed %} archive-single.html
```

The three loops move over verbatim from the pages being merged. Talks uses `archive-single-talk.html` while the other two use `archive-single.html` — this is intentional, not an inconsistency to normalize; the talk include renders venue and date differently.

The prose line currently opening `publications.md` ("For the full list of academic publications, check out my official-webpage, Google Scholar profile.") is the only prose on any of the three merged pages and must survive into the Publications section.

### Research framing paragraph

Roughly 200 words, retrospective in stance: what the PhD work was about, why art-historical and archaeological imagery breaks standard vision models, and what ICC and ICC++ contributed to explainable analysis of image composition. Written in the user's own voice, consistent with the Phase 1 content principles (no money angle, no PDF CV, client work unnamed).

It is deliberately retrospective and makes no claims about current or future research directions, so it does not go stale and contains nothing unverifiable.

**This paragraph is what resolves the `/research/` vs `/cv/` duplication.** `/cv/` loops the same three collections (uncommented during Phase 1) and continues to do so — it is the complete formal record, serving the "the website *is* the CV" principle. `/research/` becomes the framed, opinionated reading of the same material. Two documents, two readers, one underlying set of collections.

### Case study ordering

Add `order:` to each `_portfolio/*.md` as an unquoted integer, then sort via an explicit assign:

```liquid
{% assign ordered_work = site.portfolio | sort: 'order' %}
{% for post in ordered_work %}
  {% include archive-single.html %}
{% endfor %}
```

The assign is required, not stylistic. Liquid's `for` tag parses its collection expression with `Expression.parse`, which handles variable lookups and literals but not filters, so a piped filter written directly into the `for` tag is silently ignored. The repo contains one instance of that mistake already — `_includes/group-by-array:21` uses `{% for name in __names | sort %}` — inherited from the theme, and out of scope to fix here.

Current behaviour is unsorted, which Jekyll renders alphabetically by filename — so the 9× SLAM result sits fifth and tf-cnnvis lands last only by accident of the letter "t".

| order | Entry |
|---|---|
| 1 | Real-time visual SLAM on edge hardware |
| 2 | Defect detection where models plateau |
| 3 | Agentic generation in a regulated domain |
| 4 | Hybrid multimodal retrieval for visual collections |
| 5 | LLM survey analysis at research scale |
| 6 | tf-cnnvis — seeing inside a convolutional network |

Quantified results lead; the public, inspectable artifact anchors the end.

## Forced consequences

Two deletions have dependencies that cause site-wide breakage if handled naively. Both were surfaced to and confirmed by the user.

**1. The footer links to `/sitemap/` on every page.** `_includes/footer/custom.html` contains `<a href="/sitemap/">Sitemap</a>`. Deleting the sitemap page without emptying this snippet produces a broken link on every page of the site.

The file must be **emptied of the link but kept in place** — `_layouts/default.html:23` does `{% include footer/custom.html %}`, and Jekyll raises a build error on a missing include. Retain the two HTML comments, remove the anchor.

**2. Deleting `/tags/` requires editing `_config.yml`.** `_includes/page__taxonomy.html` renders tag links whenever `site.tag_archive.type` is set, and the built post page at `_site/posts/2026/03/31/information-overload/index.html` was verified to emit `rel="tag"` links pointing at `/tags/#…`. The theme's own comment at `_config.yml:283` warns that the archive page must exist at the configured path "or you can expect broken links". So `category_archive:` and `tag_archive:` must be removed alongside the pages.

**Visible consequence:** blog posts will no longer display their tags. With five tags across three published posts this costs nothing navigationally, but it is a change to how posts render, and it is forced by the deletion rather than independently requested.

## Optional

Correct the permalink of `_posts/2020-07-12-rip-banerjee-sir.md`, which is dated 2020-07-12 but published at `/posts/2012/08/rip-banerjee-sir/`, and leave a `redirect_from` behind. Cosmetic and entirely skippable; included only because the redirect machinery is already being touched.

## Out of scope

- **The `author_profile` sidebar**, currently `true` on every page. It is a layout concern — Phase 3.
- **Nav dropdown submenus.** `_includes/masthead.html` loops `site.data.navigation.main` flat, rendering only `title` and `url` with no child support. Adding a dropdown means editing the masthead and its CSS — Phase 3.
- **The 13 favicon references** in `_includes/head/custom.html` pointing at images that have never existed in the repo. Pre-existing, Phase 3.
- **Publications reconciliation against Google Scholar.** Scholar blocks automated fetching; the user is doing this comparison personally.
- **Missing metrics** for the hybrid-retrieval and agentic case studies, whose Result lines are currently qualitative. Content work, awaiting the user's numbers.
- **The uncommitted `_posts/2026-05-03-work-love.md` draft** (empty `title: ''`, permalink copied from another post). Left untracked and untouched.

## Success criteria

1. `bundle exec jekyll build` completes with no errors or warnings.
2. Navigation renders exactly four items: Selected Work, Research, Blog, CV.
3. `/work/`, `/research/`, `/blog/`, `/cv/` all return 200 and render their expected content.
4. Every old URL resolves via redirect: `/portfolio/`, `/publications/`, `/talks/`, `/teaching/`, `/year-archive/`, `/wordpress/blog-posts/`.
5. `/research/` shows all 21 publications, 3 talks, and 2 teaching entries under three headings, plus the framing paragraph.
6. `/work/` lists the six case studies in the specified order.
7. The six deleted pages return 404, and no page in the built site links to them.
8. An internal-link check across `_site` finds no broken page links (the pre-existing favicon image references are known and excluded).
9. `/cv/` still renders its Education, Experience, Skills, Publications, Talks, and Teaching sections, now with the tuition entry gone.
