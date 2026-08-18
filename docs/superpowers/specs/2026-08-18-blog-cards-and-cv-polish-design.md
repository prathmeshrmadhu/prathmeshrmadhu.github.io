# Blog Cards and CV Polish (Phase 3.1)

**Date:** 2026-08-18
**Status:** Awaiting user review
**Phase:** 3.1 — a follow-on to Phase 3, not a new phase of the original three

## Goal

Extend the Phase 3 card layout from `/work/` to `/blog/`, and give `/cv/` a visual pass that makes a fifteen-year career scannable instead of flat.

## Why

Phase 3 shipped cards on `/work/` and a warm ochre-on-cream palette site-wide. Two pages were left behind by it.

`/blog/` is still the stock Academic Pages year-grouped list. It now looks like a different site from `/work/`.

`/cv/` is worse than untouched — it was actively harmed by Phase 3. The page uses setext `======` underlines for its section headings, which is markdown H1 syntax, so the page carries **six `<h1>` elements**: `CV`, `Education`, `Experience`, `Skills`, `Publications`, `Talks`, `Teaching`. When Phase 3 made all headings serif and heavier, those six became six full-weight page titles stacked down one page. Publication titles then render as `h3`, skipping `h2` entirely.

A third problem surfaced during design and is not cosmetic. Measured from the live page, `/cv/` is 12,282 characters of content, of which **Publications is 6,104 — exactly half**. Every one of those 21 entries already appears on `/research/`. No styling improves a page that is 50% duplicate of another page.

## Decisions

Each was chosen by the user during brainstorming, from wireframes and mockups built with the site's real content.

1. **Blog gets the same cards as Work**, reusing the existing grid and card CSS rather than a blog-specific variant.
2. **Two columns, no year headings** (option A of three). Once every card carries its own date, a year heading above it repeats information. Three posts leave a half-empty final row, which is what any grid does with an odd count.
3. **The date fills the eyebrow slot** that `result:` occupies on work cards.
4. **Real excerpts are written into post front matter** (option A of three). Jekyll's auto-excerpt takes the first paragraph, and the Banerjee post's first paragraph is literally `TL; DR` — six characters. Acceptable in a list row, a visible hole in a card.
5. **CV direction 2 of three** — typographic tune-up plus dated eyebrows and skill chips. Direction 3 (a timeline rail) was rejected because it makes Experience, the most frequently edited section, the hardest to edit, and a rail does not earn that.
6. **CV publications condense to a count, the five most recent, and a link** to `/research/` (option C of three). The five are selected automatically by date, so there is no list for the user to curate or let go stale.
7. **Talks and teaching stay complete.** They are 425 and 552 characters — 7% of the page combined. Condensing them buys nothing and costs completeness.
8. **The shared card classes are renamed** from `.wgrid`/`.wcard` to `.cardgrid`/`.card`. See the rename section; this is the one decision the assistant made on the user's behalf.

### Rejected alternatives

- **Dropping excerpts from blog cards entirely** (date + title + tags). No content work and no hole, but a blog card with no prose gives a reader less reason to click than a work card does.
- **Fixing only the Banerjee excerpt.** Minimum effort, but excerpt lengths stay uneven, so card heights vary for no reason.
- **One wide column for the blog.** Never an empty slot and more room for long titles, but it stops resembling `/work/`, which was the entire request.
- **Two columns with year headings kept.** Consistent with `/research/`, but 2026 holds one post, so it renders a heading over a single card beside a wide gap.
- **Leaving the CV's publications intact.** Defensible — a CV is expected to be complete in one place — but it leaves half the page duplicating `/research/`.
- **Replacing publications with only a link.** A PhD's CV showing no publications reads as odd, and an industry reader skimming `/cv/` would never learn there are 21.
- **Hand-picking five "selected" publications.** Better editorial control, but creates a list that must be maintained and will go stale.
- **Writing the CV's Skills and Experience sections as raw HTML.** This was the assumption presented to the user in the mockups, and it turned out to be unnecessary — see the kramdown finding below.
- **A timeline rail on Experience and Education.** Visually strongest option, rejected on edit cost.

## Key technical finding: the CV stays markdown

The mockups were presented on the assumption that skill chips require hand-written HTML, because CSS cannot split the string `Python, C` into two pills. That assumption was wrong.

This repo runs kramdown with GFM input (`_config.yml:157` and `:166`). Kramdown supports inline attribute lists, verified against this exact configuration:

```
* a
* b
{: .bar}
```
produces
```html
<ul class="bar"><li>a</li><li>b</li></ul>
```

So every CV change is achieved by attaching a class with `{: .class}` and styling it. `cv.md` contains no HTML beyond the one `<ul>` wrapper the publications loop already has, and stays exactly as editable as it is today.

## Architecture

### The rename

The card component is now shared by two pages, but its classes are named for one of them — `w` for work. Using `.wcard` on the blog makes the name inaccurate. Nothing in the theme's `_sass/` uses `.card`, so there is no collision.

