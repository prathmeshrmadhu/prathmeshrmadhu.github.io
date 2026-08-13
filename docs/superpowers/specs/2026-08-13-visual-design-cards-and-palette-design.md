# Visual Design — Cards and Palette (Phase 3)

**Date:** 2026-08-13
**Status:** Approved
**Phase:** 3 of 3 (content → structure → **visual design**)

## Goal

Give the site a coherent visual identity: a warm ochre-on-cream palette with serif headings applied site-wide, and a card layout for the six case studies on `/work/`.

## Why

Phases 1 and 2 fixed what the site says and how it is organised. It still looks like an unmodified Academic Pages install — grey `#7a8288` chrome, blue `#52adc8` links, sans-serif throughout. The content is now strong enough that generic presentation undersells it.

A second, independent reason emerged during design: the current link colour `#52adc8` on white measures **2.57:1**, which fails WCAG AA badly. Every link on the live site is affected today. The restyle fixes this as a side effect.

## Decisions

Each was chosen by the user from mockups during brainstorming.

1. **Cards live inside the existing theme.** The Minimal Mistakes masthead and author sidebar stay. No layout rewrite.
2. **Cards only on `/work/`.** Publications, talks, teaching and blog remain lists, restyled to match. Rationale: cards earn their keep for six items that are each a story; publications are 21 items scanned for a venue or a year, and the author lists are the part that proves collaboration.
3. **Palette A — warm ochre on cream.** No dark theme. No webfonts; Georgia is a system serif.
4. **Card style: no thumbnail.** Accent top rule and type only. No image assets required anywhere.
5. **Card furnishing level 2c** — cards carry a result line and tag chips, requiring two new front-matter fields.
6. **Reach: site-wide.** The palette is set in `_sass/_variables.scss` and every page inherits it.
7. **Implementation: new card include.** The shared `archive-single.html` is not modified.
8. **CSS Grid for the card grid**, not susy's float-based `gallery()`.

### Rejected alternatives

- **Reference-site card anatomy** (gradient thumbnail repeating a short label). The reference works because its titles are two words; ours are sentences like *"Hybrid multimodal retrieval for visual collections"*, so copying it means either a squashed duplicate title or inventing six short labels.
- **Metric-in-thumbnail cards.** Strong for the four case studies with a hard number, but the two without would render as a conspicuous empty coloured tile. A muted grey text line reads as *different*; an empty tile reads as *missing*.
- **Confining the restyle to `/work/`.** More CSS, not less — scoping to one page means writing overrides rather than setting values. It also contradicts decision 2, since the publications list cannot get serif titles and ochre links unless the variables move.
- **Branching inside `archive-single.html`.** That include already carries four nested collection branches. A fifth makes the least readable file worse, and an error there breaks all five collections at once.
- **Deriving tag values by parsing the `**Stack**` line from each body.** Requires regex-matching markdown bold; breaks the first time a line is reworded.

## Architecture

### Palette

All values below were measured, not estimated. Contrast is against the stated background.

| Variable | Value | Contrast | Existing? | Note |
|---|---|---|---|---|
| `$background-color`, `$body-color` | `#faf8f3` | — | yes (lines 56–57, `#fff`) | cream |
| `$text-color` | `#4c4a41` | 8.37:1 on cream | yes (line 60, `$dark-gray`) | body copy |
| `$link-color` | `#8a6508` | 5.01:1 on cream | yes (line 93, `$info-color`) | **not** `#b8860b` |
| `$border-color` | `#e4dfd2` | — | yes (line 61, `$lighter-gray`) | hairlines |
| `$muted-color` | `#6a675e` | 5.33:1 on cream | **no — add** | meta, citations |
| `$accent-color` | `#b8860b` | 3.07:1 — **fails for text** | **no — add** | decoration only |

`$muted-color` and `$accent-color` do not exist in Minimal Mistakes and must be declared as new variables. The other four already exist and are being reassigned.

`$link-color` is currently defined as `$info-color` (`#52adc8`). It must be set to the literal `#8a6508`, not by editing `$info-color`, because `$info-color` also drives notice components.

Also reassign `$masthead-link-color` (line 96), currently `$primary-color` (`#7a8288`).

`$accent-color` is restricted to the card top rule and the card result eyebrow. It must never be used for body-size text.

Card-internal values, measured against the white card face `#ffffff`:

| Element | Colour | Contrast |
|---|---|---|
| Card title | `#1a1913` | 17.61:1 |
| Card excerpt | `#4c4a41` | 8.89:1 |
| `result` eyebrow | `#8a6508` | 5.32:1 |
| `result_note` eyebrow | `#6a675e` | 5.65:1 |
| Tag chip text `#7a5b06` on chip `#f6e9c4` | — | 5.22:1 |

### Typography

