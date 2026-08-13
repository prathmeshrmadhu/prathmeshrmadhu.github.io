# Visual Design — Cards and Palette Implementation Plan (Phase 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply a warm ochre-on-cream palette with serif headings site-wide, and replace the flat list on `/work/` with a two-column CSS Grid of cards.

**Architecture:** The palette lives in `_sass/_variables.scss`, so all 53 pages inherit it from six variable assignments plus three targeted selector overrides. Cards are a new `_includes/work-card.html` plus a new `_sass/_cards.scss`; the shared `_includes/archive-single.html` is never modified, which protects the other 45 pages. Six `_portfolio/*.md` files gain two front-matter fields distilled from prose already in their bodies.

**Tech Stack:** Jekyll 3.10 (via the `github-pages` gem), Sass with susy 2 float grids and breakpoint mixins, Liquid, CSS Grid. Ruby runs in Docker — there is no local Ruby.

**Spec:** `docs/superpowers/specs/2026-08-13-visual-design-cards-and-palette-design.md`

---

## Before You Start: Build Harness

There is **no Ruby on this machine** and **no test framework**. Verification means: build the site with Docker, then assert against the generated HTML and CSS in `_site/` with Python. Define these two shell functions once per shell session — they do not persist between sessions:

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
```

A build takes about 4 seconds after the first run (the first populates the `jekyll_gems` volume and takes a few minutes).

**`jclean` is mandatory before any check that something is *gone*.** Jekyll does not remove stale output, and `_site` is created root-owned by the container, so a host-side `rm -rf _site` fails with a permission error — that is why `jclean` runs inside the container.

**Two traps that produced false results in earlier phases — do not repeat them:**

1. **Never use `grep -c` to count repeated markup.** `grep -c` counts matching *lines*, not matches, and Jekyll emits whole lists on one line. Use Python's `str.count`.
2. **GitHub Pages serves extensionless URLs.** A collection entry builds to `_site/work/foo.html`, and the live URL is `/work/foo`. Any path check must try `path`, `path/index.html`, *and* `path + '.html'`.

Run every command from the repo root, `/home/prathmesh/personal/prathmeshrmadhu.github.io`. Do not use `cd` in a command you expect to be followed by others — the working directory persists between tool calls.

Work directly on `master` and commit after each task. That is this project's established practice.

---

## File Structure

| File | Action | Single responsibility |
|---|---|---|
| `_sass/_variables.scss` | modify | Palette values and `$header-font-family`. No selectors. |
| `_sass/_cards.scss` | **create** | `.wgrid` and `.wcard` only. Nothing else may live here. |
| `assets/css/main.scss` | modify | One `@import "cards";` line after `"archive"`. |
| `_sass/_masthead.scss` | modify | Serif site title (one declaration). |
| `_sass/_sidebar.scss` | modify | Serif author name (one declaration). |
| `_sass/_archive.scss` | modify | List-item type, colour and separators. |
| `_includes/work-card.html` | **create** | Render exactly one case-study card. |
| `_pages/work.html` | modify | One line: which include the loop calls. |
| `_pages/research.html` | modify | Group publications by year. |
| `_portfolio/*.md` (6) | modify | Front matter only; bodies untouched. |
| `_includes/head/custom.html` | modify | Remove 14 dead asset references. |
| `images/manifest.json` | **delete** | — |

Task order is deliberate: palette first (Task 1–2) so that every later visual check happens against the final colours; cards next (Task 3–5); lists after (Task 6); cleanup last (Task 7).

---

## Task 1: Palette variables

**Files:**
- Modify: `_sass/_variables.scss:56-61`, `_sass/_variables.scss:93`, `_sass/_variables.scss:96`

Six existing variables are reassigned and two new ones are declared. `$muted-color` and `$accent-color` **do not exist** in Minimal Mistakes.

Critical: `$link-color` is currently `$info-color`. Assign the literal `#8a6508` instead of editing `$info-color`, because `$info-color` also drives the notice components.

- [ ] **Step 1: Record the current values so the change is verifiable**

```bash
sed -n '56,61p;93,97p' _sass/_variables.scss
```

Expected output includes `$body-color : #fff;`, `$background-color : #fff;`, `$text-color : $dark-gray;`, `$border-color : $lighter-gray;`, `$link-color : $info-color;`, `$masthead-link-color : $primary-color;`.

- [ ] **Step 2: Replace lines 56–61**

Find this block:

```scss
$body-color                 : #fff;
$background-color           : #fff;
$code-background-color      : #fafafa;
$code-background-color-dark : $light-gray;
$text-color                 : $dark-gray;
$border-color               : $lighter-gray;
```

Replace with:

```scss
$body-color                 : #faf8f3;
$background-color           : #faf8f3;
$code-background-color      : #f4f1e8;
$code-background-color-dark : $light-gray;
$text-color                 : #4c4a41;
$border-color               : #e4dfd2;

/* Phase 3 palette additions — these do not exist in Minimal Mistakes */
$muted-color                : #6a675e;  /* 5.33:1 on #faf8f3 */
$accent-color               : #b8860b;  /* 3.07:1 — DECORATION ONLY, never text */
```

`$code-background-color` moves from `#fafafa` to `#f4f1e8` because a near-white code block on a cream page reads as a rendering error.

