# Blog Cards and CV Polish (Phase 3.1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the Phase 3 card layout from `/work/` to `/blog/`, and give `/cv/` a visual pass that fixes its six-`<h1>` bug and cuts the half of the page that duplicates `/research/`.

**Architecture:** The card component is renamed from work-specific names (`.wcard`) to neutral ones (`.card`) so two pages can share it honestly, then a second include `blog-card.html` renders posts into the same grid. The CV is restyled entirely through kramdown inline attribute lists (`{: .class}`) plus a new `_sass/_cv.scss`, so `cv.md` never becomes HTML.

**Tech Stack:** Jekyll 3.10 via the `github-pages` gem, Minimal Mistakes / Academic Pages, Sass with susy 2 and breakpoint mixins, kramdown with GFM input, Docker `ruby:3.2` for the toolchain.

**Spec:** `docs/superpowers/specs/2026-08-18-blog-cards-and-cv-polish-design.md`

---

## Before You Start

### There is no local Ruby. Everything runs in Docker.

Shell state does **not** persist between tool calls, so these two functions must be redefined in every Bash call that uses them:

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
```

Builds take about 4 seconds. `_site` is created root-owned, which is why `jclean` deletes it from inside a container rather than with a host `rm`.

**Run `jclean` before any check that asserts something is *gone*.** A stale `_site` will happily show you the old output and you will believe a broken change worked.

### Verification is Python against built output

There is no test framework in this repo — it is a static site. The Phase 3 plan established the working pattern and this plan follows it: assert against the built HTML in `_site/` and the compiled CSS at `_site/assets/css/main.css`. Host `python3` is available; no container needed for the checks.

Two traps that cost time during Phase 3, both still live:

- **`grep -c` counts matching *lines*, not matches.** All of this markup is emitted on single lines, so `grep -c` is useless for counting it. Use Python's `str.count`.
- **Liquid's `for` tag ignores piped filters.** `{% for p in site.x | sort: 'date' %}` silently does nothing. The sort must happen in a preceding `{% assign %}`.

### Do not touch

- `_posts/2026-05-03-work-love.md` — untracked draft, empty title. It **will** render a fourth, blank blog card in local builds. That is expected and is not a bug; it cannot reach the published site because it is not committed. Every blog check in this plan is written to tolerate it.
- `_includes/archive-single.html`, `_includes/archive-single-cv.html`, `_includes/archive-single-talk-cv.html` — shared includes, deliberately out of scope.
- `_pages/research.html` — must come out of this phase unchanged.
- The `result:` / `result_note:` front-matter keys in `_portfolio/*.md`. The CSS class is renamed; the data field is not. The field describes content, and the content genuinely is a result.
- The Phase 3 spec and plan in `docs/superpowers/`. They record the old class names as history and are not rewritten.

### Commit directly to master

This project has no feature branches. Each task ends in a commit on `master`. Do not push until Task 10.

---

## File Structure

| file | action | responsibility |
|---|---|---|
| `_sass/_variables.scss` | modify | add `$title-color`, `$chip-background`, `$chip-color` |
| `_sass/_cards.scss` | modify | rename classes; consume the three new variables |
| `_sass/_cv.scss` | **create** | CV entry, category, chip and note styles only |
| `assets/css/main.scss` | modify | `@import "cv";` between `cards` and `sidebar` |
| `_includes/work-card.html` | modify | rename classes only, no structural change |
| `_pages/work.html` | modify | `.wgrid` → `.cardgrid` only |
| `_includes/blog-card.html` | **create** | blog card markup |
| `_pages/blog.html` | modify | replace year-grouped list with card grid |
| `_posts/2026-03-31-information-overload.md` | modify | add `excerpt:` |
| `_posts/2020-09-30-why-fastai.md` | modify | add `excerpt:` |
| `_posts/2020-07-12-rip-banerjee-sir.md` | modify | add `excerpt:` |
| `_pages/cv.md` | modify | headings, entry pattern, chips, publications condensation |

---

## Task 1: Hoist shared colour values into variables

Three literals live in `_sass/_cards.scss` today and would be copy-pasted into `_sass/_cv.scss` in Task 6. Hoist them first so there is one definition.

This task must produce **byte-identical compiled CSS**. That is the whole test: a pure refactor that changes output is a bug.

**Files:**
- Modify: `_sass/_variables.scss` (after the Phase 3 palette additions, around line 66)
- Modify: `_sass/_cards.scss`

- [ ] **Step 1: Capture the current compiled CSS as a baseline**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild && cp _site/assets/css/main.css /tmp/baseline-main.css && wc -c /tmp/baseline-main.css
```

Expected: a byte count printed, no Liquid errors in the build output.

- [ ] **Step 2: Add the three variables**

In `_sass/_variables.scss`, find this block:

```scss
/* Phase 3 palette additions — these do not exist in Minimal Mistakes */
$muted-color                : #6a675e;  /* 5.33:1 on #faf8f3 */
$accent-color               : #b8860b;  /* 3.07:1 — DECORATION ONLY, never text */
```

Replace it with:

```scss
/* Phase 3 palette additions — these do not exist in Minimal Mistakes */
$muted-color                : #6a675e;  /* 5.33:1 on #faf8f3 */
$accent-color               : #b8860b;  /* 3.07:1 — DECORATION ONLY, never text */

