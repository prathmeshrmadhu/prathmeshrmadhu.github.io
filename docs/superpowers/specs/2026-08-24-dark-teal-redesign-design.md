# Phase 4 — Dark teal redesign

**Date:** 2026-08-24
**Status:** Approved, ready for implementation planning
**Source design:** `Portfolio website mockups.zip` → `design_handoff_portfolio_site/`
(`README.md` handoff spec + `Portfolio Homepage.dc.html` prototype)

## Goal

Replace the site's entire visual layer with the approved deep-teal / amber design: a dark
ground (`#08302A`), a single amber accent (`#F0A202`), Space Grotesk + JetBrains Mono, and a
type-and-geometry graphic system with zero images. Rebuild all seven routes and all 36 detail
pages on a written design system rather than overrides of the Minimal Mistakes theme.

This supersedes the Phase 3 (ochre-on-cream palette, Georgia serif) and Phase 3.1 (card
component, CV stylesheet) visual work. The content work from those phases survives — see
"What survives from Phase 3/3.1".

## Why this is a rewrite, not a restyle

The approved design shares nothing with Minimal Mistakes' visual system: different palette,
different type, different grid, no masthead, no author sidebar. Under an additive approach
every element would be an override fighting a rule that still loads.

Measured evidence:

- `_site/assets/css/main.css` is **102,456 bytes** for a six-route site. Font Awesome, susy,
  and magnific-popup are the bulk of it, and the new design uses none of them ("no icon
  library, no SVG files" — handoff, Assets).
- `jekyll-archives` is commented out in `_config.yml` and no tag or category pages exist, so
  `_layouts/archive-taxonomy.html` and the tag/category includes are already dead code.

**Chosen approach: strip Minimal Mistakes to its Jekyll plumbing and build a new design
system.** Keep `_config.yml`, the four collections, `_includes/head/`, `seo.html`, `base_path`,
analytics, and the feed. Delete the theme's visual layer.

**Rejected approaches:**

- *Additive overrides* — keeps 102 KB of competing CSS and a permanent specificity war.
- *Bespoke routes with patched detail pages* — two design systems in one repo with a visible
  seam at the boundary. Worst long-term maintenance.

## Branch strategy

**Work happens on a `redesign` branch, merged to `master` only after all success criteria
pass and the user has visually reviewed it.**

This is a deliberate one-time exception to the standing "commit straight to master" preference.
`master` is what GitHub Pages serves; a partially converted site — dark homepage, light
publication pages — would be publicly visible the moment it was pushed.

## Route map

Six nav items plus the homepage, reached via the wordmark.

| Route | Source file | Layout | Notes |
| --- | --- | --- | --- |
| `/` | `_pages/home.html` (new) | `home` | The five designed sections |
| `/work/` | `_pages/work.html` | `route` | 6 portfolio items |
| `/research/` | `_pages/research.html` | `route` | 21 publications by year, 3 talks, 2 teaching |
| `/blog/` | `_pages/blog.html` | `route` | Nav label "Blog"; URL unchanged |
| `/about/` | `_pages/about.md` | `route` | Demoted from `/`; prose bio |
| `/cv/` | `_pages/cv.md` | `route` | Markdown body unchanged |
| `/contact/` | `_pages/contact.md` (new) | `route` | Email, X, LinkedIn, location |

**Nav order:** Work · Research · Blog · About · CV · Contact. Plus the amber `Let's talk` pill
pointing at `/contact/`.

Decisions taken here and their reasons:

- **`/blog/` keeps its URL**, against the mockup's "Writing" nav label. `_pages/blog.html`
  already carries two `redirect_from` entries; stacking a third redirect layer on a live URL
  to gain a nicer word is a bad trade. The nav label becomes "Blog" so label and URL still
  agree, preserving the Phase 2 rule.
- **No `/capabilities/` route.** The mockup's nav includes it; it is the most consulting-
  flavoured word in the design and was cut. The four capability cards remain as a homepage
  section under a descriptive heading (see "Copy decisions").
- **`about.md` moves from `permalink: /` to `permalink: /about/`**, and its
  `redirect_from: [/about/, /about.html]` entries are **removed**. Leaving them would make two
  things claim `/about/`.
- **`about.md`'s "Where to go next" section is deleted.** The new homepage does that job;
  keeping it duplicates navigation inside prose.

## File structure

### Layouts — four, replacing seven

| File | Responsibility |
| --- | --- |
| `_layouts/base.html` | HTML shell: `<head>` includes, site header, `{{ content }}`, site footer |
| `_layouts/home.html` | Homepage only. Extends `base`, composes the five sections |
| `_layouts/route.html` | The six inner routes. Extends `base`, adds a page-title band |
| `_layouts/detail.html` | All 36 detail pages. Extends `base`, renders long-form prose |

**Delete:** `default.html`, `single.html`, `talk.html`, `archive.html`,
`archive-taxonomy.html`, `splash.html`.

**Keep `compress.html`.** It is not dead code — `_layouts/default.html:2` declares
`layout: compress`, so the theme's HTML whitespace compression is currently active and
configured under `compress_html:` in `_config.yml`. `base.html` must declare
`layout: compress` to preserve it.

### Includes

**Create:**

| File | Responsibility |
| --- | --- |
| `_includes/site-header.html` | Wordmark lockup, nav, `Let's talk` pill |
| `_includes/site-footer.html` | Footer: name, location, social links, copyright |
| `_includes/glyph.html` | The four CSS glyphs, selected by a `type` parameter |
| `_includes/metric-tile.html` | Amber number + mono caption |
| `_includes/work-card.html` | Rewritten. Feature and secondary variants via a parameter |
| `_includes/capability-card.html` | Glyph + H3 + body |
| `_includes/blog-card.html` | Rewritten against the new card primitive |
| `_includes/row-list-item.html` | Mono date + title, for publications and talks |

**Delete:** `author-profile.html`, `page__hero.html`, `masthead.html`, `sidebar.html`,
`nav_list`, `tag-list.html`, `category-list.html`, `social-share.html`, `breadcrumbs.html`,
`paginator.html`, `post_pagination.html`, `read-time.html`, `browser-upgrade.html`,
`archive-single.html`, `archive-single-cv.html`, `archive-single-talk.html`,
`archive-single-talk-cv.html`, `feature_row`, `gallery`, `toc`, `comment.html`,
`comments.html`, `comments-providers/`.

Comments are already disabled (`comments.provider` is blank in `_config.yml`), so the comment
includes are dead code. Deleting `archive-single-cv.html` also retires the invalid
`<li>`-inside-`<div><article>` markup that was held out of scope in Phase 3.1.

**Keep:** `head/`, `head.html`, `footer/custom.html`, `seo.html`, `analytics.html`,
`analytics-providers/`, `base_path`, `group-by-array`.

**`scripts.html` is reduced to `{% include analytics.html %}`.** Its
`/comments-providers/scripts.html` include goes with the comment system, and its
`main.min.js` reference goes with the JavaScript below.

### JavaScript — delete all of it

`assets/js/` is **316 KB on disk, and `main.min.js` is 131 KB shipped on every page view** —
larger than the CSS saving. It bundles jQuery 1.12.4 plus five plugins, every one of which
serves a feature this design does not have:

| Plugin | Serves | Status |
| --- | --- | --- |
| `jquery.greedy-navigation.js` | Minimal Mistakes' responsive masthead | Masthead deleted; nav toggle is CSS-only |
| `jquery.magnific-popup.js` | Image lightbox galleries | No galleries and no images in any content |
| `jquery.fitvids.js` | Responsive video embeds | No embeds or iframes in any content |
| `jquery.smooth-scroll.min.js` | Table-of-contents anchors | No TOC usage in any content |
| `stickyfill.min.js` | Sticky author sidebar | Sidebar deleted |

Verified by grepping all six content collections and `_pages` for `iframe`, `youtube`,
`vimeo`, `gallery`, `feature_row`, `toc`, and markdown image syntax: **zero matches.** The only
mentions of "video" are prose inside the fastai post.

`assets/js/collapse.js` (545 bytes) has **no references anywhere** in the repo. Confirmed
against the build: `_site` contains exactly two JavaScript files, `main.min.js` (131,019 bytes)
and `collapse.js` (545 bytes). `_main.js`, `plugins/` and `vendor/` are already listed in
`_config.yml`'s `exclude`, so they never shipped — but they are still 185 KB of dead source in
the repo.

Deleting the directory also means removing the three now-pointless `exclude` entries
(`assets/js/_main.js`, `assets/js/plugins`, `assets/js/vendor`) from `_config.yml`.

**Delete `assets/js/` in its entirety.** The redesigned site ships zero custom JavaScript;
the mobile nav toggle is a CSS-only `<details>` or checkbox pattern, and the handoff's
interaction list contains nothing else requiring script. Analytics, if enabled, remains the
only script tag.

The exact delete list must be verified by grepping for references before any file is removed.
Deleting a referenced include fails the build loudly, which is the desired behaviour, but the
grep is cheaper.

### Sass — a written system

New `assets/css/main.scss` import list:

```
tokens, reset, base, layout, header, hero, cards, prose, cv, footer, syntax, print
```

| Partial | Responsibility |
| --- | --- |
| `_tokens.scss` | Colour, type, space, radius, breakpoint variables. Single source of truth |
| `_reset.scss` | Retained from Minimal Mistakes; it is theme-neutral |
| `_base.scss` | Rewritten. Body, headings, links, focus states, `prefers-reduced-motion` |
| `_layout.scss` | 1180px container, 52px inset, band rhythm, hairline dividers |
| `_header.scss` | Header, wordmark, nav, CTA pill, mobile menu |
| `_hero.scss` | Hero grid, amber radial glow, blueprint grid, metric tiles |
| `_cards.scss` | Card primitive + capability / work-feature / work-secondary variants, chips, glyphs, rings |
| `_prose.scss` | Long-form detail pages: headings, lists, code, tables, blockquote, footnotes |
| `_cv.scss` | Rewritten against new tokens. Class names unchanged |
| `_footer.scss` | Rewritten |
| `_syntax.scss` | Rewritten for a dark ground |
| `_print.scss` | Rewritten. See "Print" below |

**Delete:** `_masthead.scss`, `_sidebar.scss`, `_archive.scss`, `_page.scss`,
`_navigation.scss`, `_utilities.scss`, `_animations.scss`, `_buttons.scss`, `_notices.scss`,
`_forms.scss`, `_tables.scss`, `_mixins.scss`, `vendor/susy/`, `vendor/font-awesome/`,
`vendor/magnific-popup/`.

**Keep:** `vendor/breakpoint/` — the mixin is small and already used in existing code.

## Design tokens

Taken verbatim from the handoff's token table, with two documented deviations.

**Colour** — two hues only. Everything else is `#F4F2ED` at an alpha. Do not add a third hue.

| Token | Value | Use |
| --- | --- | --- |
| `$ground` | `#08302A` | Page background; inverted text on amber |
| `$ink` | `#F4F2ED` | Primary text |
| `$accent` | `#F0A202` | Numbers, kickers, CTAs, glyph fills, links |
| `$ink-70` | `rgba(244,242,237,0.70)` | Lede |
| `$ink-62` | `rgba(244,242,237,0.62)` | Nav items |
| `$ink-60` | `rgba(244,242,237,0.60)` | Card body |
| `$ink-55` | `rgba(244,242,237,0.55)` | Metric captions |
| `$ink-52` | `rgba(244,242,237,0.52)` | Dates and eyebrows — **deviation, see below** |
| `$line` | `rgba(244,242,237,0.13)` | Card borders |
| `$line-soft` | `rgba(244,242,237,0.10)` | Band dividers |
| `$surface` | `rgba(244,242,237,0.05)` | Metric tile fill |
| `$chip` | `rgba(244,242,237,0.08)` | Chip fill |
| `$grid-line` | `rgba(244,242,237,0.04)` | Hero blueprint grid |

### Deviation 1 — accessibility

The handoff specifies `--ink-40` (`0.40`) for eyebrow text at 12px and `--ink-42` (`0.42`) for
dates at 11px. Both **fail WCAG AA**:

| Element | Spec | Measured ratio | Required |
| --- | --- | --- | --- |
| Section eyebrow | `0.40` @ 12px 400 | 3.28 | 4.5 |
| Writing date | `0.42` @ 11px 400 | 3.47 | 4.5 |

The minimum alpha reaching 4.5:1 on `#08302A` is **0.52** (measured 4.54). Both tokens
collapse into a single `$ink-52`. All twelve other text/background pairs in the design pass:
H1 12.80, amber-on-teal 6.73, lede 7.00, nav 5.82, feature body 6.69, card body 5.54, metric
caption 4.90, chip label 6.10, contact H2 on amber 6.73, contact body on amber 4.75.

### Deviation 2 — fonts self-hosted

Space Grotesk (400/500/600/700) and JetBrains Mono (400/500), self-hosted as **two variable
`woff2` files** in `assets/fonts/`, declared with `@font-face` and `font-display: swap`.

The handoff itself prefers this ("self-hosting is preferable for a GitHub Pages site"), and it
removes a third-party request from every page load. Both families are OFL-licensed; the
licence files ship alongside the fonts.

The prototype HTML loads four families — it also pulls Instrument Serif and IBM Plex Mono.
Those are prototype leftovers absent from the handoff's own token table. **Load two families
only.**

**Typography, spacing, radius, and responsive breakpoints** are taken from the handoff tables
as written (H1 64/1.0/700/−0.035em down to kicker 11px mono 500/0.12em; 4px base scale; radius
12/14/16/22/50%; breakpoints ≥1024, 768–1023, <768 with H1 at ~38px). **No shadows** — depth
comes from alpha surfaces and 1px borders.

## Section vocabulary

Nine primitives. The handoff designs only the homepage and instructs that other routes be
built "by extending the same section vocabulary". Naming the primitives explicitly is what
keeps the inner pages from being improvised.

1. **Band** — full-bleed section, `56px 52px`, optional top hairline (`$line-soft`)
2. **Heading row** — H2 + mono eyebrow baseline-aligned, or H2 + amber link space-between
3. **Card** — 1px `$line` border, radius 14 or 16; feature variant adds the amber gradient
   wash and two concentric decorative rings
4. **Kicker** — mono 11px, `letter-spacing: 0.12em`, `$accent`, uppercased in CSS
5. **Chip** — `$chip` fill, radius 14, mono 11px
6. **Metric tile** — 40px `$accent` number + mono caption on `$surface`
7. **Glyph** — the four CSS shapes: bars, target, dot matrix, quarter dial
8. **Inverted block** — amber ground, teal text. **Maximum one per page.** The scarcity is
   what gives it force
9. **Row list** — fixed-width mono date + title, baseline-aligned

### Homepage sections

1. **Header** — wordmark (CSS square-in-square, no image) + nav + amber `Let's talk` pill
2. **Hero** — factual pill, H1, lede, 2×2 metric grid, over the amber radial glow and
   blueprint grid
3. **What I work on** — four capability cards with glyphs
4. **Selected work** — 1.5fr feature card + two secondary cards, `View all six →`
5. **Blog + contact** — three writing rows beside the inverted amber contact block

### How each route is composed

| Route | Composition |
| --- | --- |
| `/work/` | Heading band; first item (by `order`) as the feature card, remaining five in a 2-up grid. Kicker from `result:` / `result_note:` |
| `/research/` | Three bands — Publications (row lists grouped by year, year as mono eyebrow), Talks (row lists), Teaching (row lists) |
| `/blog/` | Card grid, 2-up, kicker = post date, body = `excerpt:` |
| `/about/` | Single prose band, ~680px measure |
| `/cv/` | Existing kramdown IAL classes remapped onto primitives — see below |
| `/contact/` | One inverted amber block; email, X, LinkedIn, location |

Publications stay a **row list, not cards**. That was the Phase 3 decision and it holds; it now
has a native primitive instead of a fought-with archive style.

Deleting `_sass/_archive.scss` incidentally resolves the `/research/` publication-title
styling noted in the closed won't-do list (ochre + serif + bold + underline stacked). Those
rules cease to exist. This is a side effect of the rewrite, not a re-proposal.

## What survives from Phase 3/3.1

Only the CSS is discarded. The content work carries forward:

| Artefact | Fate |
| --- | --- |
| `cv.md`'s kramdown IAL structure | **Unchanged.** `.cv-date`→kicker, `.cv-role`→card H3, `.cv-org`→muted body, `.cv-cat`→eyebrow, `.cv-chips`→chips. Only `_cv.scss` is rewritten |
| `result:` / `result_note:` in `_portfolio/*.md` | **Unchanged** — becomes the kicker |
| The three real blog `excerpt:` values | **Unchanged** — feeds card bodies |
| Publications `sort: 'date' \| reverse` fix | **Kept** — a bug fix, not styling |
| CV `h1`→`h2` heading fix | **Kept** |
| CV publications condensation (count + five recent + link) | **Kept** |
| `_cards.scss`, `_cv.scss`, palette variables | Deleted and rewritten. The only real loss |

Naming the card slots generically in Phase 3.1 (`card__eyebrow` rather than `wcard__result`)
is what makes the front-matter keys survive unchanged.

## Data derivation

Every number on the site derives from content except one.

| Value | Source |
| --- | --- |
| Publication count (21) | `{{ site.publications \| size }}` |
| Work item count (6) | `{{ site.portfolio \| size }}` — drives "View all six" |
| Homepage work cards | `site.portfolio \| sort: 'order' \| limit: 3` |
| Homepage work kickers | `result:` / `result_note:` front matter |
| Homepage writing rows | `site.posts \| limit: 3` |
| CV recent publications | `site.publications \| sort: 'date' \| reverse \| limit: 5` |
| **320+ citations** | **Hardcoded literal.** Not derivable from the repo |

The mockup's three chosen work cards are exactly `order` 1, 2, 3 (SLAM, defect detection,
agentic regulated domain) and its kickers match the front matter character for character, so
the homepage needs no hardcoded project list.