- [ ] **Step 3: Replace the link colours at lines 93–97**

Find:

```scss
$link-color                 : $info-color;
$link-color-hover           : mix(#000, $link-color, 25%);
$link-color-visited         : mix(#fff, $link-color, 25%);
$masthead-link-color        : $primary-color;
$masthead-link-color-hover  : mix(#000, $primary-color, 25%);
```

Replace with:

```scss
$link-color                 : #8a6508;
$link-color-hover           : mix(#000, $link-color, 25%);
$link-color-visited         : mix(#fff, $link-color, 20%);
$masthead-link-color        : #4c4a41;
$masthead-link-color-hover  : #8a6508;
```

`$link-color-visited` changes from a 25% white mix to 20% because at 25% the visited ochre drops to 4.1:1 and fails AA.

- [ ] **Step 4: Set the heading font at line 33**

Find `$header-font-family         : $sans-serif;` and replace with:

```scss
$header-font-family         : $serif;
```

`$serif` is already defined on line 16 as `Georgia, Times, serif`. Do not add a webfont.

- [ ] **Step 5: Build and verify the compiled CSS**

```bash
jbuild
python3 - <<'EOF'
css = open('_site/assets/css/main.css').read()
checks = {
    'cream body background': 'background-color: #faf8f3' in css or '#faf8f3' in css,
    'ochre link colour':     '#8a6508' in css,
    'no blue link left':     '#52adc8' not in css.split('.notice')[0],
    'Georgia headings':      'Georgia' in css,
}
for k, v in checks.items():
    print(('PASS ' if v else 'FAIL '), k)
assert all(checks.values()), 'palette did not compile as expected'
print('Task 1 OK')
EOF
```

Expected: four `PASS` lines then `Task 1 OK`.

- [ ] **Step 6: Verify every text colour pair passes WCAG AA**

```bash
python3 - <<'EOF'
def lum(h):
    h = h.lstrip('#'); c = [int(h[i:i+2],16)/255 for i in (0,2,4)]
    c = [(v/12.92 if v <= 0.04045 else ((v+0.055)/1.055)**2.4) for v in c]
    return 0.2126*c[0] + 0.7152*c[1] + 0.0722*c[2]
def cr(a,b):
    la, lb = lum(a), lum(b); hi, lo = max(la,lb), min(la,lb)
    return (hi+0.05)/(lo+0.05)
pairs = [('#4c4a41','#faf8f3','body text'),
         ('#8a6508','#faf8f3','link'),
         ('#6a675e','#faf8f3','muted'),
         ('#4c4a41','#faf8f3','masthead link')]
bad = [(l, round(cr(a,b),2)) for a,b,l in pairs if cr(a,b) < 4.5]
for a,b,l in pairs: print(f'{cr(a,b):5.2f}:1  {l}')
assert not bad, f'below AA: {bad}'
print('all text pairs pass AA')
EOF
```

Expected: four ratios, all >= 4.5, then `all text pairs pass AA`.

- [ ] **Step 7: Commit**

```bash
git add _sass/_variables.scss
git commit -m "Set warm ochre-on-cream palette and serif headings

Replaces the theme's grey/blue defaults. Fixes the existing link
contrast failure: #52adc8 on white measured 2.57:1 against a 4.5:1
requirement."
```

---

## Task 2: Serif overrides for masthead, sidebar and archive titles

**Files:**
- Modify: `_sass/_masthead.scss:44-52`
- Modify: `_sass/_sidebar.scss:119-122`
- Modify: `_sass/_archive.scss:42-44`

Task 1 set `$header-font-family` for `h1`–`h6`, but three selectors hardcode a sans variable and win on specificity.

- [ ] **Step 1: Add serif to the masthead site title**

In `_sass/_masthead.scss`, find:

```scss
.masthead__menu-item {
  display: block;
  list-style-type: none;
  white-space: nowrap;

  &--lg {
    padding-right: 2em;
    font-weight: 700;
  }
}
```

Replace with:

```scss
.masthead__menu-item {
  display: block;
  list-style-type: none;
  white-space: nowrap;

  &--lg {
    padding-right: 2em;
    font-family: $serif;
    font-weight: 700;
  }
}
```

`&--lg` is the `li` carrying `{{ site.title }}` — see `_includes/masthead.html:10`. **Do not** put this on `.masthead__inner-wrap` (line 18): that wrap encloses the nav `<ul>`, so the nav links would go serif too, which the spec forbids.

- [ ] **Step 2: Add serif to the sidebar author name**

In `_sass/_sidebar.scss`, find:

```scss
.sidebar .author__name {
  font-family: $sans-serif;
  font-size: $type-size-5;
}
```

Replace with:

```scss
.sidebar .author__name {
  font-family: $serif;
  font-size: $type-size-5;
}
```

Use this selector (specificity 0,2,0), not the blanket `.sidebar h2, h3, …` rule at line 32 (0,1,1) — this rule already overrides that one.

- [ ] **Step 3: Add serif to archive item titles**

In `_sass/_archive.scss`, find:

```scss
.archive__item-title {
  margin-bottom: 0.25em;
  font-family: $sans-serif-narrow;
```

Replace with:

```scss
.archive__item-title {
  margin-bottom: 0.25em;
  font-family: $serif;
```

This is what makes publication titles serif on `/research/`.

- [ ] **Step 4: Build and verify all three selectors carry Georgia**

```bash
jbuild
python3 - <<'EOF'
import re
css = open('_site/assets/css/main.css').read()
def font_of(sel):
    # find the rule block for sel and return its font-family, if any
    for m in re.finditer(re.escape(sel) + r'\s*\{([^}]*)\}', css):
        fm = re.search(r'font-family:\s*([^;]+)', m.group(1))
        if fm: return fm.group(1).strip()
    return None
targets = ['.masthead__menu-item--lg', '.sidebar .author__name', '.archive__item-title']
ok = True
for t in targets:
    f = font_of(t)
    good = f is not None and 'Georgia' in f
    ok &= good
    print(('PASS ' if good else 'FAIL '), t, '->', f)
# nav links must NOT be serif
wrap = font_of('.masthead__inner-wrap')
nav_ok = wrap is None or 'Georgia' not in wrap
print(('PASS ' if nav_ok else 'FAIL '), '.masthead__inner-wrap stays sans ->', wrap)
assert ok and nav_ok
print('Task 2 OK')
EOF
```

Expected: three `PASS` lines for the serif targets, one `PASS` confirming the nav wrap is still sans, then `Task 2 OK`.

- [ ] **Step 5: Commit**

```bash
git add _sass/_masthead.scss _sass/_sidebar.scss _sass/_archive.scss
git commit -m "Make site title, author name and archive titles serif

These three selectors hardcode a sans variable and outrank
\$header-font-family. Targets the title li rather than the masthead
inner wrap so nav links stay sans-serif."
```

---

## Task 3: Front matter for the six case studies

**Files:**
- Modify: `_portfolio/real-time-slam-on-edge-hardware.md`
- Modify: `_portfolio/defect-detection-where-models-plateau.md`
- Modify: `_portfolio/agentic-systems-in-a-regulated-domain.md`
- Modify: `_portfolio/hybrid-multimodal-retrieval.md`
- Modify: `_portfolio/llm-survey-analysis-at-research-scale.md`
- Modify: `_portfolio/tf-cnnvis-open-source-cnn-visualisation.md`

Two new fields. `result:` renders ochre (a measured number); `result_note:` renders muted grey (qualitative). A file has exactly one of the two, never both. Every value is a distillation of that file's own `**Result**` paragraph; every tag comes from its own `**Stack**` line. **Invent nothing.**

Bodies are not touched in this task. Only front matter, inserted after `order:`.

- [ ] **Step 1: Add `result` and `tags` to each of the six files**

`_portfolio/real-time-slam-on-edge-hardware.md` — after `order: 1`, add:

```yaml
result: "9× faster inference"
tags: [TensorRT, ONNX, Jetson Orin NX, PyTorch]
```

`_portfolio/defect-detection-where-models-plateau.md` — after `order: 2`, add:

```yaml
result: "+20% F1 score"
tags: [TensorFlow, TF Model Garden, OpenCV]
```

`_portfolio/agentic-systems-in-a-regulated-domain.md` — after `order: 3`, add:

```yaml
result_note: "Auditable by design"
tags: [LangChain, Agentic orchestration, LLM-as-a-judge]
```

`_portfolio/hybrid-multimodal-retrieval.md` — after `order: 4`, add:

```yaml
result_note: "Shipped to production"
tags: [FAISS, ElasticSearch, Transformers]
```

`_portfolio/llm-survey-analysis-at-research-scale.md` — after `order: 5`, add:

```yaml
result: "−40% analysis time"
tags: [RAG, LangChain, FAISS]
```

`_portfolio/tf-cnnvis-open-source-cnn-visualisation.md` — after `order: 6`, add:

```yaml
result: "750+ stars, 200+ forks"
tags: [TensorFlow, TensorBoard, NumPy]
```

The `−` in `−40%` is U+2212 MINUS SIGN, not a hyphen. All values are quoted, so YAML will not misparse the leading `+` or `−`.

- [ ] **Step 2: Verify the YAML parses and the fields are mutually exclusive**