/* Phase 3.1 — shared by _cards.scss and _cv.scss */
$title-color                : #1a1913;  /* 16.59:1 on #faf8f3 */
$chip-background            : #f6e9c4;
$chip-color                 : #7a5b06;  /* 5.22:1 on $chip-background */
```

- [ ] **Step 3: Consume them in `_sass/_cards.scss`**

Three edits, each replacing a literal with its variable.

In `.wcard__title`, change:

```scss
      a { color: #1a1913; text-decoration: none; }
```

to:

```scss
      a { color: $title-color; text-decoration: none; }
```

In `.wcard__tags`, change:

```scss
      li { margin: 0; padding: 0.15em 0.6em; font-size: $type-size-7;
           border-radius: 20px; background: #f6e9c4; color: #7a5b06; }
```

to:

```scss
      li { margin: 0; padding: 0.15em 0.6em; font-size: $type-size-7;
           border-radius: 20px; background: $chip-background; color: $chip-color; }
```

- [ ] **Step 4: Verify the compiled CSS is byte-identical**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild && diff /tmp/baseline-main.css _site/assets/css/main.css && echo "IDENTICAL — refactor is clean"
```

Expected: `IDENTICAL — refactor is clean`, and `diff` prints nothing.

If `diff` prints anything, a literal was mistyped. Compare the differing line against the variable value; do not proceed until identical.

- [ ] **Step 5: Commit**

```bash
git add _sass/_variables.scss _sass/_cards.scss
git commit -m "Hoist card title and chip colours into variables

The CV partial needs the same three values. Compiled CSS is byte-identical."
```

---

## Task 2: Rename `.wgrid`/`.wcard` to `.cardgrid`/`.card`

The component is about to be shared with `/blog/`, so the `w`-for-work prefix stops being true. `result` becomes `eyebrow` because that slot holds a metric on Work and a date on Blog.

| old | new |
|---|---|
| `.wgrid` | `.cardgrid` |
| `.wcard` | `.card` |
| `.wcard__result` | `.card__eyebrow` |
| `.wcard__result--note` | `.card__eyebrow--note` |
| `.wcard__title` | `.card__title` |
| `.wcard__excerpt` | `.card__excerpt` |
| `.wcard__tags` | `.card__tags` |

**Files:**
- Modify: `_sass/_cards.scss`
- Modify: `_includes/work-card.html`
- Modify: `_pages/work.html:13`

- [ ] **Step 1: Capture the current `/work/` HTML as a baseline**

```bash
cp _site/work/index.html /tmp/baseline-work.html && grep -o 'class="w[a-z_-]*"' /tmp/baseline-work.html | sort | uniq -c
```

Expected output:

```
      6 class="wcard"
      1 class="wgrid"
      2 class="wcard__excerpt"
```

…plus lines for `wcard__result`, `wcard__title` and `wcard__tags`. The exact counts do not matter here; this file is the comparison target for Step 5.

- [ ] **Step 2: Rewrite `_sass/_cards.scss` in full**

Replace the entire file with:

```scss
/* ==========================================================================
   CARDS  —  /work/ and /blog/
   ========================================================================== */

.cardgrid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1.5em;
  margin-bottom: 2em;

  @include breakpoint($medium) {
    grid-template-columns: 1fr 1fr;
  }
}

.card {
  display: flex;
  flex-direction: column;
  background: #fff;
  border: 1px solid $border-color;
  border-top: 3px solid $accent-color;
  border-radius: $border-radius;
  padding: 1.1em 1.2em 1.3em;

  /* Holds a result on /work/ and a date on /blog/ — hence the neutral name. */
  &__eyebrow {
    margin: 0 0 0.4em;
    font-size: $type-size-7;
    font-weight: 700;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    color: $link-color;

    &--note { color: $muted-color; }
  }

  &__title {
    margin: 0 0 0.45em;
    font-family: $serif;
    font-size: $type-size-4;
    line-height: 1.25;
    border-bottom: 0;

    a { color: $title-color; text-decoration: none; }
    a:hover { color: $link-color; text-decoration: underline; }
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
      background: $chip-background;
      color: $chip-color;
    }
  }
}
```

The only changes from the previous version are the selector names, the `border-bottom: 0` staying put, and the added comment on `&__eyebrow`. Every property value is unchanged.

- [ ] **Step 3: Rewrite `_includes/work-card.html` in full**

```liquid
{% include base_path %}

<article class="card">
  {% if post.result %}
    <p class="card__eyebrow">{{ post.result }}</p>
  {% elsif post.result_note %}
    <p class="card__eyebrow card__eyebrow--note">{{ post.result_note }}</p>
  {% endif %}

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

Note `post.result` and `post.result_note` are **unchanged** — only the class attributes moved.

- [ ] **Step 4: Change the grid wrapper in `_pages/work.html`**

Change line 13 from:

```html
<div class="wgrid">
```

to:

```html
<div class="cardgrid">
```

- [ ] **Step 5: Verify `/work/` is unchanged apart from class names**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild
python3 - <<'PY'
import re, sys

old = open('/tmp/baseline-work.html').read()
new = open('_site/work/index.html').read()

# Normalise the baseline forward through the rename, then require an exact match.
m = [('wcard__result--note','card__eyebrow--note'),
     ('wcard__result','card__eyebrow'),
     ('wcard__title','card__title'),
     ('wcard__excerpt','card__excerpt'),
     ('wcard__tags','card__tags'),
     ('wcard','card'),
     ('wgrid','cardgrid')]
norm = old
for a, b in m:
    norm = norm.replace(a, b)

checks = {
    'renamed baseline matches new output': norm == new,
    'six cards':            new.count('class="card"') == 6,
    'one grid':             new.count('class="cardgrid"') == 1,
    'four plain eyebrows':  len(re.findall(r'class="card__eyebrow">', new)) == 4,
    'two note eyebrows':    len(re.findall(r'class="card__eyebrow card__eyebrow--note">', new)) == 2,
    'six tag lists':        new.count('class="card__tags"') == 6,
    'no stale wcard':       'wcard' not in new,
    'no stale wgrid':       'wgrid' not in new,
}
for k, v in checks.items():
    print(('PASS' if v else 'FAIL'), '-', k)
sys.exit(0 if all(checks.values()) else 1)
PY
```

Expected: eight `PASS` lines, exit 0.

If `renamed baseline matches new output` fails, print the first differing offset to find out what else changed — the rename must not alter structure:

```bash
python3 -c "
old=open('/tmp/baseline-work.html').read()
for a,b in [('wcard__result--note','card__eyebrow--note'),('wcard__result','card__eyebrow'),('wcard__title','card__title'),('wcard__excerpt','card__excerpt'),('wcard__tags','card__tags'),('wcard','card'),('wgrid','cardgrid')]: old=old.replace(a,b)
new=open('_site/work/index.html').read()
i=next((i for i,(x,y) in enumerate(zip(old,new)) if x!=y), min(len(old),len(new)))
print('first difference at', i); print('old:', repr(old[i-80:i+80])); print('new:', repr(new[i-80:i+80]))
"
```

- [ ] **Step 6: Confirm the old names are gone from source too**

```bash
grep -rn 'wcard\|wgrid' _sass/ _includes/ _pages/ assets/ 2>/dev/null && echo "FAIL — stale names remain" || echo "PASS — no wcard/wgrid in source"
```

Expected: `PASS — no wcard/wgrid in source`.

This deliberately does not search `docs/`, where the Phase 3 spec and plan keep the old names as history.

- [ ] **Step 7: Commit**

```bash
git add _sass/_cards.scss _includes/work-card.html _pages/work.html
git commit -m "Rename card classes from work-specific to neutral

/blog/ is about to share this component, so .wcard stops being true.
.wcard__result becomes .card__eyebrow because the slot holds a result
on /work/ and a date on /blog/. Rendered /work/ HTML is identical
apart from the class attributes."
```

---

## Task 3: Add excerpts to the three posts

Jekyll's auto-excerpt is the first paragraph. The Banerjee post's first paragraph is `TL; DR`, six characters, which is a hole in a card. These three strings were approved verbatim by the user.

All three are double-quoted because each contains an apostrophe.

**Files:**
- Modify: `_posts/2026-03-31-information-overload.md`
- Modify: `_posts/2020-09-30-why-fastai.md`
- Modify: `_posts/2020-07-12-rip-banerjee-sir.md`

- [ ] **Step 1: Add `excerpt:` to the information-overload post**

In `_posts/2026-03-31-information-overload.md`, insert after the `permalink:` line:

```yaml
excerpt: "We keep blaming the sheer volume of information. I think the damage is done by the velocity — and the fix isn't reading less, it's putting the friction back."
```

- [ ] **Step 2: Add `excerpt:` to the fastai post**

In `_posts/2020-09-30-why-fastai.md`, insert after the `permalink:` line:

```yaml
excerpt: "Notes from my first pass through fastai — why the top-down, build-something-first approach works for beginners, and the data ethics questions the course refuses to let you skip."
```

- [ ] **Step 3: Add `excerpt:` to the Banerjee post**

In `_posts/2020-07-12-rip-banerjee-sir.md`, insert after the `permalink:` line — before `redirect_from:`, so the list stays contiguous with its key:

```yaml
excerpt: "Prof. Asim Banerjee was the first person I spoke to at DAIICT, on day one. A long and unhurried remembrance of six years of his scoldings, his arguments, and his ideas about what a university is for."
```

- [ ] **Step 4: Verify the front matter parses and the excerpts took effect**

The blog page is still the old list layout at this point, which is fine — `archive-single.html` already renders `archive__item-excerpt`, so the new values are visible there.

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild
python3 - <<'PY'
import re, sys, html

h = open('_site/blog/index.html').read()
excerpts = [re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', '', m))).strip()
            for m in re.findall(r'archive__item-excerpt"[^>]*>(.*?)</p>', h, re.S)]

want = ['We keep blaming the sheer volume of information',
        'Notes from my first pass through fastai',
        'Prof. Asim Banerjee was the first person I spoke to at DAIICT']

checks = {'TL; DR is gone': not any(e.strip() == 'TL; DR' for e in excerpts)}
for w in want:
    checks[f'present: {w[:40]}'] = any(e.startswith(w) for e in excerpts)

for k, v in checks.items():
    print(('PASS' if v else 'FAIL'), '-', k)
print('\nexcerpts found:')
for e in excerpts:
    print(' -', repr(e[:70]))
sys.exit(0 if all(checks.values()) else 1)
PY
```

Expected: four `PASS` lines, exit 0. The listed excerpts may include a blank one from the untracked draft; that is expected.

- [ ] **Step 5: Commit**

```bash
git add _posts/2026-03-31-information-overload.md _posts/2020-09-30-why-fastai.md _posts/2020-07-12-rip-banerjee-sir.md
git commit -m "Write real excerpts for the three blog posts

Auto-excerpts take the first paragraph, which for the Banerjee post is
literally 'TL; DR'. Cards give the excerpt most of the body weight, so
each post now carries an explicit one."
```

---

## Task 4: Render `/blog/` as a card grid

**Files:**
- Create: `_includes/blog-card.html`
- Modify: `_pages/blog.html`

- [ ] **Step 1: Create `_includes/blog-card.html`**

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

Two things that look optional but are not. `%-d` is Ruby strftime for a non-zero-padded day, verified to give `12 July 2020`. And `markdownify | strip_html | strip_newlines` is carried over from the work card because `markdownify` wraps its output in `<p>`, and nesting that inside `<p class="card__excerpt">` is invalid HTML.

- [ ] **Step 2: Replace the body of `_pages/blog.html`**

Keep the front matter exactly as it is, including both `redirect_from` entries. Replace everything below it with:

```liquid
{% include base_path %}

<div class="cardgrid">
{% for post in site.posts %}
  {% include blog-card.html %}
{% endfor %}
</div>
```

The whole file becomes:

```liquid
---
layout: archive
permalink: /blog/
title: "Blog posts"
author_profile: true
redirect_from:
  - /year-archive/
  - /wordpress/blog-posts/
---

{% include base_path %}

<div class="cardgrid">
{% for post in site.posts %}
  {% include blog-card.html %}
{% endfor %}
</div>
```

`site.posts` is already newest-first, so no `sort` and therefore no `{% assign %}` is needed. The `{% capture written_year %}` year-grouping logic is deleted, per the design decision that a year heading repeats the date now shown on every card.

- [ ] **Step 3: Verify the grid, and that the three real posts are complete**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild
python3 - <<'PY'
import re, sys

h = open('_site/blog/index.html').read()
cards = re.findall(r'<article class="card">(.*?)</article>', h, re.S)

def field(c, cls):
    m = re.search(r'class="%s"[^>]*>(.*?)</' % cls, c, re.S)
    return re.sub(r'<[^>]+>', '', m.group(1)).strip() if m else None

want = {
    '/posts/2026/03/31/information-overload/': ('31 March 2026', 3),
    '/posts/2020/09/30/why-fastai/':          ('30 September 2020', 1),
    '/posts/2020/07/12/rip-banerjee-sir/':    ('12 July 2020', 1),
}

by_url = {}
for c in cards:
    m = re.search(r'card__title">\s*<a href="([^"]+)"', c)
    if m:
        by_url[m.group(1)] = c

checks = {
    'one cardgrid':          h.count('class="cardgrid"') == 1,
    'no year headings left': 'archive__subtitle' not in h,
    'no list rows left':     'class="list__item"' not in h,
    'at least three cards':  len(cards) >= 3,
}

for url, (date, ntags) in want.items():
    c = next((v for k, v in by_url.items() if k.endswith(url)), None)
    checks[f'card exists: {url}'] = c is not None
    if c:
        checks[f'eyebrow date: {url}'] = field(c, 'card__eyebrow') == date
        checks[f'excerpt non-empty: {url}'] = bool((field(c, 'card__excerpt') or '').strip())
        checks[f'tag count {ntags}: {url}'] = c.count('<li>') == ntags

for k, v in checks.items():
    print(('PASS' if v else 'FAIL'), '-', k)
print(f'\ntotal cards rendered: {len(cards)}  (4 locally is expected — untracked draft)')
sys.exit(0 if all(checks.values()) else 1)
PY
```

Expected: all `PASS`, exit 0, and `total cards rendered: 4` locally.

- [ ] **Step 4: Confirm `/work/` and `/research/` did not move**

```bash
python3 -c "
w=open('_site/work/index.html').read(); r=open('_site/research/index.html').read()
print('work cards      :', w.count('class=\"card\"'), '(want 6)')
print('research cards  :', r.count('class=\"card\"'), '(want 0)')
print('research pubs   :', r.count('class=\"list__item\"'), '(want 26)')
assert w.count('class=\"card\"')==6 and r.count('class=\"card\"')==0 and r.count('class=\"list__item\"')==26
print('PASS')
"
```

Expected: `PASS`.

- [ ] **Step 5: Commit**

```bash
git add _includes/blog-card.html _pages/blog.html
git commit -m "Render /blog/ as a card grid

Same grid and card CSS as /work/, with the post date in the eyebrow slot.
Year headings are dropped because every card now shows its own date."
```

---

## Task 5: Fix the CV's six `<h1>` elements

`Education` followed by `======` is markdown setext H1 syntax. Six sections use it, so the page carries six `<h1>`s on top of the layout's own title, and publication titles then render as `h3` with no `h2` between.

**Files:**
- Modify: `_pages/cv.md`

- [ ] **Step 1: Replace all six setext headings with ATX `##`**

Six edits in `_pages/cv.md`. In each case a two-line pair becomes one line.

Replace:

```markdown
Education
======
```

with:

```markdown
## Education
```

Then the same transformation for the five others — `Experience`, `Skills`, `Publications`, `Talks`, `Teaching`. Each is the section name followed by a line of `======`, and each becomes `## ` plus the name.

- [ ] **Step 2: Verify the heading hierarchy**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild
python3 - <<'PY'
import re, sys

h = open('_site/cv/index.html').read()
body = h.split('page__content')[1].split('</section')[0]
levels = [(int(t[1]), re.sub(r'<[^>]+>', '', c).strip())
          for t, c in re.findall(r'<(h[1-6])[^>]*>(.*?)</\1>', body, re.S)]

h1 = [t for lvl, t in levels if lvl == 1]
h2 = [t for lvl, t in levels if lvl == 2]

want_h2 = ['Education', 'Experience', 'Skills', 'Publications', 'Talks', 'Teaching']

checks = {
    'exactly one h1':      len(h1) == 1,
    'the h1 is the title': h1 == ['CV'],
    'six h2 sections':     len(h2) == 6,
    'h2 names correct':    h2 == want_h2,
}
for k, v in checks.items():
    print(('PASS' if v else 'FAIL'), '-', k)
print('\nh1:', h1)
print('h2:', h2)
sys.exit(0 if all(checks.values()) else 1)
PY
```

Expected: four `PASS`, exit 0, `h1: ['CV']`, `h2: ['Education', 'Experience', 'Skills', 'Publications', 'Talks', 'Teaching']`.

- [ ] **Step 3: Commit**

```bash
git add _pages/cv.md
git commit -m "Fix CV heading levels: six h1s become h2

The ====== underlines were setext H1 syntax, so the page had six
full-weight page titles. Phase 3's serif headings made this obvious."
```

---

## Task 6: Create the CV stylesheet

CSS before markup, so the next three tasks can be checked visually as they land.

**Files:**
- Create: `_sass/_cv.scss`
- Modify: `assets/css/main.scss:35`

- [ ] **Step 1: Create `_sass/_cv.scss`**

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

  /* margin: 0 is load-bearing — Minimal Mistakes styles .page__content li
     with a bottom margin, which breaks the flex row. */
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

- [ ] **Step 2: Import it in `assets/css/main.scss`**

The imports currently read:

```scss
@import "page";
@import "archive";
@import "cards";
@import "sidebar";
```

Change to:

```scss
@import "page";
@import "archive";
@import "cards";
@import "cv";
@import "sidebar";
```

- [ ] **Step 3: Verify the classes compile**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild
python3 - <<'PY'
import sys
css = open('_site/assets/css/main.css').read()
want = ['.cv-date', '.cv-role', '.cv-org', '.cv-cat', '.cv-chips', '.cv-note',
        '.card', '.cardgrid']
checks = {f'{w} in compiled css': w in css for w in want}
checks['chip bg resolved']   = '#f6e9c4' in css
checks['chip text resolved'] = '#7a5b06' in css
for k, v in checks.items():
    print(('PASS' if v else 'FAIL'), '-', k)
sys.exit(0 if all(checks.values()) else 1)
PY
```

Expected: all `PASS`, exit 0.

- [ ] **Step 4: Commit**

```bash
git add _sass/_cv.scss assets/css/main.scss
git commit -m "Add CV stylesheet partial

Entry, category, chip and note styles for /cv/, reusing the palette
variables. No markup consumes these yet."
```

---

## Task 7: Restructure CV Experience and Education entries

Dates move out of the bold run-on line and become an ochre eyebrow. Role goes serif, organisation becomes a muted line. This is done with kramdown inline attribute lists, so `cv.md` stays markdown.

The IAL goes on the line **immediately after** the block it applies to, with no blank line between them.

**Files:**
- Modify: `_pages/cv.md`

- [ ] **Step 1: Replace the Education section**

Replace everything from `## Education` up to but not including `## Experience` with:

```markdown
## Education

Dec 2018 – Nov 2022
{: .cv-date}

Ph.D., Computer Science (Computer Vision)
{: .cv-role}

Friedrich-Alexander-Universität Erlangen-Nürnberg
{: .cv-org}

* Chair of Pattern Recognition. Dissertation on scene understanding in digital humanities.
* Cumulative GPA: 1.3/4.0 (1.0 best)

Jul 2014 – May 2016
{: .cv-date}

M.Tech., Information & Communication Technology
{: .cv-role}

DAIICT, Gandhinagar
{: .cv-org}

* Cumulative GPA: 9.23/10.0

2014
{: .cv-date}

B.E., Electronics & Communication Engineering
{: .cv-role}

LD College of Engineering, Ahmedabad
{: .cv-org}

```

Every fact is carried over from the current text unchanged. The en dashes in the date ranges are U+2013.

- [ ] **Step 2: Replace the Experience section**

Replace everything from `## Experience` up to but not including `## Skills` with:

```markdown
## Experience

Aug 2026 – Present
{: .cv-date}

Senior Vice President – Machine Learning
{: .cv-role}

Infocusp Innovations, Pune
{: .cv-org}

* Promoted to lead the machine learning practice, with accountability for technical direction and delivery quality across the computer vision and LLM portfolio.
* Developing technical leads and strengthening evaluation and delivery standards across teams.

Jan 2025 – Jul 2026
{: .cv-date}

Vice President – Machine Learning
{: .cv-role}

Infocusp Innovations, Pune
{: .cv-org}

* Led the computer vision group (10+ engineers) across multiple concurrent LLM and computer vision projects, converting open-ended client requirements into crisp project definitions, task breakdowns, and agreed success criteria.
* Led a 4-engineer team optimising MASt3R-SLAM for drone trajectory tracking on Jetson Orin NX, delivering a ~9× inference speedup (0.26 → 2.4 FPS) under tight compute and power budgets using TensorRT and ONNX, plus adaptive retrieval that skips redundant relocalisations during turns.
* Led a 5-engineer team building agentic AI systems for user researchers — agents that execute analysis workflows and generate reports — with LLM-as-a-judge evaluation harnesses as a first-class deliverable.
* Delivered a production hybrid multimodal retrieval system fusing vector-indexed image and text search with keyword search, for heterogeneous visual collections where off-the-shelf embeddings fail.
* Designed agentic health-protocol generation for a regulated domain with an auditable LLM review layer.

Aug 2023 – Jan 2025
{: .cv-date}

Technical Lead – Machine Learning
{: .cv-role}

Infocusp Innovations, Pune
{: .cv-org}

* Fine-tuned TF Model Garden detection models for industrial defect inspection, achieving a 20% F1-score improvement on production data characterised by tiny targets, severe class imbalance, and few labelled failure examples; carried the work from data pipeline to customer POC.
* Built and led a 4-person R&D team on an LLM/RAG survey-analysis platform that summarises, tags, and reports on user-research data, cutting researcher time per project by 40%, validated against human-coded baselines.
* Translated peer-reviewed small-data techniques — transfer learning, attention-guided augmentation, one-shot detection — into repeatable delivery patterns for engagements where off-the-shelf models plateau.

Dec 2018 – Jun 2023
{: .cv-date}

PhD Researcher
{: .cv-role}

Friedrich-Alexander-Universität Erlangen-Nürnberg
{: .cv-org}

* Pioneered ICC and ICC++, explainable feature learning methods leveraging human pose to uncover semantics and link iconography across image datasets.
* Enhanced pose estimation in ancient Greek vase paintings through style transfer and a perceptual metric, and improved one-shot object detection for heterogeneous artwork images using data contextualisation strategies.
* Improved classification performance for breast calcification analysis using histogram equalisation.

Jul 2016 – Nov 2018
{: .cv-date}

Machine Learning Engineer
{: .cv-role}

Infocusp Innovations, Ahmedabad
{: .cv-org}

* Designed and deployed an enterprise candidate recommendation system processing 1M candidates daily to optimise hiring across multiple job positions.
* Led end-to-end development of a scalable hiring infrastructure using Python, PySpark and AWS, supporting concurrent multi-user access.
* Designed and implemented algorithms for reel, jerk, jigging and catch detection from fishing-rod sensor data — Python for development, C for deployment — with verification and validation testing.
* Contributed to [tf-cnnvis](https://github.com/InFoCusp/tf_cnnvis), an open-source CNN visualisation tool.

```

Every bullet is byte-identical to the current text. The only change is that each `**Role** · Company · Dates` line is split into three classed blocks.

- [ ] **Step 3: Verify the entries rendered and no content was lost**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild
python3 - <<'PY'
import re, sys, html

h = open('_site/cv/index.html').read()
txt = lambda s: re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', ' ', s))).strip()

dates = [txt(m) for m in re.findall(r'class="cv-date"[^>]*>(.*?)</p>', h, re.S)]
roles = [txt(m) for m in re.findall(r'class="cv-role"[^>]*>(.*?)</p>', h, re.S)]
orgs  = [txt(m) for m in re.findall(r'class="cv-org"[^>]*>(.*?)</p>',  h, re.S)]

checks = {
    'eight cv-date (3 education + 5 experience)': len(dates) == 8,
    'eight cv-role': len(roles) == 8,
    'eight cv-org':  len(orgs)  == 8,
    'SVP role present':      'Senior Vice President – Machine Learning' in roles,
    'PhD degree present':    'Ph.D., Computer Science (Computer Vision)' in roles,
    'BE degree present':     'B.E., Electronics & Communication Engineering' in roles,
    'current role dated':    'Aug 2026 – Present' in dates,
    'tf-cnnvis link kept':   'github.com/InFoCusp/tf_cnnvis' in h,
    'SLAM number kept':      '9× inference speedup' in txt(h),
    'F1 number kept':        '20% F1-score improvement' in txt(h),
    'no leftover middot separators': '·' not in txt(h).replace('&middot;', ''),
}
for k, v in checks.items():
    print(('PASS' if v else 'FAIL'), '-', k)
print('\ndates:', dates)
print('roles:', roles)
sys.exit(0 if all(checks.values()) else 1)
PY
```

Expected: all `PASS`, exit 0, with eight dates and eight roles listed.

- [ ] **Step 4: Commit**

```bash
git add _pages/cv.md
git commit -m "Restructure CV entries with dated eyebrows

Dates leave the bold run-on line and become an ochre eyebrow; role goes
serif and organisation becomes a muted line. Uses kramdown inline
attribute lists, so cv.md stays markdown. No content changed."
```

---

## Task 8: Turn CV skills into chips

CSS cannot split `Python, C` into two pills, so each skill becomes its own list item. Kramdown's IAL on the list supplies the class.

All 29 skills across 6 categories are carried over verbatim.

**Files:**
- Modify: `_pages/cv.md`

- [ ] **Step 1: Replace the Skills section**

Replace everything from `## Skills` up to but not including `## Publications` with:

```markdown
## Skills

Programming languages
{: .cv-cat}

* Python
* C
{: .cv-chips}

AI/ML frameworks
{: .cv-cat}

* TensorFlow
* PyTorch
* Scikit-learn
* OpenCV
* Hugging Face
* Transformers
* ONNX
* TensorRT
{: .cv-chips}

Technologies
{: .cv-cat}

* Prompt engineering
* Docker
* CI/CD (GitHub Actions, Jenkins)
{: .cv-chips}

Tools
{: .cv-cat}

* Git
* VSCode
* Pandas
* NumPy
* IceVision
* LangChain
* LlamaIndex
* Tensorboard
* JupyterLab
* Streamlit
{: .cv-chips}

Databases
{: .cv-cat}

* ElasticSearch
* FAISS
* TFRecords
* Protobuf
{: .cv-chips}

Cloud
{: .cv-cat}

* AWS (EC2, S3, Lambda, SageMaker)
* GCP
{: .cv-chips}

```

- [ ] **Step 2: Verify every skill survived**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild
python3 - <<'PY'
import re, sys, html

h = open('_site/cv/index.html').read()
txt = lambda s: html.unescape(re.sub(r'<[^>]+>', '', s)).strip()

cats  = [txt(m) for m in re.findall(r'class="cv-cat"[^>]*>(.*?)</p>', h, re.S)]
lists = re.findall(r'<ul class="cv-chips">(.*?)</ul>', h, re.S)
chips = [txt(li) for l in lists for li in re.findall(r'<li>(.*?)</li>', l, re.S)]

want_cats = ['Programming languages', 'AI/ML frameworks', 'Technologies',
             'Tools', 'Databases', 'Cloud']
want_chips = ['Python', 'C', 'TensorFlow', 'PyTorch', 'Scikit-learn', 'OpenCV',
              'Hugging Face', 'Transformers', 'ONNX', 'TensorRT',
              'Prompt engineering', 'Docker', 'CI/CD (GitHub Actions, Jenkins)',
              'Git', 'VSCode', 'Pandas', 'NumPy', 'IceVision', 'LangChain',
              'LlamaIndex', 'Tensorboard', 'JupyterLab', 'Streamlit',
              'ElasticSearch', 'FAISS', 'TFRecords', 'Protobuf',
              'AWS (EC2, S3, Lambda, SageMaker)', 'GCP']

checks = {
    'six categories':     cats == want_cats,
    'six chip lists':     len(lists) == 6,
    'twenty-nine chips':  len(chips) == 29,
    'all skills present': chips == want_chips,
}
for k, v in checks.items():
    print(('PASS' if v else 'FAIL'), '-', k)
missing = [w for w in want_chips if w not in chips]
if missing:
    print('MISSING:', missing)
extra = [c for c in chips if c not in want_chips]
if extra:
    print('UNEXPECTED:', extra)
sys.exit(0 if all(checks.values()) else 1)
PY
```

Expected: four `PASS`, exit 0, no `MISSING` or `UNEXPECTED` lines.

- [ ] **Step 3: Commit**

```bash
git add _pages/cv.md
git commit -m "Render CV skills as chips

One list item per skill so CSS can pill them, reusing the tag-chip style
from the Work cards. All 29 skills across 6 categories preserved."
```

---

## Task 9: Condense CV publications

Publications are 6,104 of the CV's 12,282 content characters — exactly half the page — and every entry already appears on `/research/`.

**Files:**
- Modify: `_pages/cv.md`

- [ ] **Step 1: Replace the Publications section**

Replace everything from `## Publications` up to but not including `## Talks` with:

```liquid
## Publications

{% assign pub_count = site.publications | size %}
{% assign recent_pubs = site.publications | sort: 'date' | reverse %}

{{ pub_count }} peer-reviewed publications. The five most recent are below; the [full list is on the research page]({{ base_path }}/research/).
{: .cv-note}

  <ul>{% for post in recent_pubs limit: 5 %}
    {% include archive-single-cv.html %}
  {% endfor %}</ul>

```

Three things worth understanding rather than copying blindly:

- The count is derived with `| size`, never typed, so it cannot drift from the collection.
- The `{% assign %}` on its own line is mandatory. Liquid's `for` tag ignores piped filters, so `{% for post in site.publications | sort: 'date' %}` would silently not sort.
- This replaces `{% for post in site.publications reversed %}`, which reversed **collection order**, not date order. `/research/` was corrected to `sort: 'date' | reverse` in Phase 3; this brings `/cv/` into line. Expect the five entries to differ from the five that `reversed` happened to produce.

The `## Talks` and `## Teaching` sections below are left exactly as they are.

- [ ] **Step 2: Verify the count, the five entries, and the link**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild
python3 - <<'PY'
import re, sys, html

cv = open('_site/cv/index.html').read()
body = cv.split('page__content')[1].split('</section')[0]
txt = lambda s: re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', ' ', s))).strip()

sections = re.split(r'<h2[^>]*>(.*?)</h2>', body)
named = {txt(sections[i]): sections[i + 1] for i in range(1, len(sections), 2)}

pubs = named.get('Publications', '')
note = re.search(r'class="cv-note"[^>]*>(.*?)</p>', pubs, re.S)

checks = {
    'note paragraph present':   note is not None,
    'derived count says 21':    bool(note) and '21 peer-reviewed publications' in txt(note.group(1)),
    'links to /research/':      '/research/' in pubs,
    'exactly five entries':     pubs.count('archive__item-title') == 5,
    'talks section intact':     named.get('Talks', '').count('archive__item-title') == 3,
    'teaching section intact':  named.get('Teaching', '').count('archive__item-title') == 2,
}

# The five must be the five newest by date, matching /research/'s ordering.
research = open('_site/research/index.html').read()
r_titles = re.findall(r'archive__item-title"[^>]*>\s*<a[^>]*>(.*?)</a>', research, re.S)
c_titles = re.findall(r'archive__item-title"[^>]*>\s*<a[^>]*>(.*?)</a>', pubs, re.S)
checks['five newest match /research/ order'] = [txt(t) for t in c_titles] == [txt(t) for t in r_titles[:5]]

for k, v in checks.items():
    print(('PASS' if v else 'FAIL'), '-', k)

print('\nCV publications listed:')
for t in c_titles:
    print(' -', txt(t)[:70])
print('\nsection sizes (visible chars):')
for n, s in named.items():
    print(f'  {n:14} {len(txt(s)):>6}')
sys.exit(0 if all(checks.values()) else 1)
PY
```

Expected: all `PASS`, exit 0, five titles listed, and `Publications` now well under its previous 6,104 characters.

- [ ] **Step 3: Commit**

```bash
git add _pages/cv.md
git commit -m "Condense CV publications to a count, five recent, and a link

Publications were half the CV's content and duplicated /research/ entirely.
The count is derived from the collection so it cannot go stale. Also fixes
'reversed', which reversed collection order rather than date order."
```

---

## Task 10: Whole-site verification, then push

**Files:** none modified.

- [ ] **Step 1: Clean build from scratch**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild 2>&1 | tail -20
```

Expected: `done in N seconds`, no `Liquid Warning`, no `Liquid Exception`.

- [ ] **Step 2: Run every success criterion from the spec**

```bash
python3 - <<'PY'
import re, sys, glob, html

txt = lambda s: re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', ' ', s))).strip()
blog = open('_site/blog/index.html').read()
work = open('_site/work/index.html').read()
res  = open('_site/research/index.html').read()
cv   = open('_site/cv/index.html').read()
css  = open('_site/assets/css/main.css').read()

cvbody = cv.split('page__content')[1].split('</section')[0]
cvlv = [int(t[1]) for t, _ in re.findall(r'<(h[1-6])[^>]*>(.*?)</\1>', cvbody, re.S)]

# no stale class names anywhere in the built site or the source
stale = [f for f in glob.glob('_site/**/*.html', recursive=True) + ['_site/assets/css/main.css']
         if 'wcard' in open(f).read() or 'wgrid' in open(f).read()]

checks = {
    '2:  blog has one cardgrid':        blog.count('class="cardgrid"') == 1,
    '2:  blog has >=3 cards':           blog.count('class="card"') >= 3,
    '2:  every blog card has eyebrow':  blog.count('class="card__eyebrow"') == blog.count('class="card"'),
    '3:  no wcard/wgrid in _site':      not stale,
    '4:  work still has six cards':     work.count('class="card"') == 6,
    '5:  cv has exactly one h1':        cvlv.count(1) == 1,
    '5:  cv has six h2':                cvlv.count(2) == 6,
    '5:  cv skips no heading level':    all(b - a <= 1 for a, b in zip(sorted(set(cvlv)), sorted(set(cvlv))[1:])),
    '6:  cv count says 21':             '21 peer-reviewed publications' in txt(cv),
    '6:  cv shows five pubs':           txt(cv).count('21 peer-reviewed') == 1,
    '7:  cv has 29 chips':              sum(l.count('<li>') for l in re.findall(r'<ul class="cv-chips">(.*?)</ul>', cv, re.S)) == 29,
    '8:  research has 26 list items':   res.count('class="list__item"') == 26,
    '8:  research has 7 year groups':   len(re.findall(r'archive__year"', res)) == 7,
    '8:  research has zero cards':      res.count('class="card"') == 0,
    '10: no new colours':               all(c in css for c in ['#faf8f3', '#8a6508', '#b8860b', '#f6e9c4', '#7a5b06', '#1a1913']),
}
for k, v in sorted(checks.items()):
    print(('PASS' if v else 'FAIL'), '-', k)
if stale:
    print('STALE FILES:', stale)
sys.exit(0 if all(checks.values()) else 1)
PY
```

Expected: all `PASS`, exit 0.

- [ ] **Step 3: Check every internal link, both forms**

GitHub Pages serves extensionless URLs, and this theme emits absolute `https://prathmeshrmadhu.github.io/...` links as well as root-relative ones. A checker that tests only one form tests almost nothing — this was a real miss during Phase 3.

```bash
python3 - <<'PY'
import re, glob, os, sys

pages = glob.glob('_site/**/*.html', recursive=True)

def resolves(path):
    p = path.lstrip('/')
    for cand in (os.path.join('_site', p),
                 os.path.join('_site', p, 'index.html'),
                 os.path.join('_site', p + '.html')):
        if os.path.isfile(cand):
            return True
    return p in ('', '/')

broken, n_root, n_abs = [], 0, 0
for f in pages:
    h = open(f).read()
    for href in re.findall(r'href="(/[^"#?]*)"', h):
        n_root += 1
        if not resolves(href):
            broken.append((f, href))
    for href in re.findall(r'href="https://prathmeshrmadhu\.github\.io([^"#?]*)"', h):
        n_abs += 1
        if not resolves(href):
            broken.append((f, href))

print(f'{len(pages)} pages, {n_root} root-relative + {n_abs} absolute internal links checked')
print(f'broken: {len(broken)}')
for f, h in broken[:20]:
    print('  ', f, '->', h)
sys.exit(0 if not broken else 1)
PY
```

Expected: `broken: 0`, exit 0.

- [ ] **Step 4: Report to the user and wait**

Summarise the commits and the verification results. The remaining judgement is aesthetic and belongs to the user — specifically whether the CV entry rhythm reads well and whether the blog cards look right at desktop and narrow widths.

**Do not push until the user confirms.**

- [ ] **Step 5: Push, only after confirmation**

Plain `git push` fails on this repo — it authenticates as the wrong GitHub account. Use:

```bash
GIT_SSH_COMMAND="ssh -F /dev/null -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -i $HOME/.ssh/id_ed25519_prathmesh_personal" git push origin master
```

- [ ] **Step 6: Confirm the live site rebuilt**

GitHub Pages takes 15–60 seconds. Poll rather than guessing:

```bash
for i in $(seq 1 40); do
  if curl -s https://prathmeshrmadhu.github.io/assets/css/main.css | grep -q 'cv-chips'; then
    echo "new build live after ~$((i*15))s"; break
  fi
  sleep 15
done
python3 -c "
import urllib.request as u, re
blog = u.urlopen('https://prathmeshrmadhu.github.io/blog/').read().decode()
cv   = u.urlopen('https://prathmeshrmadhu.github.io/cv/').read().decode()
print('live blog cards :', blog.count('class=\"card\"'), '(want 3 — the draft is not committed)')
print('live cardgrid   :', blog.count('class=\"cardgrid\"'), '(want 1)')
print('live cv chips   :', cv.count('cv-chips'), '(want 6)')
print('live cv h1 count:', len(re.findall(r'<h1', cv)), '(want 1)')
assert blog.count('class=\"card\"') == 3
print('PASS')
"
```

Expected: `PASS`, and exactly 3 cards live — the untracked draft cannot appear.

---

## Self-Review Notes

**Spec coverage.** Every spec decision maps to a task: decision 1–3 → Tasks 2 and 4; decision 4 → Task 3; decision 5 → Tasks 6, 7, 8; decision 6 → Task 9; decision 7 → Task 9 Step 1 (talks and teaching untouched, asserted in Step 2); decision 8 → Task 2. The shared-colour hoist → Task 1. The kramdown finding is exercised by Tasks 7, 8 and 9. All ten spec success criteria are asserted in Task 10 Step 2, numbered to match.

**Naming consistency.** `.cardgrid`, `.card`, `.card__eyebrow`, `.card__eyebrow--note`, `.card__title`, `.card__excerpt`, `.card__tags` are defined in Task 2 and used with identical spelling in Task 4 and in every assertion. `.cv-date`, `.cv-role`, `.cv-org`, `.cv-cat`, `.cv-chips`, `.cv-note` are defined in Task 6 and consumed in Tasks 7, 8 and 9. `$title-color`, `$chip-background` and `$chip-color` are declared in Task 1, before Tasks 2 and 6 use them.

**Known risk.** Task 9 changes which five publications appear, because it fixes `reversed` to a real date sort. That is intended, but it means the CV's publication list will not match its previous contents. Task 9 Step 2 asserts the five match the first five on `/research/` rather than hardcoding titles, so the check stays correct as publications are added.