`$header-font-family: $serif` (`Georgia, Times, serif` — already defined in `_variables.scss`). This flows to all `h1`–`h6` via `_sass/_base.scss:27`.

Three sites hardcode `$sans-serif-narrow` and would otherwise remain sans while everything else turned serif. Each needs a one-line change to `$serif`:

- `_sass/_masthead.scss:18` — site title
- `_sass/_sidebar.scss:34` — author name
- `_sass/_archive.scss:44` — `.archive__item-title` (this is what makes publication titles serif)

Nav links, footer and body copy stay sans-serif. The rule: serif for things that are *named*, sans for things that are *operated*.

### File structure

| File | Action | Responsibility |
|---|---|---|
| `_sass/_variables.scss` | modify | palette values, `$header-font-family` |
| `_sass/_cards.scss` | create | `.wgrid` and `.wcard` only |
| `assets/css/main.scss` | modify | add `@import "cards";` after `"archive"` |
| `_sass/_archive.scss` | modify | list restyle; `.archive__item-title` to serif |
| `_sass/_masthead.scss` | modify | line 18 to `$serif` |
| `_sass/_sidebar.scss` | modify | line 34 to `$serif` |
| `_includes/work-card.html` | create | render one case-study card |
| `_pages/work.html` | modify | one line: swap the include |
| `_pages/research.html` | modify | group publications by year |
| `_portfolio/*.md` (6 files) | modify | add `result`/`result_note` and `tags` |
| `_includes/head/custom.html` | modify | remove 14 dead asset references |
| `images/manifest.json` | delete | names the site "Minimal Mistakes"; all 6 icons missing |

`_includes/archive-single.html` is **not** modified. That protects the rendering of 45 of the 53 pages.

### Card component

`_pages/work.html` already has its own explicit loop, so the change is one line — `archive-single.html` becomes `work-card.html`.

```html
<article class="wcard">
  <p class="wcard__result">9× faster inference</p>
  <h2 class="wcard__title"><a href="…">Real-time visual SLAM on edge hardware</a></h2>
  <p class="wcard__excerpt">…</p>
  <ul class="wcard__tags"><li>TensorRT</li><li>ONNX</li><li>Jetson Orin NX</li></ul>
</article>
```

The card is white on the cream page with `border-top: 3px solid #b8860b`.

The title is an `h2`, matching `.archive__item-title` elsewhere and keeping the outline correct under the page `h1` ("Selected Work"). The `result` eyebrow precedes the title visually but is a `p`, not a heading — it must not enter the document outline.

Grid: two even columns in the ~936px the sidebar leaves at `$large` (1200px container, sidebar `span(2 of 12)`, content `span(10 of 12 last)`), collapsing to one column below `$medium`.

```scss
.wgrid {
  display: grid;
  gap: 1.5em;
  grid-template-columns: 1fr;
  @include breakpoint($medium) { grid-template-columns: 1fr 1fr; }
}
```

### Measured vs unmeasured results

Two field names carry the distinction rather than a boolean flag:

- `result:` → renders in ochre `#8a6508`
- `result_note:` → renders in muted grey `#6a675e`

A case study that later gains a hard number switches field name. There is no `result_measured` flag to keep in sync.

Liquid: `{% if post.result %}` … `{% elsif post.result_note %}` … `{% endif %}`. A card with neither field renders without an eyebrow.

### Front-matter additions

Four of six case studies have a hard number; two do not. Every value is a distillation of that file's existing `**Result**` paragraph, and every tag comes from its existing `**Stack**` line. Nothing is invented.

| File (order) | New front matter |
|---|---|
| `real-time-slam-on-edge-hardware.md` (1) | `result: "9× faster inference"`<br>`tags: [TensorRT, ONNX, Jetson Orin NX, PyTorch]` |
| `defect-detection-where-models-plateau.md` (2) | `result: "+20% F1 score"`<br>`tags: [TensorFlow, TF Model Garden, OpenCV]` |
| `agentic-systems-in-a-regulated-domain.md` (3) | `result_note: "Auditable by design"`<br>`tags: [LangChain, Agentic orchestration, LLM-as-a-judge]` |
| `hybrid-multimodal-retrieval.md` (4) | `result_note: "Shipped to production"`<br>`tags: [FAISS, ElasticSearch, Transformers]` |
| `llm-survey-analysis-at-research-scale.md` (5) | `result: "−40% analysis time"`<br>`tags: [RAG, LangChain, FAISS]` |
| `tf-cnnvis-open-source-cnn-visualisation.md` (6) | `result: "750+ stars, 200+ forks"`<br>`tags: [TensorFlow, TensorBoard, NumPy]` |

Traceability to existing prose:

- *"Roughly 9× faster inference, from 0.26 to 2.4 FPS"* → `9× faster inference`
- *"A 20% F1-score improvement"* → `+20% F1 score`
- *"A 40% reduction in researcher time per project"* → `−40% analysis time`
- *"Past 750 stars and 200 forks"* → `750+ stars, 200+ forks`
- *"An auditable generation pipeline…"* → `Auditable by design`
- *"Shipped to production and serving live queries"* → `Shipped to production`