```bash
python3 - <<'EOF'
import glob, re
expect = {
 'real-time-slam-on-edge-hardware':        ('result', '9× faster inference', 4),
 'defect-detection-where-models-plateau':  ('result', '+20% F1 score', 3),
 'agentic-systems-in-a-regulated-domain':  ('result_note', 'Auditable by design', 3),
 'hybrid-multimodal-retrieval':            ('result_note', 'Shipped to production', 3),
 'llm-survey-analysis-at-research-scale':  ('result', '\u221240% analysis time', 3),
 'tf-cnnvis-open-source-cnn-visualisation':('result', '750+ stars, 200+ forks', 3),
}
fails = []
for path in sorted(glob.glob('_portfolio/*.md')):
    stem = path.split('/')[-1][:-3]
    fm = open(path).read().split('---')[1]
    field, value, ntags = expect[stem]
    has_r  = re.search(r'^result:\s*"(.*)"', fm, re.M)
    has_rn = re.search(r'^result_note:\s*"(.*)"', fm, re.M)
    tags   = re.search(r'^tags:\s*\[(.*)\]', fm, re.M)
    if bool(has_r) and bool(has_rn): fails.append(f'{stem}: has BOTH result and result_note')
    got = (has_r or has_rn)
    if not got: fails.append(f'{stem}: has neither result nor result_note')
    elif got.group(1) != value: fails.append(f'{stem}: value {got.group(1)!r} != {value!r}')
    if not tags: fails.append(f'{stem}: no tags')
    elif len([t for t in tags.group(1).split(',') if t.strip()]) != ntags:
        fails.append(f'{stem}: expected {ntags} tags, got {tags.group(1)}')
    print(f'{stem}: {field}={got.group(1) if got else None!r}, tags={tags.group(1) if tags else None}')
assert not fails, fails
counts = {'result':0, 'result_note':0}
for f,_,_ in expect.values(): counts[f] += 1
assert counts == {'result':4, 'result_note':2}, counts
print('Task 3 OK — 4 result, 2 result_note')
EOF
```

Expected: six description lines then `Task 3 OK — 4 result, 2 result_note`.

- [ ] **Step 3: Confirm the build still succeeds and `order` is unchanged**

```bash
jbuild
python3 - <<'EOF'
import re
html = open('_site/work/index.html').read()
titles = re.findall(r'archive__item-title[^>]*>\s*<a href="([^"]+)"', html)
print(len(titles), 'entries')
assert len(titles) == 6, f'expected 6 case studies, got {len(titles)}'
assert 'real-time-slam' in titles[0], f'order changed: first is {titles[0]}'
print('Task 3 build OK')
EOF
```

Expected: `6 entries` then `Task 3 build OK`. The page still uses the old list markup at this point — cards arrive in Task 5.

- [ ] **Step 4: Commit**

```bash
git add _portfolio/
git commit -m "Add result and tags front matter to the six case studies

Values are distilled from each file's existing Result paragraph and
Stack line. result: carries a measured number (4 files);
result_note: is qualitative (2 files)."
```

---

## Task 4: Card styles

**Files:**
- Create: `_sass/_cards.scss`
- Modify: `assets/css/main.scss`

CSS Grid, not susy `gallery()`. Two columns at `$medium` and up, one below. The card is white on the cream page with an ochre top rule.

- [ ] **Step 1: Create `_sass/_cards.scss`**

```scss
/* ==========================================================================
   WORK CARDS  —  /work/ only
   ========================================================================== */

.wgrid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1.5em;
  margin-bottom: 2em;

  @include breakpoint($medium) {
    grid-template-columns: 1fr 1fr;
  }
}

.wcard {
  display: flex;
  flex-direction: column;
  background: #fff;
  border: 1px solid $border-color;
  border-top: 3px solid $accent-color;
  border-radius: $border-radius;
  padding: 1.1em 1.2em 1.3em;

  &__result {
    margin: 0 0 0.4em;
    font-size: $type-size-7;
    font-weight: 700;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    color: $link-color;

    &--note {
      color: $muted-color;
    }
  }

  &__title {
    margin: 0 0 0.45em;
    font-family: $serif;
    font-size: $type-size-4;
    line-height: 1.25;
    border-bottom: 0;

    a {
      color: #1a1913;
      text-decoration: none;
    }

    a:hover {
      color: $link-color;
      text-decoration: underline;
    }
  }

  &__excerpt {
    margin: 0;
    font-size: 0.9em;
    line-height: 1.5;
    color: $text-color;
  }

  &__tags {
    display: flex;
    flex-wrap: wrap;
    gap: 0.35em;
    margin: 0.9em 0 0;
    padding: 0;
    list-style: none;

    li {
      margin: 0;
      padding: 0.15em 0.6em;
      font-size: $type-size-7;
      border-radius: 20px;
      background: #f6e9c4;
      color: #7a5b06;
    }
  }
}
```

Notes for whoever reads this later: `$accent-color` (`#b8860b`) appears only as a border here — it measures 3.07:1 and must never be used for text. `border-bottom: 0` on `&__title` is needed because `_sass/_page.scss` gives headings inside `.page__content` a bottom rule. `margin-top` is not set on `&__tags` alone because the flex column keeps the excerpt and tags spaced by `gap` on the parent only if declared — it is not, so the explicit `0.9em` top margin is load-bearing.

- [ ] **Step 2: Import the partial**

In `assets/css/main.scss`, find:

```scss
@import "page";
@import "archive";
@import "sidebar";
```

Replace with:

```scss
@import "page";
@import "archive";
@import "cards";
@import "sidebar";
```

Order matters: after `archive` so card rules win any shared selector, before `sidebar` to keep the theme's grouping intact.

- [ ] **Step 3: Build and verify the card CSS compiled**