**The citation figure is the single manual-refresh value on the site.** It lives in
`_config.yml` as `scholar_citations: "320+"` and is rendered as
`{{ site.scholar_citations }}`, never inline in a template, so there is exactly one place to
update it.

**The paper count is not hardcoded anywhere.** The mockup says `27 papers`; Google Scholar
reports 27 but six of those are duplicates, so the true figure is the 21 in `_publications`.
Deriving it means `/`, `/research/` and `/cv/` can never disagree.

## Copy decisions

The handoff's copy is kept where it traces to the user's own writing, and changed where it
frames the site as a service offering.

| Element | Mockup | Decision |
| --- | --- | --- |
| H1 | `Standard models fail. That's where I start.` | **Keep verbatim.** It is a compression of `about.md:17`, the user's own sentence. Second sentence in `$accent` |
| Lede | `Computer vision researcher and ML leader. Ten years across…` | **Keep verbatim.** Derived from `about.md:11` + `:17`. "Ten years" verified: ML Engineer from Jul 2016 |
| Hero pill | `OPEN TO COLLABORATION & ADVISORY` | **Replaced** with a factual statement: `SVP MACHINE LEARNING · INFOCUSP`. Pill shape and leading amber dot retained |
| Section 3 H2 | `What I can build for you` | **Replaced** with `What I work on` |
| Section 3 eyebrow | `/ four practice areas` | **Replaced** with `/ four recurring problems` |
| Capability card bodies (×4) | — | **Keep verbatim.** Factual and accurate to real work |
| Contact block H2 | `Have a problem that doesn't fit the benchmark?` | **Replaced** with `Working on something hard?` |
| Contact block body | `Pune, India. Collaboration, advisory and speaking.` | **Replaced** with `Pune, India.` |
| Contact block button | `Start a conversation →` | **Replaced** with `Get in touch →`, linking to `/contact/` |
| Metric tile 3 | `27` / `papers, 250+ citations` | **Replaced** with derived `21` / `papers, 320+ citations` |
| Writing rows | Three invented headlines | **Replaced** with the three most recent real posts |