All values are quoted in YAML. Note that `−40%` uses U+2212 MINUS SIGN, not a hyphen.

### List restyle

`_sass/_archive.scss`:

- `.archive__item-title` → `$serif`, `$type-size-5`, ochre link colour
- `.archive__item-excerpt` → `0.9em` (currently `$type-size-6` = 12px, too small once it is the main content of a row)
- Citation line → `$type-size-7` in `#6a675e`, present but recessive
- Row separators → 1px `#e4dfd2`

`_pages/research.html:28` currently renders publications with a bare `{% for post in site.publications reversed %}` and no year dividers. The approved mockup has them, so publications need Liquid grouping:

```liquid
{% assign pubs = site.publications | sort: 'date' | reverse %}
{% assign byyear = pubs | group_by_exp: "p", "p.date | date: '%Y'" %}
{% for year in byyear %}
  <h3 class="archive__year">{{ year.name }}</h3>
  {% for post in year.items %}{% include archive-single.html %}{% endfor %}
{% endfor %}
```

`group_by_exp` has shipped since Jekyll 3.4, so it is safe on 3.10. This also replaces reliance on the collection's default sort order with an explicit sort on `date`.

Talks keep their own `archive-single-talk.html` include, unmodified.

### `<head>` cleanup

`_includes/head/custom.html` references 19 local assets. **14 do not exist:**

- `apple-touch-icon-{57,60,72,76,114,120,144,152,180}x*.png` (9)
- `favicon-16x16.png`, `favicon-32x32.png`, `favicon-96x96.png`, `android-chrome-192x192.png` (4)
- `favicon.ico` (1)

The remaining **5 resolve.** Of those, `images/manifest.json` is actively wrong: it declares `"name": "Minimal Mistakes"` and lists six `android-chrome-*.png` icons, none of which are present. Delete the file and its `<link rel="manifest">`.

The other 4 are kept: `safari-pinned-tab.svg`, `mstile-144x144.png`, `browserconfig.xml`, `assets/css/academicons.css`.

No new favicon is added. There is no source artwork, and inventing a monogram would be inventing an identity.

## Forced consequences

Things that follow from the decisions and cannot be avoided within them.

1. **No partial rollout.** Because the palette lives in `_variables.scss`, the first deploy changes all 53 pages at once.
2. **`tags` duplicates the `**Stack**` line.** The card tags are a curated 3–4 item subset of prose already in each body, so two places must be updated when a stack changes. Accepted as the lesser evil against parsing markdown.
3. **Both unmeasured cards land in the same row.** With two columns, `order` 1–6 lays out as rows `[1,2] [3,4] [5,6]`. Orders 3 and 4 are the agentic and hybrid-retrieval studies — the only two without a number — so the middle row reads as entirely metric-free. Interleaving to `slam, agentic, defect, hybrid, survey, tf-cnnvis` would put one number in every row. **Decision: leave `order` unchanged.** It was a deliberate strength ranking in Phase 1 and is not being rewritten for layout reasons.

## Open item for the user

`images/safari-pinned-tab.svg` is potrace-generated vector art and `images/mstile-144x144.png` exists alongside it. It is not determinable from the repo whether these are the user's own artwork from an earlier version of the site or leftover Minimal Mistakes branding. Both are kept by default. If they are theme leftovers, they should be deleted too.

## Out of scope

- Dark theme. Explicitly excluded by the user.
- Webfonts. Georgia is a system serif; no network cost.
- Nav dropdowns (would require masthead and CSS work; deferred from Phase 2).
- Talks content, still thin — deferred from Phase 1.
- The untracked draft `_posts/2026-05-03-work-love.md`. Not to be touched.
- Adding metrics to the two case studies that lack them. That is a content question, not a design one.
- Rewriting `archive-single.html` or removing the now-unused susy `gallery()` and teaser-image code from `_archive.scss`.

## Success criteria

1. `/work/` renders six cards in two columns at desktop width, one column below `$medium`.
2. Each card shows a title, excerpt and tag chips; four show an ochre `result` and two a muted `result_note`.
3. Card order remains 1–6 as set in Phase 1.
4. Every page has the cream background, serif headings and ochre links, including masthead title and sidebar name.
5. Publication titles render serif; publications are grouped under year headings; author lists and citations are retained.
6. No link on any page measures below 4.5:1 contrast.
7. `_includes/head/custom.html` emits zero references to missing files.
8. No new image assets are added to the repository.
9. Existing URLs and redirects from Phase 2 continue to resolve; the 26 entries on `/research/` and 3 posts on `/blog/` are unchanged in count.
10. The build completes with no Liquid errors.