```bash
jbuild
python3 - <<'EOF'
css = open('_site/assets/css/main.css').read()
checks = {
    '.wgrid exists':          '.wgrid' in css,
    'grid-template-columns':  'grid-template-columns' in css,
    '.wcard exists':          '.wcard' in css,
    'ochre top border':       '#b8860b' in css,
    'tag chip background':    '#f6e9c4' in css,
    'result eyebrow colour':  '#8a6508' in css,
}
for k, v in checks.items(): print(('PASS ' if v else 'FAIL '), k)
assert all(checks.values())
print('Task 4 OK')
EOF
```

Expected: six `PASS` lines then `Task 4 OK`.

- [ ] **Step 4: Commit**

```bash
git add _sass/_cards.scss assets/css/main.scss
git commit -m "Add work card styles as a CSS Grid partial

Two columns at \$medium and up, one below. Uses CSS Grid rather than
susy gallery() to avoid float clearfix and fixed column maths."
```

---

## Task 5: Card markup and the `/work/` page

**Files:**
- Create: `_includes/work-card.html`
- Modify: `_pages/work.html:13`

`_includes/archive-single.html` is **not** touched. That is the whole point of this approach — publications, talks, teaching and blog keep rendering exactly as they do now.

- [ ] **Step 1: Create `_includes/work-card.html`**

```liquid
{% include base_path %}

<article class="wcard">
  {% if post.result %}
    <p class="wcard__result">{{ post.result }}</p>
  {% elsif post.result_note %}
    <p class="wcard__result wcard__result--note">{{ post.result_note }}</p>
  {% endif %}

  <h2 class="wcard__title">
    <a href="{{ base_path }}{{ post.url }}" rel="permalink">{{ post.title }}</a>
  </h2>

  {% if post.excerpt %}
    <p class="wcard__excerpt">{{ post.excerpt | markdownify | strip_html | strip_newlines }}</p>
  {% endif %}

  {% if post.tags and post.tags.size > 0 %}
    <ul class="wcard__tags">
      {% for tag in post.tags %}<li>{{ tag }}</li>{% endfor %}
    </ul>
  {% endif %}
</article>
```

The title is an `h2`, matching `.archive__item-title` and keeping the outline correct under the page `h1` ("Selected Work"). The result eyebrow is a `p`, not a heading — it must not enter the document outline even though it appears above the title.

`| markdownify | strip_html | strip_newlines` on the excerpt is deliberate: `markdownify` wraps output in `<p>`, and nesting that inside `<p class="wcard__excerpt">` is invalid HTML. Stripping the tags avoids it.

- [ ] **Step 2: Wrap the loop in the grid and swap the include**

Replace the whole of `_pages/work.html` with:

```html
---
layout: archive
title: "Selected Work"
permalink: /work/
author_profile: true
redirect_from:
  - /portfolio/
---

{% include base_path %}

{% assign ordered_work = site.portfolio | sort: 'order' %}
<div class="wgrid">
{% for post in ordered_work %}
  {% include work-card.html %}
{% endfor %}
</div>
```

Only two things changed: the loop body now calls `work-card.html`, and the loop is wrapped in `.wgrid`. The `{% assign %}` on the line above stays — Liquid's `for` tag ignores piped filters, so the sort must happen in an `assign` first.

- [ ] **Step 3: Build and verify six cards render with correct eyebrow types**

```bash
jclean && jbuild
python3 - <<'EOF'
import re
html = open('_site/work/index.html').read()
n_cards = html.count('class="wcard"')
n_grid  = html.count('class="wgrid"')
ochre   = len(re.findall(r'class="wcard__result">', html))
muted   = len(re.findall(r'class="wcard__result wcard__result--note">', html))
tags    = html.count('class="wcard__tags"')
titles  = re.findall(r'wcard__title">\s*<a href="([^"]+)"', html)
print('grid wrappers :', n_grid)
print('cards         :', n_cards)
print('ochre result  :', ochre)
print('muted result  :', muted)
print('tag lists     :', tags)
print('first card    :', titles[0] if titles else None)
assert n_grid == 1, n_grid
assert n_cards == 6, n_cards
assert ochre == 4, ochre
assert muted == 2, muted
assert tags == 6, tags
assert 'real-time-slam' in titles[0], titles[0]
# no leftover list markup, and no nested <p> from the excerpt
assert 'archive__item-title' not in html, 'old list markup still present'
assert '<p class="wcard__excerpt"><p>' not in html, 'nested <p> in excerpt'
print('Task 5 OK')
EOF
```

Expected: the six printed values (`1`, `6`, `4`, `2`, `6`, a SLAM URL) then `Task 5 OK`.

- [ ] **Step 4: Verify the other collections are untouched**

```bash
python3 - <<'EOF'
r = open('_site/research/index.html').read()
b = open('_site/blog/index.html').read()
print('research archive items:', r.count('archive__item-title'))
print('research wcards       :', r.count('class="wcard"'))
print('blog archive items    :', b.count('archive__item-title'))
assert r.count('archive__item-title') == 26, r.count('archive__item-title')
assert r.count('class="wcard"') == 0, 'cards leaked onto /research/'
print('other collections unchanged')
EOF
```

Expected: `26`, `0`, a blog count, then `other collections unchanged`. The blog count is 3 in a clean checkout, or 4 if the untracked draft `_posts/2026-05-03-work-love.md` is present — either is fine, do not touch that file.