The words "advisory", "practice areas", "what I can build for you" and "open to collaboration"
must not appear anywhere in the built site. This is an asserted success criterion, not a
guideline.

**Recorded tension:** the handoff states the design "carries no Infocusp brand cues — this is
a deliberately independent personal brand", while the chosen contact address is
`prathmesh@infocusp.com` and the hero pill names Infocusp. This is the user's explicit choice,
recorded here so it is a decision rather than an oversight.

## Detail pages

All four collections have `output: true`, so 36 detail pages exist behind the seven routes: 21
publications, 6 portfolio items, 3 talks, 2 teaching entries, 4 posts (3 tracked). The handoff
designs none of them.

All 36 render through `_layouts/detail.html` and `_sass/_prose.scss`, composed from the same
primitives: page-title band, kicker where the front matter supplies one, prose body at a ~680px
measure, chips for tags.

`_config.yml` `defaults` must be rewritten: every `layout: single` becomes `layout: detail`,
`layout: talk` becomes `layout: detail`, and **every `author_profile: true` is removed** — the
sidebar does not exist in this design.

`_prose.scss` must handle what long-form posts actually contain: headings h2–h4, ordered and
unordered lists, inline and fenced code, tables, blockquotes, images, footnotes, and links.
The Banerjee post is the longest and is the reference case for verifying prose styling.