| old | new |
|---|---|
| `.wgrid` | `.cardgrid` |
| `.wcard` | `.card` |
| `.wcard__result` | `.card__eyebrow` |
| `.wcard__result--note` | `.card__eyebrow--note` |
| `.wcard__title` | `.card__title` |
| `.wcard__excerpt` | `.card__excerpt` |
| `.wcard__tags` | `.card__tags` |

`result` becomes `eyebrow` because the slot holds a metric on Work and a date on Blog; naming it for one of its two uses would be the same mistake at a smaller scale.

The rename touches three files: `_sass/_cards.scss`, `_includes/work-card.html`, `_pages/work.html`. The front-matter field names `result:` and `result_note:` in `_portfolio/*.md` are **not** renamed — they describe the content, and the content genuinely is a result.

The Phase 3 spec and plan under `docs/superpowers/` keep the old class names. They are a record of what was decided on 2026-08-13 and are not rewritten.

**This is the one decision made without an explicit user answer.** The user approved the design as a whole after it was recommended. It is mechanical and revertible; it is the natural thing to veto at spec review.

### Shared colour values

Three literals are currently hardcoded in `_sass/_cards.scss` and would be duplicated into `_sass/_cv.scss`. They move to `_sass/_variables.scss` alongside the Phase 3 additions:

```scss
$title-color                 : #1a1913;  /* card and CV entry titles */
$chip-background             : #f6e9c4;
$chip-color                  : #7a5b06;  /* 5.22:1 on #f6e9c4 */
```

Both partials then reference the variables. No new colours are introduced — these are the exact values Phase 3 already shipped and audited.

### `/blog/`

New include `_includes/blog-card.html`, parallel to `work-card.html`:

```liquid
{% include base_path %}

<article class="card">
  <p class="card__eyebrow">{{ post.date | date: "%-d %B %Y" }}</p>

  <h2 class="card__title">
    <a href="{{ base_path }}{{ post.url }}" rel="permalink">{{ post.title }}</a>
  </h2>

  {% if post.excerpt %}
    <p class="card__excerpt">{{ post.excerpt | markdownify | strip_html | strip_newlines }}</p>
  {% endif %}

  {% if post.tags and post.tags.size > 0 %}
    <ul class="card__tags">
      {% for tag in post.tags %}<li>{{ tag }}</li>{% endfor %}
    </ul>
  {% endif %}
</article>
```

A separate include rather than a branch inside `work-card.html`: same reasoning Phase 3 used to avoid touching `archive-single.html`. Each include stays readable and an error in one cannot break the other page.

`markdownify | strip_html | strip_newlines` is carried over unchanged. `markdownify` wraps output in `<p>`, and nesting that inside `<p class="card__excerpt">` is invalid HTML.

`_pages/blog.html` body becomes:

```liquid
{% include base_path %}

<div class="cardgrid">
{% for post in site.posts %}
  {% include blog-card.html %}
{% endfor %}
</div>
```

`site.posts` is already date-descending, so no `sort` is needed. Front matter is unchanged, including both `redirect_from` entries.

### Post excerpts

Added as an `excerpt:` line to each post's front matter. Approved verbatim by the user:

| post | excerpt |
|---|---|
| `2026-03-31-information-overload.md` | We keep blaming the sheer volume of information. I think the damage is done by the velocity — and the fix isn't reading less, it's putting the friction back. |
| `2020-09-30-why-fastai.md` | Notes from my first pass through fastai — why the top-down, build-something-first approach works for beginners, and the data ethics questions the course refuses to let you skip. |
| `2020-07-12-rip-banerjee-sir.md` | Prof. Asim Banerjee was the first person I spoke to at DAIICT, on day one. A long and unhurried remembrance of six years of his scoldings, his arguments, and his ideas about what a university is for. |

The fastai excerpt says "notes" deliberately. That post is a bullet outline from the fastai course, not a finished essay, and a card gives it the same visual weight as the other two. Describing it accurately is the honest correction.

Written with double-quoted YAML values, since all three contain apostrophes.

### `/cv/`

**Section headings.** All six `======` setext underlines become `##`. The page keeps exactly one `<h1>`, the title supplied by the layout.

**Entry pattern**, applied to Experience and Education:

```markdown
Aug 2026 – Present
{: .cv-date}

Senior Vice President – Machine Learning
{: .cv-role}

Infocusp Innovations, Pune
{: .cv-org}

* Promoted to lead the machine learning practice, with accountability for
  technical direction and delivery quality across the portfolio.
```

The dates leave the bold run-on line and become the eyebrow. Body bullets are unchanged text.

Applying this to **Education** as well as Experience extends slightly past the mockups, which showed Experience and Skills only. Degrees are entries of the same shape as jobs, so treating them differently would be arbitrary — but it is an extension, and worth confirming.

**Skills**, one category per group:

```markdown
Programming languages
{: .cv-cat}

* Python
* C
{: .cv-chips}
```

The six existing categories and their contents are unchanged. Only the comma-separated strings split into one list item per skill.

**Publications:**

```liquid
{% assign pub_count = site.publications | size %}
{% assign recent_pubs = site.publications | sort: 'date' | reverse %}

{{ pub_count }} peer-reviewed publications. The five most recent are below; the
[full list is on the research page]({{ base_path }}/research/).
{: .cv-note}

<ul>{% for post in recent_pubs limit: 5 %}
  {% include archive-single-cv.html %}
{% endfor %}</ul>
```