- [ ] **Step 5: Commit**

```bash
git add _includes/work-card.html _pages/work.html
git commit -m "Render /work/ as a card grid

Adds a dedicated work-card include rather than branching inside the
shared archive-single.html, which already carries four collection
branches and is rendered on 45 other pages."
```

---

## Task 6: List restyle and publication year grouping

**Files:**
- Modify: `_sass/_archive.scss:60-66`, `_sass/_archive.scss:88-93`
- Modify: `_pages/research.html:28-30`

- [ ] **Step 1: Enlarge the archive excerpt and quieten the meta**

In `_sass/_archive.scss`, find:

```scss
.archive__item-excerpt {
  margin-top: 0;
  font-size: $type-size-6;

  & + p {
    text-indent: 0;
  }
}
```

Replace with:

```scss
.archive__item-excerpt {
  margin-top: 0;
  font-size: 0.9em;
  line-height: 1.5;

  & + p {
    text-indent: 0;
  }
}
```

`$type-size-6` is `0.75em` (12px), too small now that the excerpt is a row's main content.

- [ ] **Step 2: Add the year heading and row separator styles**

In `_sass/_archive.scss`, find:

```scss
.list__item {
  @include breakpoint($medium) {
    padding-right: $right-sidebar-width-narrow;
  }
```

Insert this rule immediately *before* `.list__item`:

```scss
.archive__year {
  margin: 1.8em 0 0.6em;
  padding-bottom: 0.25em;
  font-family: $serif;
  font-size: $type-size-5;
  color: $muted-color;
  border-bottom: 1px solid $border-color;
}

.list__item + .list__item {
  padding-top: 1em;
  border-top: 1px solid $border-color;
}
```

`.list__item + .list__item` rather than a bottom border on every item, so there is no trailing rule under the last entry before a year heading.

- [ ] **Step 3: Quieten the citation line**

The citation is emitted by `_includes/archive-single.html` as a bare `<p>` with no class, so it cannot be targeted directly without editing that include — which this plan does not do. Instead scope it through the list item. Append to the end of `_sass/_archive.scss`:

```scss
/* Citation and venue lines inside list rows. These are unclassed <p>
   elements emitted by _includes/archive-single.html, which this phase
   deliberately does not modify, so they are reached positionally. */
.list__item .archive__item > p {
  margin: 0.2em 0 0;
  font-size: $type-size-7;
  color: $muted-color;
}
```

`.archive__item-excerpt` is also a `<p>` inside `.archive__item` and would be caught by this. Its own rule sets `font-size: 0.9em`, but both selectors have equal specificity (0,2,1 vs 0,1,1 — `.list__item .archive__item > p` is 0,2,1 and wins). Add the override explicitly right after:

```scss
.list__item .archive__item > p.archive__item-excerpt {
  font-size: 0.9em;
  color: $text-color;
}
```

- [ ] **Step 4: Group publications by year in `_pages/research.html`**

Find lines 28–30:

```liquid
{% for post in site.publications reversed %}
  {% include archive-single.html %}
{% endfor %}
```

Replace with:

```liquid
{% assign pubs = site.publications | sort: 'date' | reverse %}
{% assign pubs_by_year = pubs | group_by_exp: "p", "p.date | date: '%Y'" %}
{% for year in pubs_by_year %}
  <h3 class="archive__year">{{ year.name }}</h3>
  {% for post in year.items %}
    {% include archive-single.html %}
  {% endfor %}
{% endfor %}
```

`group_by_exp` has shipped since Jekyll 3.4, so it is available on 3.10. This also replaces reliance on the collection's default sort order with an explicit sort on `date`.

Do **not** change the talks or teaching loops — talks use their own `archive-single-talk.html` include.

- [ ] **Step 5: Build and verify grouping preserves every publication**

```bash
jclean && jbuild
python3 - <<'EOF'
import re
html = open('_site/research/index.html').read()
items = html.count('archive__item-title')
years = re.findall(r'archive__year">(\d{4})</h3>', html)
print('total archive items:', items)
print('year headings      :', years)
assert items == 26, f'expected 26 entries (21 pubs + 3 talks + 2 teaching), got {items}'
assert len(years) >= 3, years
assert years == sorted(years, reverse=True), f'years not descending: {years}'
assert len(years) == len(set(years)), f'duplicate year heading: {years}'
# author lists and citations must survive
assert 'Recommended citation' in html, 'citations lost'
assert 'P Madhu' in html, 'author lists lost'
print('Task 6 OK')
EOF
```

Expected: `26`, a descending list of distinct years, then `Task 6 OK`.

- [ ] **Step 6: Commit**

```bash
git add _sass/_archive.scss _pages/research.html
git commit -m "Restyle list rows and group publications by year

Publications had no year dividers; adds Liquid grouping via
group_by_exp and an explicit date sort, replacing reliance on the
collection's default order."
```

---

## Task 7: Remove dead head references

**Files:**
- Modify: `_includes/head/custom.html:5-20`, `_includes/head/custom.html:23`
- Delete: `images/manifest.json`

14 of the 19 local assets referenced do not exist. `manifest.json` exists but declares `"name": "Minimal Mistakes"` and lists six icons that are all missing.