## Print

The site **is** the CV — there is no PDF download, by the user's own standing rule. Someone
will press Ctrl+P on `/cv/`.

A dark-teal page prints either as a black rectangle or, with backgrounds suppressed, as cream
text on white paper. Neither is acceptable. `_print.scss` is therefore a **required
deliverable**, not housekeeping:

- Invert to black text on white for all printed output
- Hide the header nav, CTA pill, footer social links, and all decorative elements (glow,
  blueprint grid, rings, glyphs)
- Render chips as plain comma-separated text rather than filled pills
- Keep the CV's date / role / org hierarchy legible through weight and size, not colour
- Avoid page breaks inside a CV entry (`break-inside: avoid`)

## Interactions

From the handoff, all required:

- Nav hover: `$ink-62` → `$ink`, `transition: color 150ms ease`
- Amber pill and button hover: `translateY(-1px)` plus ~8% brightness, `160ms ease`
- Card hover: border `$line` → `rgba(244,242,237,0.28)` plus `rgba(244,242,237,0.03)` tint,
  `180ms ease`. Whole card is the click target
- Writing row hover: title → `$accent`
- **Focus states required on every interactive element:** `outline: 2px solid #F0A202;
  outline-offset: 3px`. Never suppress the outline without replacing it
- `prefers-reduced-motion`: drop the transforms, keep colour transitions