The count is derived, never typed, so it cannot drift from the collection.

This also fixes a latent bug. The current code is `{% for post in site.publications reversed %}`, which reverses **collection order**, not date order. `/research/` was corrected to `sort: 'date' | reverse` in Phase 3; this brings `/cv/` in line.

**Talks and teaching** loops are untouched.

**New partial `_sass/_cv.scss`**, imported in `assets/css/main.scss` immediately after `cards`:

```scss
/* ==========================================================================
   CV  —  /cv/ only
   ========================================================================== */

.cv-date {
  margin: 1.6em 0 0.15em;
  font-size: $type-size-7;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: $link-color;
}

.cv-role {
  margin: 0 0 0.1em;
  font-family: $serif;
  font-size: $type-size-5;
  font-weight: 700;
  color: $title-color;
}

.cv-org {
  margin: 0 0 0.5em;
  font-size: $type-size-6;
  color: $muted-color;
}

.cv-cat {
  margin: 1.1em 0 0.35em;
  font-size: $type-size-7;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: $muted-color;
}

.cv-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 0.35em;
  margin: 0 0 0.4em;
  padding: 0;
  list-style: none;

  li {
    margin: 0;
    padding: 0.15em 0.6em;
    font-size: $type-size-7;
    border-radius: 20px;
    background: $chip-background;
    color: $chip-color;
  }
}

.cv-note {
  margin: 0 0 1em;
  color: $muted-color;
}
```

`.cv-chips li` sets `margin: 0` explicitly because Minimal Mistakes styles `.page__content li`, and that inherited margin would otherwise break the flex row.

## Files touched

| file | action | responsibility |
|---|---|---|
| `_sass/_variables.scss` | modify | add `$title-color`, `$chip-background`, `$chip-color` |
| `_sass/_cards.scss` | modify | rename classes; consume the three new variables |
| `_sass/_cv.scss` | **create** | CV entry, category, chip and note styles only |
| `assets/css/main.scss` | modify | `@import "cv";` after `cards` |
| `_includes/work-card.html` | modify | rename classes only; no structural change |
| `_pages/work.html` | modify | `.wgrid` → `.cardgrid` only |
| `_includes/blog-card.html` | **create** | blog card markup |
| `_pages/blog.html` | modify | replace year-grouped list with card grid |
| `_posts/2026-03-31-information-overload.md` | modify | add `excerpt:` |
| `_posts/2020-09-30-why-fastai.md` | modify | add `excerpt:` |
| `_posts/2020-07-12-rip-banerjee-sir.md` | modify | add `excerpt:` |
| `_pages/cv.md` | modify | headings, entry pattern, chips, publications condensation |

`_includes/archive-single.html`, `_includes/archive-single-cv.html`, `_includes/archive-single-talk-cv.html`, `_pages/research.html` and `_pages/work.html`'s front matter are **not** modified.

## Success criteria

1. Clean build (`jclean` then `jbuild`) with no Liquid errors or warnings.
2. `/blog/` contains one `.cardgrid` and three `.card` articles in the published build, each with an eyebrow date, a title link to the post permalink, a non-empty excerpt, and its tag chips.
3. Zero occurrences of `wcard` or `wgrid` in `_sass/`, `_includes/`, `_pages/`, or the built `_site/`.
4. `/work/` still renders six cards, and its built HTML is byte-identical to the pre-rename output except for the renamed class attributes.
5. `/cv/` contains exactly one `<h1>` and six `<h2>`s. No heading level is skipped.
6. `/cv/` publications section shows a derived count of 21, exactly five entries, and a working link to `/research/`. The five are the five most recent by date.
7. `/cv/` skills render as chips, one per skill, across all six categories, with every skill from the current text preserved.
8. `/research/` is unchanged: 21 publications, 7 year groups, zero cards.
9. Zero broken internal links, checked both root-relative and absolute, as in Phase 3.
10. Contrast unchanged — no new colour values are introduced, so the Phase 3 audit still holds.

## Out of scope

- **The publication-title underline on `/research/`** — ochre, bold and underlined, flagged at the end of Phase 3 and still undecided. The underline is pre-existing theme CSS in `_sass/_archive.scss`.
- **`archive-single-cv.html` emits `<li>` nested inside `<div>` and `<article>`**, so the `<ul>` wrapper contains non-`li` children. Invalid HTML, pre-existing, affects all three CV collection sections. Fixing it means editing a shared include, which this phase avoids for the same reason Phase 3 did.
- **`_posts/2026-05-03-work-love.md`** — untracked draft with an empty title. Not touched. It has a side effect worth knowing: local builds will render a fourth, blank blog card. It cannot appear on the published site because it is not committed.
- **`.claude/launch.json`**, `browserconfig.xml`, and the provenance of `safari-pinned-tab.svg` / `mstile-144x144.png` — carried over from Phase 3, still unresolved.
- **Talks and teaching content**, and reconciling publications against Google Scholar.