- [ ] **Step 1: Confirm the current state before changing anything**

```bash
python3 - <<'EOF'
import re, os
s = open('_includes/head/custom.html').read()
miss, ok = [], []
for p in re.findall(r'(?:href|content)="([^"]+)"', s):
    q = p.replace('{{ base_path }}', '').split('?')[0].lstrip('/')
    if not q or q.startswith(('http', '#')): continue
    (ok if os.path.exists(q) else miss).append(q)
print('missing', len(miss)); [print('  ', x) for x in miss]
print('resolve', len(ok));  [print('  ', x) for x in ok]
assert len(miss) == 14, len(miss)
EOF
```

Expected: `missing 14` and `resolve 5`. Note the Liquid tags and `?v=` query strings must be stripped before the existence check — a naive check reports every path as missing.

- [ ] **Step 2: Delete lines 5 through 20 and line 23**

Remove these 15 `<link>` elements and 1 `<meta>` from `_includes/head/custom.html`:

- the nine `<link rel="apple-touch-icon" …>` lines (57x57, 60x60, 72x72, 76x76, 114x114, 120x120, 144x144, 152x152, 180x180)
- the four `<link rel="icon" …>` lines (favicon-32x32, android-chrome-192x192, favicon-96x96, favicon-16x16)
- `<link rel="manifest" href="{{ base_path }}/images/manifest.json?v=M44lzPylqQ">`
- `<link rel="shortcut icon" href="/images/favicon.ico?v=M44lzPylqQ">`
- `<meta name="msapplication-config" content="{{ base_path }}/images/browserconfig.xml?v=M44lzPylqQ">`

**Keep** `<link rel="mask-icon" href="…safari-pinned-tab.svg…">` and `assets/css/academicons.css` — both resolve.

The `msapplication-config` meta goes even though `browserconfig.xml` exists, because that XML points at `mstile-144x144.png` and the tile is Minimal Mistakes artwork. Leave `browserconfig.xml` and `mstile-144x144.png` on disk — the user has not yet confirmed whether that and `safari-pinned-tab.svg` are his own artwork.

- [ ] **Step 3: Delete the manifest**

```bash
git rm images/manifest.json
```

- [ ] **Step 4: Verify zero dead references remain**

```bash
jclean && jbuild
python3 - <<'EOF'
import re, os
s = open('_includes/head/custom.html').read()
miss = []
for p in re.findall(r'(?:href|content)="([^"]+)"', s):
    q = p.replace('{{ base_path }}', '').split('?')[0].lstrip('/')
    if not q or q.startswith(('http', '#')): continue
    if not os.path.exists(q): miss.append(q)
print('remaining dead references:', miss)
assert miss == [], miss
built = open('_site/index.html').read()
assert 'apple-touch-icon' not in built, 'apple-touch-icon still emitted'
assert 'manifest.json' not in built, 'manifest still referenced'
assert 'safari-pinned-tab.svg' in built, 'mask-icon was removed by mistake'
print('Task 7 OK')
EOF
```

Expected: `remaining dead references: []` then `Task 7 OK`.

- [ ] **Step 5: Commit**

```bash
git add _includes/head/custom.html
git commit -m "Remove 14 dead icon references and the theme manifest

manifest.json declared the site as \"Minimal Mistakes\" and listed six
android-chrome icons that were all missing. Keeps safari-pinned-tab.svg
and academicons.css, which resolve."
```

---

## Task 8: Whole-site verification

**Files:** none modified — this task only verifies.

- [ ] **Step 1: Clean build**

```bash
jclean && jbuild
```

Expected: no Liquid errors, no warnings about missing includes.

- [ ] **Step 2: Check every internal page link still resolves**

```bash
python3 - <<'EOF'
import os, re, glob
pages = glob.glob('_site/**/*.html', recursive=True)
broken = []
for f in pages:
    for href in re.findall(r'href="(/[^"#?]*)"', open(f, encoding='utf-8').read()):
        if href.startswith('//'): continue
        base = href.lstrip('/')
        cands = [os.path.join('_site', base),
                 os.path.join('_site', base, 'index.html'),
                 os.path.join('_site', base + '.html')]
        if not any(os.path.exists(c) for c in cands):
            broken.append((f.replace('_site/', ''), href))
print('pages scanned :', len(pages))
print('broken links  :', len(broken))
for b in sorted(set(broken))[:20]: print('   ', b)
assert not broken, broken
print('all internal links resolve')
EOF
```

Expected: about 53 pages scanned, `broken links : 0`. The third candidate (`base + '.html'`) is essential — collection entries build as `foo.html` and are served extensionless.

- [ ] **Step 3: Confirm the palette reaches every page, not just `/work/`**

```bash
python3 - <<'EOF'
import glob
targets = ['_site/index.html', '_site/cv/index.html', '_site/work/index.html',
           '_site/research/index.html', '_site/blog/index.html']
css = open('_site/assets/css/main.css').read()
assert '#faf8f3' in css and '#8a6508' in css and 'Georgia' in css
for t in targets:
    html = open(t).read()
    assert 'assets/css/main.css' in html, f'{t} does not load main.css'
    print('PASS ', t)
print('palette reaches all key pages')
EOF
```