Mobile nav below 768px becomes a menu with `Let's talk` still visible in the bar. No
JavaScript framework — a checkbox or `<details>` toggle, since the site currently ships no
custom JS for navigation.

Contact is a `mailto:` link, not a form. The handoff notes that a form would need loading and
validation states designed; none exist, and a static site has nothing to post to.

## Success criteria

All must pass before merging `redesign` into `master`.

1. Clean build, zero errors, and **exactly 53 HTML pages** — unchanged from today. The
   arithmetic: `about.md` currently emits three pages (`/index.html` plus the `/about/` and
   `/about.html` redirects). After the change it emits one (`/about/`), and the new `/` and
   `/contact/` pages replace the two retired redirects. Net zero. A count other than 53 means
   something was lost or duplicated
2. Zero broken internal links, checking `path`, `path/index.html` and `path + '.html'`, and
   matching both root-relative and absolute `https://prathmeshrmadhu.github.io/...` href forms
3. `_site/assets/css/main.css` **under 25 KB** (from 102,456 bytes). Note that
   `_config.yml` already sets `sass.style: compressed`, so both figures are minified — the
   102 KB is not unminified bloat, it is genuinely that much CSS, most of it Font Awesome.
   Estimated new total is 15–20 KB across twelve partials; the 25 KB bar leaves room for
   `_prose.scss` and `_syntax.scss`, which are hard to size in advance