Expected: five `PASS` lines then `palette reaches all key pages`.

- [ ] **Step 4: Re-run the contrast audit against the compiled CSS**

```bash
python3 - <<'EOF'
def lum(h):
    h = h.lstrip('#'); c = [int(h[i:i+2],16)/255 for i in (0,2,4)]
    c = [(v/12.92 if v <= 0.04045 else ((v+0.055)/1.055)**2.4) for v in c]
    return 0.2126*c[0] + 0.7152*c[1] + 0.0722*c[2]
def cr(a,b):
    la, lb = lum(a), lum(b); hi, lo = max(la,lb), min(la,lb)
    return (hi+0.05)/(lo+0.05)
pairs = [('#4c4a41','#faf8f3','body on cream'),
         ('#8a6508','#faf8f3','link on cream'),
         ('#6a675e','#faf8f3','muted on cream'),
         ('#1a1913','#ffffff','card title on card'),
         ('#4c4a41','#ffffff','card excerpt on card'),
         ('#8a6508','#ffffff','card result on card'),
         ('#6a675e','#ffffff','card result_note on card'),
         ('#7a5b06','#f6e9c4','tag text on chip')]
bad = []
for a,b,l in pairs:
    v = cr(a,b); print(f'{v:5.2f}:1  {l}')
    if v < 4.5: bad.append((l, round(v,2)))
assert not bad, f'below AA: {bad}'
print('every text pair passes WCAG AA')
EOF
```

Expected: eight ratios, all >= 4.5, then `every text pair passes WCAG AA`.

- [ ] **Step 5: Confirm no image assets were added**

```bash
git status --short images/ ; git diff --cached --stat HEAD -- images/
python3 -c "
import subprocess
out = subprocess.run(['git','diff','--name-status','HEAD~7','HEAD','--','images/'],
                     capture_output=True, text=True).stdout
added = [l for l in out.splitlines() if l.startswith('A')]
print('added image files:', added)
assert not added, added
print('no new image assets')
"
```

Expected: `added image files: []` then `no new image assets`. Success criterion 8 in the spec requires this.

- [ ] **Step 6: Report to the user and request a visual check**

Verification so far is structural — it proves the CSS compiled and the markup is correct, **not** that the page looks right. State that limit plainly rather than claiming the design works.

Ask the user to open the site and confirm: two card columns at desktop width and one on a narrow window; the ochre top rule and result eyebrows; serif site title with sans nav links; year headings on `/research/` with author lists intact.

To serve locally:

```bash
docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle \
  -w /srv/jekyll -p 4000:4000 ruby:3.2 \
  bash -c "bundle install --quiet && bundle exec jekyll serve --host 0.0.0.0"
```

Then visit `http://localhost:4000/work/`.

- [ ] **Step 7: Push only after the user confirms**

Plain `git push` fails on this repo — it authenticates as the wrong user. Use the personal key:

```bash
GIT_SSH_COMMAND="ssh -F /dev/null -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -i $HOME/.ssh/id_ed25519_prathmesh_personal" git push origin master
```

Then confirm the deploy:

```bash
sleep 30 && curl -s -o /dev/null -w '%{http_code}\n' https://prathmeshrmadhu.github.io/work/
```

Expected: `200`.

---

## Self-Review

**Spec coverage.** Every spec section maps to a task: palette → 1; typography and the three overrides → 1 (variable) and 2 (selectors); file structure → all; card component → 4 (CSS) and 5 (markup); measured vs unmeasured results → 3 and 5; front-matter additions → 3; list restyle and year grouping → 6; head cleanup → 7. Success criteria 1–2 → Task 5 Step 3; 3 → Task 3 Step 3 and Task 5 Step 3; 4 → Task 8 Step 3; 5 → Task 6 Step 5; 6 → Task 8 Step 4; 7 → Task 7 Step 4; 8 → Task 8 Step 5; 9 → Task 5 Step 4 and Task 8 Step 2; 10 → Task 8 Step 1.

**Naming consistency.** `.wgrid`, `.wcard`, `.wcard__result`, `.wcard__result--note`, `.wcard__title`, `.wcard__excerpt`, `.wcard__tags` are defined in Task 4 and used with identical names in Task 5 and in every assertion. `$muted-color` and `$accent-color` are declared in Task 1 before Task 4 and Task 6 consume them. `.archive__year` is defined in Task 6 Step 2 and emitted in Task 6 Step 4.

**Known limits of this plan.**

1. **No visual verification is possible from the command line.** Every check here is structural. Task 8 Step 6 hands that to the user explicitly rather than declaring success.
2. **Task 6 Step 3 reaches unclassed `<p>` elements positionally**, because the citation markup lives in `archive-single.html` and this phase does not modify that file. It is the one fragile selector in the plan. If it misbehaves, the correct fix is to add a class in `archive-single.html` — which is out of scope here and should be raised, not silently done.
3. **Task 8 Step 5 assumes exactly 7 commits** (`HEAD~7`). If tasks are combined or split, adjust the range or compare against the pre-Phase-3 SHA instead.