4. Zero occurrences of `author_profile`, `page__content`, `fa-`, `susy`, `magnific` in built
   output
5. Every text/background pair meets WCAG AA (4.5:1 body, 3:1 large), re-measured against the
   **compiled** CSS rather than this spec
6. `/cv/` print stylesheet asserted to produce dark text on a white ground
7. Derived counts hold: 21 publications, 6 work items, 3 writing rows on `/`
8. No hardcoded paper count anywhere; `320+` appears exactly once in the source
9. Zero occurrences of "advisory", "practice areas", "what i can build for you", "open to
   collaboration" (case-insensitive) in built output
10. `/about/` resolves as a real page; nothing else claims that URL
11. No horizontal overflow at 1440, 1024, 768 and 375 px
12. All 36 detail pages render via `detail.html`; none fall back to a deleted layout
13. Two font families requested, not four; both self-hosted, zero third-party font requests
14. Zero image requests on `/`
15. **Zero JavaScript requests** other than analytics. No `main.min.js`, no jQuery, no
    `assets/js/` directory in `_site`

### Verification method

Python assertions against built HTML in `_site/` and compiled CSS at
`_site/assets/css/main.css`, per the established pattern for this repo. There is no test
framework; it is a static site.

Build harness (no local Ruby; shell state does not persist between calls, so redefine per
call):

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
```

`jclean` before any assertion that something is **gone**; a stale `_site` will show old output.
Use Python `str.count`, never `grep -c`, which counts matching lines and is useless against
this theme's single-line markup.

### Known limitation

**Every criterion above is structural.** They can prove the CSS is under 20 KB, the links
resolve, the contrast maths is correct and the derived counts are right. They cannot prove the
site looks good. Phase 3.1 was never visually reviewed either. A human visual review of the
`redesign` branch is a merge precondition.

## Out of scope

- `_posts/2026-05-03-work-love.md` — untracked draft, empty `title`, date-mismatched
  permalink. It is the newest post by date, so `limit: 3` on the homepage yields a **blank top
  row locally** and a different set than live. Local checks must tolerate this. **Do not
  modify this file.**
- `images/safari-pinned-tab.svg`, `images/mstile-144x144.png` — provenance unresolved. **Do
  not delete.**
- `browserconfig.xml`, `.claude/launch.json` — left on disk deliberately.
- Google Scholar reconciliation — Scholar blocks automated fetching. The 21 vs 27 gap is
  resolved as duplicates by the user's own judgement.
- The two qualitative `result_note:` lines (`Auditable by design`, `Shipped to production`) —
  they need the user's figures; do not invent them.
- `Prathmesh Site Directions.dc.html` — the rejected-directions exploration board. The handoff
  marks it "Not for implementation."
- Dark/light theme toggle. The site is dark. No toggle was requested.

## Open item

The three real posts date `2026.03`, `2020.09` and `2020.07`. The design's writing section
implies recent, regular output; the reality is one post in 2026 and two from 2020. This is
accurate content and ships as-is. Noted only so the sparseness is expected rather than read as
a bug.
