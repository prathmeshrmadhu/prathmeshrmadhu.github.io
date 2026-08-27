# Phase 4 — Dark Teal Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **This repo's owner has recorded a preference for inline execution, not subagents.** Honour it.

**Spec:** `docs/superpowers/specs/2026-08-24-dark-teal-redesign-design.md` — read it before starting. This plan implements it; where they disagree, the spec wins.

**Goal:** Replace the site's entire visual layer with the approved deep-teal (`#08302A`) / amber (`#F0A202`) design — Space Grotesk + JetBrains Mono, zero images, zero JavaScript — rebuilding all seven routes and all 36 detail pages on a written design system instead of Minimal Mistakes overrides.

**Architecture:** Strip Minimal Mistakes to its Jekyll plumbing (config, collections, `head/`, `seo.html`, `base_path`, analytics, feed) and delete its visual layer. Four layouts (`base`, `home`, `route`, `detail`) replace seven. Twelve hand-written Sass partials replace twenty-one theme partials plus three vendor libraries. Every number on the site derives from front matter except one hardcoded citation figure in `_config.yml`.

**Tech Stack:** Jekyll 3.10 (`github-pages` gem), kramdown, Liquid, Sass (`style: compressed`), self-hosted variable `woff2` fonts. No JS framework, no icon font, no SVG, no images. Docker for builds; there is no local Ruby.

---

## Before you start

**Build harness. Shell state does NOT persist between Bash calls — redefine these in every single call that needs them:**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
```

Run `jclean` before any assertion that something is **gone**. A stale `_site` will happily show you deleted output.

**Verification rules learned the hard way in earlier phases:**

- **Never use `grep -c`.** It counts matching *lines*. This theme emits single-line markup, so `grep -c` reports `1` for fifty matches. Use Python `str.count`.
- **Liquid's `for` tag ignores piped filters.** `{% for p in site.portfolio | sort: 'order' %}` silently does nothing. You must `{% assign %}` first, then loop over the assigned variable.
- **kramdown inline attribute lists** are `{: .class}` on the line *immediately* after the block, with no blank line between. Verified working in `_pages/cv.md`.
- **`_posts/2026-05-03-work-love.md` is an untracked draft with an empty `title`.** It is the newest post by date, so `limit: 3` on the homepage yields a **blank top row locally** and a different set than production. Local checks must tolerate this. **Do not modify or delete this file.**
- **Do not delete `images/safari-pinned-tab.svg` or `images/mstile-144x144.png`.** Provenance unresolved; out of scope.

**Push command.** Plain `git push` fails — it authenticates as the wrong account:

```bash
GIT_SSH_COMMAND="ssh -F /dev/null -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -i $HOME/.ssh/id_ed25519_prathmesh_personal" git push origin redesign
```

**Flag to raise at visual review, not to resolve here:** the spec's nav order includes `Contact` *and* the amber `Let's talk` pill, both pointing at `/contact/`. That is two links to one URL in one header. The plan implements the spec as approved; note it for the user rather than silently dropping one.

---

## File structure

### Created

| File | Responsibility |
| --- | --- |
| `scripts/fetch-fonts.sh` | Re-resolves and downloads the four `woff2` subsets. Google's URLs are version-hashed, so this must fetch the CSS and parse it, never hardcode |
| `assets/fonts/space-grotesk-latin.woff2` | Space Grotesk variable, latin subset |
| `assets/fonts/space-grotesk-latin-ext.woff2` | Space Grotesk variable, latin-ext subset |
| `assets/fonts/jetbrains-mono-latin.woff2` | JetBrains Mono variable, latin subset |
| `assets/fonts/jetbrains-mono-latin-ext.woff2` | JetBrains Mono variable, latin-ext subset |
| `assets/fonts/OFL-Space-Grotesk.txt` | Licence |
| `assets/fonts/OFL-JetBrains-Mono.txt` | Licence |
| `_layouts/base.html` | HTML shell. Declares `layout: compress` |
| `_layouts/home.html` | Homepage only. Composes the five designed sections |
| `_layouts/route.html` | The six inner routes. Page-title band + content |
| `_layouts/detail.html` | All 36 detail pages. Title band + prose body + chips |
| `_includes/site-header.html` | Wordmark, nav, CSS-only mobile toggle, `Let's talk` pill |
| `_includes/site-footer.html` | Name, location, links, copyright |
| `_includes/font-face.html` | *Not created* — `@font-face` lives in `_sass/_base.scss` so it ships inside `main.css` |
| `_includes/glyph.html` | Four CSS glyphs, selected by a `type` parameter |
| `_includes/metric-tile.html` | Amber number + mono caption |
| `_includes/capability-card.html` | Glyph + H3 + body |
| `_includes/row-list-item.html` | Mono date + title, with an optional metadata line |
| `_pages/home.html` | `permalink: /`, `layout: home` |
| `_pages/contact.md` | `permalink: /contact/` |
| `_sass/_tokens.scss` | Single source of truth for colour, type, space, radius, breakpoints |
| `_sass/_layout.scss` | Container, band rhythm, heading rows, kickers, chips, dividers |
| `_sass/_header.scss` | Header, wordmark, nav, pill, mobile menu |
| `_sass/_hero.scss` | Hero grid, amber glow, blueprint grid, metric tiles |
| `_sass/_prose.scss` | Long-form detail-page typography |

### Rewritten in place

| File | Change |
| --- | --- |
| `assets/css/main.scss` | New twelve-partial import list |
| `_sass/_base.scss` | `@font-face`, body, headings, links, focus, `prefers-reduced-motion` |
| `_sass/_cards.scss` | Card primitive + capability / work-feature / work-secondary / blog variants, rings |
| `_sass/_cv.scss` | Retargeted at the new tokens. **Class names unchanged**, so `cv.md` needs no edits |
| `_sass/_footer.scss` | New footer |
| `_sass/_syntax.scss` | Dark-ground code highlighting |
| `_sass/_print.scss` | Black-on-white inversion. A required deliverable, not housekeeping |
| `_sass/_reset.scss` | **Three lines patched only** — it is theme-neutral otherwise |
| `_includes/work-card.html` | Feature and secondary variants via a parameter |
| `_includes/blog-card.html` | Against the new card primitive |
| `_includes/scripts.html` | Reduced to `{% include analytics.html %}` |
| `_includes/head.html` | Drop the `no-js` script |
| `_includes/head/custom.html` | Drop academicons + MathJax; retheme `theme-color` |
| `_data/navigation.yml` | Six items in the spec's order |
| `_config.yml` | `defaults` (no `single`/`talk`/`author_profile`), `scholar_citations`, `exclude` |
| `_pages/about.md` | Demoted from `/` to `/about/`; "Where to go next" removed |
| `_pages/work.html`, `_pages/blog.html`, `_pages/research.html`, `_pages/cv.md`, `_pages/404.md` | `layout: route`, `author_profile` removed |

### Deleted

- `_layouts/`: `default.html`, `single.html`, `talk.html`, `archive.html`, `archive-taxonomy.html`, `splash.html`. **Keep `compress.html`** — it is live, referenced by `layout: compress`.
- `_includes/`: `author-profile.html`, `page__hero.html`, `page__taxonomy.html`, `masthead.html`, `sidebar.html`, `nav_list`, `tag-list.html`, `category-list.html`, `social-share.html`, `breadcrumbs.html`, `paginator.html`, `post_pagination.html`, `read-time.html`, `browser-upgrade.html`, `archive-single.html`, `archive-single-cv.html`, `archive-single-talk.html`, `archive-single-talk-cv.html`, `feature_row`, `gallery`, `toc`, `comment.html`, `comments.html`, `comments-providers/`, `footer.html`.
- `_sass/`: `_masthead.scss`, `_sidebar.scss`, `_archive.scss`, `_page.scss`, `_navigation.scss`, `_utilities.scss`, `_animations.scss`, `_buttons.scss`, `_notices.scss`, `_forms.scss`, `_tables.scss`, `_mixins.scss`, `_variables.scss`, `vendor/susy/`, `vendor/font-awesome/`, `vendor/magnific-popup/`, `vendor/breakpoint/`.
- `assets/js/` entirely — **316 KB on disk, 131 KB shipped on every page view.**
- `assets/css/academicons.css`, `assets/css/academicons.min.css`, `assets/css/collapse.css`.
- All nineteen icon-font files in `assets/fonts/` — **2.9 MB**: `academicons.{eot,svg,ttf,woff}`, `fa-brands-400.*`, `fa-regular-400.*`, `fa-solid-900.*`.

**Kept:** `_includes/head.html`, `head/custom.html`, `footer/custom.html`, `seo.html`, `analytics.html`, `analytics-providers/`, `base_path`, `group-by-array`, `_layouts/compress.html`.

---

## Task 1: Branch and baseline

Capture the numbers the success criteria are measured against, before anything changes.

**Files:**
- Create: `docs/superpowers/plans/baseline-2026-08-24.txt` (scratch record, committed for auditability)

- [ ] **Step 1: Confirm you are on `master` and the tree is clean**

```bash
cd /home/prathmesh/personal/prathmeshrmadhu.github.io
git status --short && git branch --show-current
```

Expected: `master`. The only untracked file should be `_posts/2026-05-03-work-love.md`. If anything else is dirty, **stop and ask** — do not stash someone else's work.

- [ ] **Step 2: Create the `redesign` branch**

```bash
git checkout -b redesign && git branch --show-current
```

Expected: `redesign`

This branch is mandatory. `master` is what GitHub Pages serves; a half-converted site — dark homepage, cream publication pages — would be publicly visible the instant it was pushed.

- [ ] **Step 3: Build the current site and record the baseline**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild
```

Expected: `done in N seconds.` with no errors.

- [ ] **Step 4: Write the baseline record**

```bash
python3 - <<'PY' > docs/superpowers/plans/baseline-2026-08-24.txt
import os, pathlib
root = pathlib.Path('_site')
pages = sorted(p for p in root.rglob('*.html'))
css = root / 'assets/css/main.css'
js = [p for p in root.rglob('*.js')]
print("BASELINE — master, before Phase 4")
print("html pages:", len(pages))
print("main.css bytes:", css.stat().st_size)
print("js files shipped:", len(js))
for p in js:
    print("  ", p.relative_to(root), p.stat().st_size)
print("source assets/js bytes:", sum(f.stat().st_size for f in pathlib.Path('assets/js').rglob('*') if f.is_file()))
print("source assets/fonts bytes:", sum(f.stat().st_size for f in pathlib.Path('assets/fonts').rglob('*') if f.is_file()))
PY
cat docs/superpowers/plans/baseline-2026-08-24.txt
```

Expected output — these are the figures the success criteria compare against:

```
BASELINE — master, before Phase 4
html pages: 53
main.css bytes: 102456
js files shipped: 2
   assets/js/main.min.js 131019
   assets/js/collapse.js 545
source assets/js bytes: 323...
source assets/fonts bytes: 2957652
```

If `html pages` is not 53 or `main.css bytes` is not 102456, **stop.** The spec's arithmetic is built on those two numbers and something has changed since it was written.

- [ ] **Step 5: Record the `/research/` intro prose character count**

Success criterion 16 asserts this survives within 5%. Measure it now, on the old build.

```bash
python3 - <<'PY'
import re, pathlib
html = pathlib.Path('_site/research/index.html').read_text()
body = html.split('<div class="archive">')[1].split('<div class="page__footer">')[0]
intro = body.split('Publications')[0]
text = re.sub(r'<[^>]+>', ' ', intro)
text = re.sub(r'\s+', ' ', text).strip()
print("intro chars:", len(text))
for probe in ["Concepts to Computational Constructs", "Odeuropa", "SniffyArt", "pulmonary hemosiderophages"]:
    print(f"  {probe!r}:", text.count(probe))
PY
```

Expected: a character count in the low thousands, and `1` for each of the four probes. Append the number to `docs/superpowers/plans/baseline-2026-08-24.txt` by hand.

Note the wrapper: **the archive layout's outer div is `class="archive"`, NOT `page__content`.** A previous plan got this wrong and the assertion silently passed on an empty string.

- [ ] **Step 6: Commit the baseline**

```bash
git add docs/superpowers/plans/2026-08-24-dark-teal-redesign.md docs/superpowers/plans/baseline-2026-08-24.txt
git commit -m "docs: add Phase 4 redesign plan and pre-change baseline metrics"
```

---

## Task 2: Self-host the two font families

Google's Fonts CSS API serves version-hashed subset URLs (`v22`, `v24`, …), so a script that hardcodes URLs rots. `scripts/fetch-fonts.sh` re-resolves them every run. This is the one script the repo gains; it earns its place because font updates must be reproducible.

**Files:**
- Create: `scripts/fetch-fonts.sh`
- Create: `assets/fonts/space-grotesk-latin.woff2`, `assets/fonts/space-grotesk-latin-ext.woff2`, `assets/fonts/jetbrains-mono-latin.woff2`, `assets/fonts/jetbrains-mono-latin-ext.woff2`
- Create: `assets/fonts/OFL-Space-Grotesk.txt`, `assets/fonts/OFL-JetBrains-Mono.txt`
- Modify: `_config.yml` (add `scripts` to `exclude`)

- [ ] **Step 1: Write the fetch script**

```bash
mkdir -p scripts assets/fonts
```

Create `scripts/fetch-fonts.sh`:

```bash
#!/usr/bin/env bash
# Re-resolve and download the self-hosted font subsets.
#
# Google's Fonts CSS API serves version-hashed woff2 URLs (v22, v24, ...), so this
# script must fetch and parse the CSS rather than hardcode download links.
# A browser User-Agent is required — Google serves TTF to unknown agents.
#
# Usage: bash scripts/fetch-fonts.sh
set -euo pipefail
cd "$(dirname "$0")/.."

UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'

fetch_family () {
  local slug="$1" query="$2"
  local css
  css="$(curl -sS -A "$UA" "https://fonts.googleapis.com/css2?family=${query}&display=swap")"
  # `python3 -` reads the program from stdin (the heredoc) and still takes argv,
  # so the CSS travels as an argument. Do NOT pipe the CSS in: a heredoc claims
  # stdin, and the pipe would be silently discarded.
  python3 - "$slug" "$css" <<'PY'
import re, subprocess, sys
slug, css = sys.argv[1], sys.argv[2]
# One @font-face block per unicode subset. Pick the two we ship.
wanted = {"U+0000-00FF": "latin", "U+0100-02BA": "latin-ext"}
found = {}
for block in re.findall(r"@font-face\s*\{(.*?)\}", css, re.S):
    rng = re.search(r"unicode-range:\s*([^;]+);", block)
    url = re.search(r"url\((https://[^)]+\.woff2)\)", block)
    if not rng or not url:
        continue
    first = rng.group(1).split(",")[0].strip()
    if first in wanted:
        found[wanted[first]] = url.group(1)
for subset, url in sorted(found.items()):
    out = f"assets/fonts/{slug}-{subset}.woff2"
    subprocess.run(["curl", "-sS", "-o", out, url], check=True)
    print(f"  {out}  <-  {url}")
missing = set(wanted.values()) - set(found)
if missing:
    sys.exit(f"ERROR: subsets not found for {slug}: {sorted(missing)}")
PY
}

echo "Space Grotesk:"
fetch_family space-grotesk 'Space+Grotesk:wght@300..700'
echo "JetBrains Mono:"
fetch_family jetbrains-mono 'JetBrains+Mono:wght@400..700'

echo "Licences:"
curl -sS -o assets/fonts/OFL-Space-Grotesk.txt \
  https://raw.githubusercontent.com/floriankarsten/space-grotesk/master/OFL.txt
curl -sS -o assets/fonts/OFL-JetBrains-Mono.txt \
  https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/OFL.txt
echo "  assets/fonts/OFL-Space-Grotesk.txt"
echo "  assets/fonts/OFL-JetBrains-Mono.txt"
```

- [ ] **Step 2: Run it**

```bash
bash scripts/fetch-fonts.sh
```

Expected: four `assets/fonts/*.woff2` lines and two licence lines, no `ERROR:`.

- [ ] **Step 3: Verify the four files, by size**

Use `stat`, not `ls | awk` — the column offsets in `ls -la` shift and you will print timestamps instead of filenames.

```bash
for f in assets/fonts/space-grotesk-latin.woff2 assets/fonts/space-grotesk-latin-ext.woff2 \
         assets/fonts/jetbrains-mono-latin.woff2 assets/fonts/jetbrains-mono-latin-ext.woff2 \
         assets/fonts/OFL-Space-Grotesk.txt assets/fonts/OFL-JetBrains-Mono.txt; do
  printf '%8d  %s\n' "$(stat -c%s "$f")" "$f"
done
```

Expected: the four `woff2` files total roughly **82 KB** (approximately 21.8 KB, 18.5 KB, 30.7 KB, 11.4 KB — subset contents shift slightly between font releases, so treat these as approximate). Both licence files should be several kilobytes of text, not an HTML error page. If a licence file starts with `<`, the raw URL moved; find the current one rather than committing an error page.

- [ ] **Step 4: Exclude `scripts/` from the build**

In `_config.yml`, inside the `exclude:` list, add one entry in alphabetical position between `package.json` and `tmp`:

```yaml
  - package.json
  - scripts
  - tmp
```

- [ ] **Step 5: Commit**

```bash
git add scripts/fetch-fonts.sh assets/fonts/space-grotesk-latin.woff2 \
  assets/fonts/space-grotesk-latin-ext.woff2 assets/fonts/jetbrains-mono-latin.woff2 \
  assets/fonts/jetbrains-mono-latin-ext.woff2 assets/fonts/OFL-Space-Grotesk.txt \
  assets/fonts/OFL-JetBrains-Mono.txt _config.yml
git commit -m "feat: self-host Space Grotesk and JetBrains Mono subsets

Removes a third-party request from every page load. Fetch script
re-resolves Google's version-hashed URLs rather than hardcoding them."
```

---

## Task 3: Design tokens

One file, no rules — just variables. Every later partial reads from here. Two colour hues exist and no third may be added: everything that is not `$ground` or `$accent` is `#F4F2ED` at an alpha.

**Files:**
- Create: `_sass/_tokens.scss`

- [ ] **Step 1: Write `_sass/_tokens.scss`**

```scss
// ---------------------------------------------------------------------------
// Design tokens — single source of truth.
//
// Two hues only: $ground and $accent. Everything else is $ink at an alpha.
// Do not add a third hue.
//
// Contrast note: $ink-52 is the WCAG AA floor on $ground (measured 4.54:1).
// The source design specified 0.40 for eyebrows and 0.42 for dates; both fail
// AA (3.28 and 3.47). They are collapsed into $ink-52 here. Do not lower it.
// ---------------------------------------------------------------------------

// Colour
$ground:        #08302A;
$ink:           #F4F2ED;
$accent:        #F0A202;

$ink-72:        rgba(244, 242, 237, 0.72);  // hero pill
$ink-70:        rgba(244, 242, 237, 0.70);  // lede
$ink-68:        rgba(244, 242, 237, 0.68);  // feature card body
$ink-64:        rgba(244, 242, 237, 0.64);  // chip label
$ink-62:        rgba(244, 242, 237, 0.62);  // nav items
$ink-60:        rgba(244, 242, 237, 0.60);  // card body
$ink-55:        rgba(244, 242, 237, 0.55);  // metric captions
$ink-52:        rgba(244, 242, 237, 0.52);  // dates, eyebrows — AA floor

$line:          rgba(244, 242, 237, 0.13);  // card borders
$line-strong:   rgba(244, 242, 237, 0.20);  // hero pill border
$line-hover:    rgba(244, 242, 237, 0.28);  // card border on hover
$line-ring:     rgba(244, 242, 237, 0.17);  // feature card decorative rings
$line-soft:     rgba(244, 242, 237, 0.10);  // band dividers
$surface:       rgba(244, 242, 237, 0.05);  // metric tile fill
$surface-hover: rgba(244, 242, 237, 0.03);  // card tint on hover
$chip:          rgba(244, 242, 237, 0.08);  // chip fill
$glyph-mute:    rgba(244, 242, 237, 0.25);  // inactive glyph segments
$grid-line:     rgba(244, 242, 237, 0.04);  // hero blueprint grid

// Consumed by the retained _reset.scss. Do not rename.
$background-color: $ground;
$link-color:       $accent;

// Type
$sans: "Space Grotesk", system-ui, -apple-system, "Segoe UI", Arial, sans-serif;
$mono: "JetBrains Mono", ui-monospace, "SF Mono", Menlo, Consolas, monospace;

// Space
$container: 1180px;
$inset:     52px;   // horizontal page inset, desktop
$inset-sm:  20px;   // horizontal page inset, mobile
$band:      56px;   // vertical band rhythm, desktop
$band-sm:   32px;   // vertical band rhythm, mobile
$measure:   680px;  // long-form prose measure

// Radius. No shadows anywhere — depth comes from alpha surfaces and 1px borders.
$r-metric: 12px;
$r-card:   14px;
$r-work:   16px;
$r-pill:   22px;

// Breakpoints.
// Phase 3 inherited a $medium defined twice in the theme's _variables.scss, and
// the non-!default declaration won at 500px — which is why the old card grids
// went two-up on a large phone. These are the only breakpoints now.
$bp-md: 768px;
$bp-lg: 1024px;

// Transitions
$t-color: color 150ms ease;
$t-lift:  160ms ease;
$t-card:  180ms ease;
```

- [ ] **Step 2: Verify it compiles standalone**

Nothing imports it yet, so prove the syntax before building the site on it.

```bash
docker run --rm -v "$PWD":/w -w /w ruby:3.2 bash -c \
  "gem install sass --no-document --silent >/dev/null 2>&1; sass --style compressed _sass/_tokens.scss 2>&1 | tail -5"
```

Expected: no output, or only a deprecation notice. Any `Error:` line means a syntax mistake — fix it before moving on.

- [ ] **Step 3: Commit**

```bash
git add _sass/_tokens.scss
git commit -m "feat: add design tokens for the dark teal palette

Collapses the source design's 0.40/0.42 muted greys into a single
\$ink-52, the measured WCAG AA floor on #08302A."
```

---

## Task 4: The layout shell

This task replaces the page chrome and gets a compiling, if unfinished, site. After it, the header and footer are the new design and the old theme CSS is gone. Inner-page content will look unstyled until later tasks — that is expected.

**Files:**
- Create: `_layouts/base.html`, `_includes/site-header.html`, `_includes/site-footer.html`
- Create: `_sass/_layout.scss`, `_sass/_header.scss`
- Rewrite: `_sass/_base.scss`, `_sass/_footer.scss`, `assets/css/main.scss`
- Modify: `_sass/_reset.scss` (three lines), `_data/navigation.yml`

- [ ] **Step 1: Patch the three external dependencies out of `_sass/_reset.scss`**

`_reset.scss` is 178 lines and theme-neutral apart from **five** references. Patching them lets `vendor/breakpoint/`, `vendor/susy/` and `_mixins.scss` be deleted.

**Correction, found during execution:** an earlier draft of this task said "exactly three references, verified by dependency scan." That was wrong, and the scan in Step 2 is why — it matches only `$variables`, so it reports a clean `unknown: []` while `@include` and `@extend` dependencies sit untouched. There are five, not three. Two of them break compilation.

1. Line 5 — `@include border-box-sizing;` resolves to `vendor/susy/susy/language/susy/_box-sizing.scss`. Inline it:

```scss
/* Inlined from susy's border-box-sizing mixin; vendor/susy is being deleted. */
*,
*::before,
*::after {
  box-sizing: border-box;
}
```

2. Line 13 opens a breakpoint block. Replace `@include breakpoint($medium) {` with:

```scss
  @media (min-width: $bp-md) {
```

3. Line 76 — `a:focus { @extend %tab-focus; }` resolves to `_mixins.scss`, which itself references `$warning-color`, making this a transitive third dependency. **Delete the rule**, do not inline it: `%tab-focus` emits a grey dotted outline on `:focus` (not `:focus-visible`), which fires on mouse click and fights the amber `:focus-visible` ring that `_base.scss` establishes. Replace with a comment:

```scss
/* Focus state is owned by _base.scss (:focus-visible, amber ring). The theme's
   %tab-focus placeholder lived in _mixins.scss and pulled in a warning-colour
   variable; both are being deleted. */
```

4. `$background-color` (line 10) and `$link-color` (line 70) need no edit — `_tokens.scss` defines both names deliberately.

The `a:hover, a:active { outline: 0 }` rule further down is **not** a focus suppression — it omits `:focus`, so the amber ring survives. Leave it.

- [ ] **Step 2: Verify no other theme variable leaks into the reset**

A variable-only scan is not enough — it cannot see `@include` or `@extend`. Check all three kinds:

```bash
python3 - <<'PY'
import re, pathlib
src = pathlib.Path('_sass/_reset.scss').read_text()
known = {'$background-color', '$link-color', '$bp-md'}
found = set(re.findall(r'\$[a-z0-9-]+', src))
print("variables used:", sorted(found))
print("unknown vars:", sorted(found - known))
print("@include calls left:", re.findall(r'@include\s+([\w-]+)', src))
print("@extend calls left:", re.findall(r'@extend\s+([%.\w-]+)', src))
PY
```

Expected:

```
variables used: ['$background-color', '$bp-md', '$link-color']
unknown vars: []
@include calls left: []
@extend calls left: []
```

If `unknown vars` is non-empty, add those variables to `_tokens.scss` or inline their values. If either mixin list is non-empty, resolve where it comes from and inline or delete it. **Do not resurrect `_variables.scss` or `_mixins.scss`** — every file they live in is deleted in Task 18, so a surviving reference is a build failure deferred, not avoided.

- [ ] **Step 3: Write `_sass/_base.scss`**

Full replacement of the file.

```scss
// ---------------------------------------------------------------------------
// Base — @font-face, document defaults, links, focus, motion.
// ---------------------------------------------------------------------------

// Variable fonts: one file per subset covers every weight in the range.
@font-face {
  font-family: "Space Grotesk";
  font-style: normal;
  font-weight: 300 700;
  font-display: swap;
  src: url("/assets/fonts/space-grotesk-latin.woff2") format("woff2");
  unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA,
    U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193,
    U+2212, U+2215, U+FEFF, U+FFFD;
}
@font-face {
  font-family: "Space Grotesk";
  font-style: normal;
  font-weight: 300 700;
  font-display: swap;
  src: url("/assets/fonts/space-grotesk-latin-ext.woff2") format("woff2");
  unicode-range: U+0100-02BA, U+02BD-02C5, U+02C7-02CC, U+02CE-02D7, U+02DD-02FF,
    U+0304, U+0308, U+0329, U+1D00-1DBF, U+1E00-1E9F, U+1EF2-1EFF, U+2020,
    U+20A0-20AB, U+20AD-20C0, U+2113, U+2C60-2C7F, U+A720-A7FF;
}
@font-face {
  font-family: "JetBrains Mono";
  font-style: normal;
  font-weight: 400 700;
  font-display: swap;
  src: url("/assets/fonts/jetbrains-mono-latin.woff2") format("woff2");
  unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA,
    U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193,
    U+2212, U+2215, U+FEFF, U+FFFD;
}
@font-face {
  font-family: "JetBrains Mono";
  font-style: normal;
  font-weight: 400 700;
  font-display: swap;
  src: url("/assets/fonts/jetbrains-mono-latin-ext.woff2") format("woff2");
  unicode-range: U+0100-02BA, U+02BD-02C5, U+02C7-02CC, U+02CE-02D7, U+02DD-02FF,
    U+0304, U+0308, U+0329, U+1D00-1DBF, U+1E00-1E9F, U+1EF2-1EFF, U+2020,
    U+20A0-20AB, U+20AD-20C0, U+2113, U+2C60-2C7F, U+A720-A7FF;
}

html {
  -webkit-text-size-adjust: 100%;
}

body {
  margin: 0;
  background: $ground;
  color: $ink;
  font-family: $sans;
  font-size: 16px;
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

h1, h2, h3, h4 {
  margin: 0;
  font-family: $sans;
  font-weight: 600;
  letter-spacing: -0.02em;
  text-wrap: balance;
}

p { text-wrap: pretty; }

a {
  color: $accent;
  text-decoration: none;
  transition: $t-color;

  &:hover { color: $ink; }
}

// Focus is never suppressed without replacement.
:focus-visible {
  outline: 2px solid $accent;
  outline-offset: 3px;
}

// Skip link for keyboard users, since the header comes before the content.
.skip-link {
  position: absolute;
  left: -9999px;
  z-index: 10;
  padding: 10px 16px;
  background: $accent;
  color: $ground;
  font: 600 13px/1 $sans;

  &:focus {
    left: $inset-sm;
    top: 10px;
  }
}

.u-sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  margin: -1px;
  padding: 0;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

// Drop the transforms, keep the colour transitions. Do not blanket-disable
// every transition here — the design relies on colour feedback for hover.
@media (prefers-reduced-motion: reduce) {
  .pill:hover,
  .btn:hover,
  .card:hover {
    transform: none;
  }
  * {
    animation: none !important;
  }
}
```

- [ ] **Step 4: Write `_sass/_layout.scss`**

```scss
// ---------------------------------------------------------------------------
// Layout — container, band rhythm, heading rows, and the shared small
// primitives (kicker, chip) that several components reuse.
// ---------------------------------------------------------------------------

.band {
  padding: $band $inset;

  &--divided { border-top: 1px solid $line-soft; }
  &--tight   { padding-top: 0; }
}

.band__inner {
  max-width: $container;
  margin: 0 auto;
}

// H2 + mono eyebrow, baseline-aligned.
.heading-row {
  display: flex;
  align-items: baseline;
  gap: 14px;
  margin-bottom: 30px;

  // H2 + amber link pushed to the far edge.
  &--split {
    justify-content: space-between;
    margin-bottom: 26px;
  }
}

.heading-row__title {
  margin: 0;
  font: 600 26px/1 $sans;
  letter-spacing: -0.02em;
}

.heading-row__eyebrow {
  font: 400 12px/1 $mono;
  color: $ink-52;
}

.heading-row__link {
  font: 500 12px/1 $mono;
  color: $accent;
  white-space: nowrap;
}

// Kicker — mono, tracked out, uppercased in CSS so front matter keeps its case.
.kicker {
  margin: 0 0 16px;
  font: 500 11px/1 $mono;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: $accent;
}

// Chips — tag pills.
.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 7px;
  margin: 22px 0 0;
  padding: 0;
  list-style: none;
}

.chips li {
  padding: 6px 10px;
  background: $chip;
  border-radius: $r-card;
  font: 500 11px/1 $mono;
  color: $ink-64;
}

// Page-title band used by route.html and detail.html.
.page-title {
  padding: 52px $inset $band;
}

.page-title__inner {
  max-width: $container;
  margin: 0 auto;
}

.page-title__h1 {
  margin: 0;
  font: 700 42px/1.05 $sans;
  letter-spacing: -0.03em;
}

.page-title__lede {
  max-width: $measure;
  margin: 18px 0 0;
  font: 400 16.5px/1.65 $sans;
  color: $ink-70;
}
```

- [ ] **Step 5: Write `_sass/_header.scss`**

The mobile toggle is a checkbox, not JavaScript. A `<details>` element would be more semantic, but modern browsers hide `::details-content` with `content-visibility`, which author CSS cannot reliably force open for the desktop layout. The checkbox is focusable and space-togglable, and the label carries a screen-reader name.

```scss
// ---------------------------------------------------------------------------
// Header — wordmark, nav, CTA pill, CSS-only mobile menu.
// ---------------------------------------------------------------------------

.site-header__inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  max-width: $container;
  margin: 0 auto;
  padding: 20px $inset;
}

// Wordmark: square-in-square, drawn in CSS. No image.
.wordmark {
  display: inline-flex;
  align-items: center;
  gap: 11px;
  color: $ink;

  &:hover { color: $ink; }
  &:hover .wordmark__mark::after { background: $ink; }
}

.wordmark__mark {
  position: relative;
  width: 18px;
  height: 18px;
  border: 1.5px solid $accent;
  flex: none;

  &::after {
    content: "";
    position: absolute;
    inset: 4px;
    background: $accent;
    transition: background 150ms ease;
  }
}

.wordmark__text {
  font: 600 13.5px/1 $sans;
  letter-spacing: 0.01em;
}

.nav {
  display: flex;
  align-items: center;
  gap: 26px;
}

.nav__list {
  display: flex;
  align-items: center;
  gap: 26px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.nav__link {
  font: 500 12px/1 $mono;
  color: $ink-62;
  transition: $t-color;

  &:hover { color: $ink; }

  &[aria-current="page"] { color: $ink; }
}

.pill {
  padding: 8px 13px;
  background: $accent;
  color: $ground;
  border-radius: 20px;
  font: 500 12px/1 $mono;
  white-space: nowrap;
  transition: transform $t-lift, filter $t-lift;

  &:hover {
    color: $ground;
    transform: translateY(-1px);
    filter: brightness(1.08);
  }
}

// --- Mobile menu ---------------------------------------------------------

.nav__toggle {
  position: absolute;
  opacity: 0;
  width: 44px;
  height: 44px;
  margin: 0;
}

.nav__burger {
  display: none;
  width: 44px;
  height: 44px;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.nav__burger-bars,
.nav__burger-bars::before,
.nav__burger-bars::after {
  display: block;
  width: 20px;
  height: 1.5px;
  background: $ink;
}

.nav__burger-bars {
  position: relative;

  &::before,
  &::after {
    content: "";
    position: absolute;
    left: 0;
  }
  &::before { top: -6px; }
  &::after  { top: 6px; }
}

.nav__toggle:focus-visible + .nav__burger {
  outline: 2px solid $accent;
  outline-offset: 3px;
}

@media (max-width: $bp-md - 1px) {
  .site-header__inner {
    padding: 16px $inset-sm;
    flex-wrap: wrap;
  }

  .nav__burger { display: flex; }

  // The pill stays visible in the bar; only the link list collapses.
  .nav__list {
    display: none;
    flex-basis: 100%;
    flex-direction: column;
    align-items: flex-start;
    gap: 0;
    order: 3;
  }

  .nav__list li {
    width: 100%;
    border-top: 1px solid $line-soft;
  }

  .nav__link {
    display: block;
    padding: 14px 0;
    font-size: 13px;
  }

  .nav__toggle:checked ~ .nav__list { display: flex; }
}

@media (min-width: $bp-md) {
  .nav__toggle { display: none; }
}
```

- [ ] **Step 6: Write `_sass/_footer.scss`**

Full replacement.

```scss
// ---------------------------------------------------------------------------
// Footer.
// ---------------------------------------------------------------------------

.site-footer {
  border-top: 1px solid $line-soft;
  padding: 34px $inset 40px;
}

.site-footer__inner {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  justify-content: space-between;
  gap: 18px;
  max-width: $container;
  margin: 0 auto;
}

.site-footer__id {
  font: 500 13px/1.5 $sans;
  color: $ink-70;
}

.site-footer__where {
  display: block;
  font: 400 11px/1.5 $mono;
  color: $ink-52;
}

.site-footer__links {
  display: flex;
  flex-wrap: wrap;
  gap: 20px;
  margin: 0;
  padding: 0;
  list-style: none;
  font: 400 11px/1 $mono;
}

.site-footer__links a {
  color: $ink-62;

  &:hover { color: $ink; }
}

.site-footer__copyright {
  flex-basis: 100%;
  margin: 0;
  font: 400 11px/1.6 $mono;
  color: $ink-52;
}
```

- [ ] **Step 7: Write the new `assets/css/main.scss`**

Full replacement. The empty front matter block at the top is required — it is what makes Jekyll process the file.

```scss
---
---

// Dark teal design system. See docs/superpowers/specs/2026-08-24-dark-teal-redesign-design.md
@import "tokens";
@import "reset";
@import "base";
@import "layout";
@import "header";
@import "hero";
@import "cards";
@import "prose";
@import "cv";
@import "footer";
@import "syntax";
@import "print";
```

- [ ] **Step 8: Create placeholder partials so the import list resolves**

`_hero.scss`, `_prose.scss` are written in later tasks. `_cards.scss`, `_cv.scss`, `_syntax.scss`, `_print.scss` exist but hold Phase 3 code that references now-deleted variables. Empty them all now so the build compiles; later tasks fill them in.

```bash
for f in _sass/_hero.scss _sass/_prose.scss; do printf '// filled in a later task\n' > "$f"; done
for f in _sass/_cards.scss _sass/_cv.scss _sass/_syntax.scss _sass/_print.scss; do printf '// rewritten in a later task\n' > "$f"; done
ls -1 _sass/_hero.scss _sass/_prose.scss _sass/_cards.scss _sass/_cv.scss _sass/_syntax.scss _sass/_print.scss
```

Expected: all six paths listed.

- [ ] **Step 9: Write `_includes/site-header.html`**

```liquid
{% include base_path %}
<a class="skip-link" href="#content">Skip to content</a>
<header class="site-header">
  <div class="site-header__inner">
    <a class="wordmark" href="{{ base_path }}/">
      <span class="wordmark__mark" aria-hidden="true"></span>
      <span class="wordmark__text">P.R. MADHU</span>
    </a>

    <input class="nav__toggle" type="checkbox" id="nav-toggle">
    <label class="nav__burger" for="nav-toggle"><span class="u-sr-only">Menu</span><span class="nav__burger-bars" aria-hidden="true"></span></label>

    <nav class="nav" aria-label="Main">
      <ul class="nav__list">
        {% for item in site.data.navigation.main %}
          <li><a class="nav__link" href="{{ base_path }}{{ item.url }}"{% if page.url == item.url %} aria-current="page"{% endif %}>{{ item.title }}</a></li>
        {% endfor %}
      </ul>
      <a class="pill" href="{{ base_path }}/contact/">Let's talk</a>
    </nav>
  </div>
</header>
```

The `<input>` sits outside `<nav>` so the `~` sibling selector in `_header.scss` can reach `.nav__list`. It is inside `.site-header__inner`, which is the shared parent — check the markup order matches the selector if you change either.

The accessible name comes from the `<label>`'s visually hidden "Menu" text, not from `aria-label` on the input. A real label is more reliably announced, and it gives the checkbox a click target.

- [ ] **Step 10: Write `_includes/site-footer.html`**

```liquid
{% include base_path %}
<footer class="site-footer">
  <div class="site-footer__inner">
    <p class="site-footer__id">
      Prathmesh Madhu
      <span class="site-footer__where">Pune, India</span>
    </p>
    <ul class="site-footer__links">
      <li><a href="mailto:prathmesh@infocusp.com">Email</a></li>
      <li><a href="https://x.com/prathmeshmadhu">X</a></li>
      <li><a href="https://www.linkedin.com/in/prathmeshrmadhu/">LinkedIn</a></li>
      <li><a href="https://github.com/prathmeshrmadhu">GitHub</a></li>
      <li><a href="{% if site.atom_feed.path %}{{ site.atom_feed.path }}{% else %}{{ base_path }}/feed.xml{% endif %}">Feed</a></li>
    </ul>
    <p class="site-footer__copyright">&copy; {{ site.time | date: '%Y' }} Prathmesh Madhu. Built with Jekyll.</p>
  </div>
</footer>
```

The old `footer.html` emitted Font Awesome `<i class="fab fa-twitter-square">` icons and an AcademicPages attribution chain. Both go — text links only, no icon font.

- [ ] **Step 11: Write `_layouts/base.html`**

```liquid
---
layout: compress
---

<!doctype html>
<html lang="{{ site.locale | slice: 0,2 | default: 'en' }}">
  <head>
    {% include head.html %}
    {% include head/custom.html %}
  </head>

  <body>
    {% include site-header.html %}

    <main id="content" role="main">
      {{ content }}
    </main>

    {% include site-footer.html %}
    {% include footer/custom.html %}
    {% include scripts.html %}
  </body>
</html>
```

`layout: compress` is deliberate. `_layouts/compress.html` is **not** dead code — the old `default.html` declared it, and `compress_html:` is configured in `_config.yml`. Dropping it would silently un-minify every page.

- [ ] **Step 12: Update `_data/navigation.yml`**

Full replacement, in the spec's order.

```yaml
# Main navigation. Order is from the Phase 4 spec: Work, Research, Blog,
# About, CV, Contact. The amber "Let's talk" pill also points at /contact/.
main:
  - title: "Work"
    url: /work/

  - title: "Research"
    url: /research/

  - title: "Blog"
    url: /blog/

  - title: "About"
    url: /about/

  - title: "CV"
    url: /cv/

  - title: "Contact"
    url: /contact/
```

- [ ] **Step 13: Commit**

The site does not build yet — `_config.yml` still points every page at the deleted-in-spirit `single` layout, and `/about/` and `/contact/` do not exist. Task 5 closes that. Commit the shell now so the diff stays reviewable.

```bash
git add _layouts/base.html _includes/site-header.html _includes/site-footer.html \
  _sass/_tokens.scss _sass/_layout.scss _sass/_header.scss _sass/_base.scss \
  _sass/_footer.scss _sass/_reset.scss _sass/_hero.scss _sass/_prose.scss \
  _sass/_cards.scss _sass/_cv.scss _sass/_syntax.scss _sass/_print.scss \
  assets/css/main.scss _data/navigation.yml
git commit -m "feat: new layout shell, header, footer and sass foundation

Replaces the Minimal Mistakes masthead and footer with a written
design system. Site does not build until the route wiring lands."
```

---

## Task 5: Config and route wiring

Point every page at the new layouts, retire the sidebar defaults, create the two new routes, and demote `about.md`. At the end of this task the site builds and every URL resolves.

**Files:**
- Modify: `_config.yml` (`defaults`, `scholar_citations`, `exclude`)
- Modify: `_includes/head.html`, `_includes/head/custom.html`, `_includes/scripts.html`
- Create: `_layouts/route.html`, `_layouts/home.html`, `_layouts/detail.html`
- Create: `_pages/home.html`, `_pages/contact.md`
- Modify: `_pages/about.md`, `_pages/work.html`, `_pages/blog.html`, `_pages/research.html`, `_pages/cv.md`, `_pages/404.md`

- [ ] **Step 1: Rewrite the `defaults` block in `_config.yml`**

Replace the entire existing `defaults:` block — from the `defaults:` line down to the blank line before `# Sass/SCSS` — with this. Every `layout: single` and `layout: talk` becomes `layout: detail`, and **every `author_profile: true` is gone** because the sidebar no longer exists. `read_time`, `comments`, `share`, `related` all drove deleted includes.

```yaml
defaults:
  # _posts
  - scope:
      path: ""
      type: posts
    values:
      layout: detail
  # _pages
  - scope:
      path: ""
      type: pages
    values:
      layout: route
  # _teaching
  - scope:
      path: ""
      type: teaching
    values:
      layout: detail
  # _publications
  - scope:
      path: ""
      type: publications
    values:
      layout: detail
  # _portfolio
  - scope:
      path: ""
      type: portfolio
    values:
      layout: detail
  # _talks
  - scope:
      path: ""
      type: talks
    values:
      layout: detail
```

- [ ] **Step 2: Add `scholar_citations` to `_config.yml`**

This is the one number on the site that cannot be derived from the repo. Putting it in config means exactly one place to update it. Add it immediately after the `title:` line in the site settings block:

```yaml
scholar_citations           : "320+"
```

- [ ] **Step 3: Remove the three dead `exclude` entries from `_config.yml`**

`assets/js/` is deleted in Task 6, so these become meaningless. Delete these three lines from the `exclude:` list:

```yaml
  - assets/js/_main.js
  - assets/js/plugins
  - assets/js/vendor
```

- [ ] **Step 4: Verify the config parses and the values landed**

```bash
python3 - <<'PY'
import yaml, pathlib
cfg = yaml.safe_load(pathlib.Path('_config.yml').read_text())
layouts = {d['scope']['type']: d['values'].get('layout') for d in cfg['defaults']}
print("layouts:", layouts)
print("author_profile anywhere:", any('author_profile' in d['values'] for d in cfg['defaults']))
print("scholar_citations:", cfg.get('scholar_citations'))
print("assets/js in exclude:", [e for e in cfg['exclude'] if 'assets/js' in str(e)])
print("scripts in exclude:", 'scripts' in cfg['exclude'])
PY
```

Expected:

```
layouts: {'posts': 'detail', 'pages': 'route', 'teaching': 'detail', 'publications': 'detail', 'portfolio': 'detail', 'talks': 'detail'}
author_profile anywhere: False
scholar_citations: 320+
assets/js in exclude: []
scripts in exclude: True
```

- [ ] **Step 5: Clean up `_includes/head.html`**

Delete the `no-js` class-swapping `<script>` block — the site ships no JavaScript and nothing keys off a `js` class any more. Remove these four lines:

```liquid
<script>
  document.documentElement.className = document.documentElement.className.replace(/\bno-js\b/g, '') + ' js ';
</script>
```

Leave everything else in the file: `base_path`, `seo.html`, the feed link, the viewport metas, and the `main.css` link.

- [ ] **Step 6: Rewrite `_includes/head/custom.html`**

Full replacement. This drops the academicons stylesheet (a second icon font) and the MathJax CDN script — **verified: zero content files in `_posts`, `_publications`, `_portfolio`, `_talks`, `_teaching` or `_pages` use `$$` or `\(` math delimiters**, so MathJax was loading on all 53 pages for nothing. `theme-color` moves from the old cream to the new ground.

```liquid
{% include base_path %}

<!-- start custom head snippets -->

<link rel="mask-icon" href="{{ base_path }}/images/safari-pinned-tab.svg?v=M44lzPylqQ" color="#08302A">
<meta name="msapplication-TileColor" content="#08302A">
<meta name="msapplication-TileImage" content="{{ base_path }}/images/mstile-144x144.png?v=M44lzPylqQ">
<meta name="theme-color" content="#08302A">

<!-- end custom head snippets -->
```

- [ ] **Step 7: Reduce `_includes/scripts.html`**

Full replacement — one line. The `main.min.js` reference goes with the JavaScript, and `/comments-providers/scripts.html` goes with the comment system (`comments.provider` is already blank in `_config.yml`).

```liquid
{% include analytics.html %}
```

- [ ] **Step 8: Write `_layouts/route.html`**

The six inner routes. A page-title band, then whatever the page emits.

```liquid
---
layout: base
---

<div class="page-title">
  <div class="page-title__inner">
    <h1 class="page-title__h1">{{ page.title }}</h1>
    {% if page.lede %}<p class="page-title__lede">{{ page.lede }}</p>{% endif %}
  </div>
</div>

{{ content }}
```

- [ ] **Step 9: Write `_layouts/home.html` as a pass-through for now**

Tasks 7–10 fill in the five sections. For now it just needs to exist and render nothing but the shell.

```liquid
---
layout: base
---

{{ content }}
```

- [ ] **Step 10: Write `_layouts/detail.html`**

All 36 detail pages. Fleshed out in Task 16; this version renders correctly but plainly.

```liquid
---
layout: base
---

<article class="detail">
  <div class="page-title">
    <div class="page-title__inner">
      {% if page.venue %}<p class="kicker">{{ page.venue }}</p>{% endif %}
      <h1 class="page-title__h1">{{ page.title }}</h1>
    </div>
  </div>

  <div class="band band--tight">
    <div class="band__inner">
      <div class="prose">
        {{ content }}
      </div>
    </div>
  </div>
</article>
```

- [ ] **Step 11: Create `_pages/home.html`**

```liquid
---
layout: home
title: "Prathmesh Madhu"
permalink: /
excerpt: "Computer vision researcher and ML leader. Ten years across peer-reviewed research and production systems."
---
```

No body. `home.html` composes everything from collections.

- [ ] **Step 12: Demote `_pages/about.md`**

Change the front matter — `permalink` moves to `/about/` and **both `redirect_from` entries are removed**. Leaving them would make `about.md` claim `/about/` twice, and `redirect_from` pages silently win or lose depending on build order. Replace lines 1–9 with:

```yaml
---
permalink: /about/
title: "About"
excerpt: "Computer vision researcher and machine learning leader."
---
```

Then delete the "Where to go next" section — the heading and the two bullets. Remove exactly these five lines:

```markdown
## Where to go next

* **[Selected work](/work/)** — what I've built, and what it measurably did
* **[Research](/research/)** — publications, talks, and teaching

```

The new homepage does that job; keeping it duplicates navigation inside prose. Every other line of `about.md` stays verbatim — it is Phase 1 content and the source of the homepage H1 and lede.

- [ ] **Step 13: Create `_pages/contact.md`**

```markdown
---
permalink: /contact/
title: "Get in touch"
lede: "Working on something hard? Email is the fastest way to reach me."
excerpt: "Reach Prathmesh Madhu by email, X, or LinkedIn."
---

<div class="band band--tight">
  <div class="band__inner">
    <div class="invert">
      <h2 class="invert__title">Working on something hard?</h2>
      <p class="invert__body">Pune, India.</p>
      <a class="btn" href="mailto:prathmesh@infocusp.com">prathmesh@infocusp.com</a>
      <ul class="invert__links">
        <li><a href="https://x.com/prathmeshmadhu">X</a></li>
        <li><a href="https://www.linkedin.com/in/prathmeshrmadhu/">LinkedIn</a></li>
      </ul>
    </div>
  </div>
</div>
```

Contact is a `mailto:` link, not a form. A form would need loading and validation states designed, and a static site has nothing to post to. `.invert` and `.btn` are styled in Task 10.

- [ ] **Step 14: Retarget the four existing route pages**

For each of `_pages/work.html`, `_pages/blog.html`, `_pages/research.html`, `_pages/cv.md`: change `layout: archive` to `layout: route` and **delete the `author_profile: true` line**. Keep every `redirect_from` block and every `permalink` exactly as-is — those URLs are live.

Resulting front matter:

```yaml
# _pages/work.html
---
layout: route
title: "Selected Work"
permalink: /work/
redirect_from:
  - /portfolio/
---
```

```yaml
# _pages/blog.html
---
layout: route
permalink: /blog/
title: "Blog"
redirect_from:
  - /year-archive/
  - /wordpress/blog-posts/
---
```

```yaml
# _pages/research.html
---
layout: route
title: "Research"
permalink: /research/
redirect_from:
  - /publications/
  - /talks/
  - /teaching/
---
```

```yaml
# _pages/cv.md
---
layout: route
title: "CV"
permalink: /cv/
redirect_from:
  - /resume
---
```

`blog.html`'s title changes from `"Blog posts"` to `"Blog"` so the H1 matches the nav label — the Phase 2 label/URL agreement rule.

- [ ] **Step 15: Strip the Google fixurl script from `_pages/404.md`**

Success criterion 15 is zero JavaScript other than analytics, and this page loads `//linkhelp.clients.google.com/tbproxy/lh/wm/fixurl.js`. It also promises a search box that the deleted theme never rendered. Full replacement:

```markdown
---
title: "Page Not Found"
excerpt: "Page not found."
sitemap: false
permalink: /404.html
---

That page doesn't exist. Try [the homepage](/), [selected work](/work/), or [research](/research/).
```

- [ ] **Step 16: Build**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild
```

Expected: `done in N seconds.`

If it fails with `Could not find layout`, a collection default still points at a deleted layout — recheck Step 1. If it fails on a missing include, a page still calls one of the includes deleted in Task 18 (which hasn't run yet, so this should not happen).

- [ ] **Step 17: Verify the routes and the page count**

```bash
python3 - <<'PY'
import pathlib
root = pathlib.Path('_site')
pages = sorted(p.relative_to(root).as_posix() for p in root.rglob('*.html'))
print("html pages:", len(pages), "(expected 53)")
for r in ['index.html', 'work/index.html', 'research/index.html', 'blog/index.html',
          'about/index.html', 'cv/index.html', 'contact/index.html', '404.html']:
    print(f"  {r}:", "OK" if r in pages else "MISSING")
print("about.html redirect still present:", 'about.html' in pages, "(expected False)")
home = (root / 'index.html').read_text()
print("home uses new header:", 'wordmark__mark' in home)
print("masthead in home:", 'masthead' in home, "(expected False)")
print("fixurl anywhere:", any('fixurl' in p.read_text() for p in root.rglob('*.html')), "(expected False)")
PY
```

Expected: `html pages: 53`, all eight routes `OK`, `about.html redirect still present: False`, `home uses new header: True`, `masthead in home: False`, `fixurl anywhere: False`.

The arithmetic behind 53: `about.md` used to emit three pages (`/index.html` plus the `/about/` and `/about.html` redirects) and now emits one; the new `/` and `/contact/` replace the two retired redirects. Net zero. **Any number other than 53 means something was lost or duplicated — stop and find it.**

- [ ] **Step 18: Commit**

```bash
git add _config.yml _includes/head.html _includes/head/custom.html _includes/scripts.html \
  _layouts/route.html _layouts/home.html _layouts/detail.html \
  _pages/home.html _pages/contact.md _pages/about.md _pages/work.html \
  _pages/blog.html _pages/research.html _pages/cv.md _pages/404.md
git commit -m "feat: wire all routes to the new layouts

Retires the author sidebar defaults, demotes about.md from / to /about/,
adds /contact/, and drops the unused MathJax and Google fixurl scripts."
```

---

## Task 6: Delete the JavaScript and the icon fonts

The single largest shipping win in this phase, and it is not the CSS. `main.min.js` is **131 KB on every page view** and `assets/fonts/` holds **2.9 MB** of Font Awesome and academicons files.

**Files:**
- Delete: `assets/js/` (entire directory, 316 KB)
- Delete: `assets/css/academicons.css`, `assets/css/academicons.min.css`, `assets/css/collapse.css`
- Delete: nineteen icon-font files in `assets/fonts/`

- [ ] **Step 1: Prove nothing references what you are about to delete**

Cheaper than a failed build, and a failed build is the fallback safety net anyway.

```bash
python3 - <<'PY'
import pathlib, re
roots = ['_layouts', '_includes', '_pages', '_posts', '_portfolio', '_publications',
         '_talks', '_teaching', '_sass', '_data', 'assets/css']
needles = ['main.min.js', 'collapse.js', 'collapse.css', 'academicons',
           'jquery', 'magnific', 'greedy', 'fitvids', 'stickyfill', 'smooth-scroll',
           'fa-brands', 'fa-solid', 'fa-regular']
hits = {}
for r in roots:
    for f in pathlib.Path(r).rglob('*'):
        if not f.is_file() or f.suffix not in {'.html', '.md', '.scss', '.yml', '.css'}:
            continue
        if 'vendor' in f.parts:   # theme vendor sass, deleted in task 18
            continue
        text = f.read_text(errors='ignore')
        for n in needles:
            if n in text:
                hits.setdefault(n, []).append(f.as_posix())
for n in needles:
    print(f"{n}: {hits.get(n, [])}")
PY
```

Expected: every line empty (`[]`). If `academicons` still shows `_includes/head/custom.html`, Task 5 Step 6 was not applied — go back and apply it.

- [ ] **Step 2: Confirm no content needs the five jQuery plugins**

Each plugin serves a feature this design does not have. Verify by content, not by assumption.

```bash
python3 - <<'PY'
import pathlib
roots = ['_posts', '_portfolio', '_publications', '_talks', '_teaching', '_pages']
needles = ['<iframe', 'youtube', 'vimeo', 'gallery', 'feature_row', 'toc', '![']
hits = {n: [] for n in needles}
for r in roots:
    for f in pathlib.Path(r).rglob('*'):
        if f.is_file() and f.suffix in {'.md', '.html'}:
            t = f.read_text(errors='ignore')
            for n in needles:
                if n in t:
                    hits[n].append(f.as_posix())
for n, v in hits.items():
    print(f"{n!r}: {v}")
PY
```

Expected: all empty. `greedy-navigation` served the deleted masthead, `magnific-popup` served galleries, `fitvids` served embeds, `smooth-scroll` served a table of contents, `stickyfill` served the deleted sidebar. Nothing left needs any of them.

- [ ] **Step 3: Delete**

```bash
git rm -r --quiet assets/js
git rm --quiet assets/css/academicons.css assets/css/academicons.min.css assets/css/collapse.css
git rm --quiet assets/fonts/academicons.eot assets/fonts/academicons.svg \
  assets/fonts/academicons.ttf assets/fonts/academicons.woff \
  assets/fonts/fa-brands-400.eot assets/fonts/fa-brands-400.svg assets/fonts/fa-brands-400.ttf \
  assets/fonts/fa-brands-400.woff assets/fonts/fa-brands-400.woff2 \
  assets/fonts/fa-regular-400.eot assets/fonts/fa-regular-400.svg assets/fonts/fa-regular-400.ttf \
  assets/fonts/fa-regular-400.woff assets/fonts/fa-regular-400.woff2 \
  assets/fonts/fa-solid-900.eot assets/fonts/fa-solid-900.svg assets/fonts/fa-solid-900.ttf \
  assets/fonts/fa-solid-900.woff assets/fonts/fa-solid-900.woff2
ls -1 assets/ assets/css/ assets/fonts/
```

Expected: `assets/` contains `css` and `fonts` only (no `js`); `assets/css/` contains `main.scss` only; `assets/fonts/` contains exactly the four `woff2` files and two `OFL-*.txt` files.

- [ ] **Step 4: Clean-build and assert the site ships no JavaScript**

`jclean` is mandatory here. Without it, `_site` keeps the deleted files and this assertion passes on stale output.

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild
python3 - <<'PY'
import pathlib
root = pathlib.Path('_site')
js = sorted(p.relative_to(root).as_posix() for p in root.rglob('*.js'))
print("js files in _site:", js, "(expected [])")
print("assets/js exists:", (root / 'assets/js').exists(), "(expected False)")
fonts = sorted(p.name for p in (root / 'assets/fonts').iterdir())
print("fonts shipped:", fonts)
total = sum(p.stat().st_size for p in (root / 'assets/fonts').iterdir())
print("font bytes:", total, "(expected ~82000-100000)")
# Count only executable scripts. seo.html emits <script type="application/ld+json">
# structured data on every page — that is metadata, not a script request.
import re
execs = []
for p in root.rglob('*.html'):
    for tag in re.findall(r'<script[^>]*>', p.read_text(errors='ignore')):
        if 'application/ld+json' in tag:
            continue
        execs.append((p.relative_to(root).as_posix(), tag))
print("executable script tags:", len(execs), "(expected 1 per page)")
# Every executable script must be one of exactly two known, sanctioned kinds.
unexplained = []
for path, tag in execs:
    txt = (root / path).read_text(errors='ignore')
    if 'GoogleAnalyticsObject' in txt:      # analytics snippet
        continue
    if 'Redirecting&hellip;' in txt:        # jekyll-redirect-from stub
        continue
    unexplained.append((path, tag))
print("unexplained executable scripts:", len(unexplained), "(expected 0)")
for u in unexplained[:5]:
    print("  ", u)
PY
```

Expected: `js files in _site: []`, `assets/js exists: False`, six font files, roughly 93 KB, and **zero unexplained** executable scripts.

**Do not assert `count('<script') == 0`.** Three separate reasons, all verified against real build output:

1. `_includes/seo.html` emits a `<script type="application/ld+json">` structured-data block on every page. That is JSON-LD metadata a crawler reads, not JavaScript a browser executes, and it stays.
2. `_includes/scripts.html` still calls `analytics.html`, and `_config.yml` sets `analytics.provider: "google-universal"`, so every content page carries an inline Google Analytics snippet. The spec's criterion 15 is "zero JavaScript **other than analytics**", so this is compliant as written.
3. **Eight pages carry a `<script>location="..."</script>` redirect and no analytics at all.** These are `jekyll-redirect-from` stubs generated for the live `redirect_from` URLs — `resume.html`, `year-archive/`, `portfolio/`, `talks/`, `publications/`, `teaching/`, `wordpress/blog-posts/`, and `posts/2012/08/rip-banerjee-sir/`. Each is a `noindex` page whose entire body is a redirect, with a `<meta http-equiv="refresh">` fallback for no-JS clients. This is plugin output, not authored code, and it is the mechanism keeping those old URLs alive. Do not try to remove it.

**Open question for the user, raised during execution — do not resolve unilaterally.** That analytics snippet is worth killing outright:

- `analytics.google.tracking_id` in `_config.yml` is **empty**, so the emitted code is `ga('create', '', 'auto')` — it cannot collect anything.
- It still fetches `//www.google-analytics.com/analytics.js` on every page view, which is a third-party request the design otherwise has zero of.
- `analytics.js` is Universal Analytics, which Google **shut down in July 2023**. The product behind it no longer exists.

Setting `analytics.provider: false` in `_config.yml` would make the site literally zero-JavaScript and zero-third-party-request. It is a one-line change. Because it alters the owner's tracking configuration, ask before doing it; if they want analytics later, GA4 needs a different snippet anyway.

- [ ] **Step 5: Commit**

```bash
git add -u
git commit -m "perf: delete all JavaScript and both icon fonts

Removes 131KB of jQuery shipped on every page view, 2.9MB of Font
Awesome and academicons files, and three orphaned stylesheets. Every
plugin served a feature this design does not have; verified by
grepping all six content collections."
```

---

## Task 7: Homepage hero

The first of the five designed homepage sections: a factual pill, the H1, the lede, and a 2×2 metric grid over an amber radial glow and a blueprint grid.

**Files:**
- Create: `_includes/metric-tile.html`
- Rewrite: `_sass/_hero.scss`
- Modify: `_layouts/home.html`

- [ ] **Step 1: Write `_includes/metric-tile.html`**

```liquid
<div class="metric">
  <div class="metric__value">{{ include.value }}</div>
  <div class="metric__caption">{{ include.caption }}</div>
</div>
```

- [ ] **Step 2: Write `_sass/_hero.scss`**

```scss
// ---------------------------------------------------------------------------
// Hero — the amber glow, the blueprint grid, and the metric tiles.
// Both background layers are pure CSS gradients. No images anywhere.
// ---------------------------------------------------------------------------

.hero {
  position: relative;
  padding: 64px $inset 0;
  overflow: hidden;
}

// Amber radial wash, top-right.
.hero__glow {
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  height: 520px;
  background: radial-gradient(120% 90% at 82% 8%, rgba(240, 162, 2, 0.22) 0%, transparent 62%);
  pointer-events: none;
}

// Blueprint grid: two 1px gradients on a 44px tile.
.hero__grid {
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient($grid-line 1px, transparent 1px),
    linear-gradient(90deg, $grid-line 1px, transparent 1px);
  background-size: 44px 44px;
  pointer-events: none;
}

.hero__inner {
  position: relative;
  display: grid;
  grid-template-columns: 1.35fr 1fr;
  gap: 48px;
  align-items: end;
  max-width: $container;
  margin: 0 auto;
  padding-bottom: 52px;
}

.hero__pill {
  display: inline-flex;
  align-items: center;
  gap: 9px;
  margin-bottom: 28px;
  padding: 7px 13px;
  border: 1px solid $line-strong;
  border-radius: 20px;
  font: 500 11px/1 $mono;
  color: $ink-72;

  &::before {
    content: "";
    width: 6px;
    height: 6px;
    background: $accent;
    border-radius: 50%;
    flex: none;
  }
}

.hero__h1 {
  margin: 0;
  font: 700 64px/1 $sans;
  letter-spacing: -0.035em;
}

.hero__h1 em {
  font-style: normal;
  color: $accent;
}

.hero__lede {
  max-width: 480px;
  margin: 26px 0 0;
  font: 400 16.5px/1.65 $sans;
  color: $ink-70;
}

.hero__metrics {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.metric {
  padding: 22px;
  background: $surface;
  border: 1px solid rgba(244, 242, 237, 0.11);
  border-radius: $r-metric;
}

.metric__value {
  font: 700 40px/1 $sans;
  letter-spacing: -0.03em;
  color: $accent;
}

.metric__caption {
  margin-top: 8px;
  font: 400 11px/1.45 $mono;
  color: $ink-55;
}
```

- [ ] **Step 3: Add the hero to `_layouts/home.html`**

Replace the file. The pill copy is **not** the mockup's `OPEN TO COLLABORATION & ADVISORY` — that frames the site as a service offering, which is out of bounds. It is replaced with a factual statement, keeping the pill shape and the leading amber dot.

```liquid
---
layout: base
---

{% include base_path %}
{% assign pub_count = site.publications | size %}
{% capture cite_caption %}papers, {{ site.scholar_citations }} citations{% endcapture %}

<section class="hero">
  <div class="hero__glow" aria-hidden="true"></div>
  <div class="hero__grid" aria-hidden="true"></div>
  <div class="hero__inner">
    <div>
      <p class="hero__pill">SVP MACHINE LEARNING · INFOCUSP</p>
      <h1 class="hero__h1">Standard models<br>fail. <em>That's where<br>I start.</em></h1>
      <p class="hero__lede">Computer vision researcher and ML leader. Ten years across peer-reviewed research and production systems — non-standard imagery, scarce labels, tight compute, auditable outputs.</p>
    </div>
    <div class="hero__metrics">
      {% include metric-tile.html value="9×" caption="faster SLAM on edge" %}
      {% include metric-tile.html value="+20%" caption="F1 in production" %}
      {% include metric-tile.html value=pub_count caption=cite_caption %}
      {% include metric-tile.html value="750+" caption="stars on tf-cnnvis" %}
    </div>
  </div>
</section>

{{ content }}
```

The H1 and lede are kept verbatim from the design — they compress `about.md` lines 11 and 17, which are the user's own sentences. The `<em>` carries the amber second sentence.

Metric tile 3 is **derived**, not the mockup's hardcoded `27`. Google Scholar reports 27 papers but six are duplicates; `_publications` holds the true 21. Deriving it means `/`, `/research/` and `/cv/` can never disagree.

The caption goes through `{% capture %}` rather than being written inline as `caption="papers, 320+ citations"`. **Liquid `include` parameters cannot interpolate**, so an inline string would hardcode `320+` a second time — and success criterion 8 asserts that figure appears exactly **once** in source, in `_config.yml`. Capture it, pass the variable.

- [ ] **Step 4: Build and verify the hero**

```bash
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jbuild
python3 - <<'PY'
import pathlib
home = pathlib.Path('_site/index.html').read_text()
checks = {
    "H1 first clause": "Standard models" in home,
    "H1 amber clause": "That&#39;s where" in home or "That's where" in home,
    "factual pill": "SVP MACHINE LEARNING" in home,
    "mockup pill gone": "OPEN TO COLLABORATION" not in home,
    "derived pub count 21": ">21</div>" in home,
    "hardcoded 27 absent": ">27</div>" not in home,
    "citations figure": "320+ citations" in home,
    "glow layer": 'class="hero__glow"' in home,
    "grid layer": 'class="hero__grid"' in home,
    "four metric tiles": home.count('class="metric"') == 4,
    "no images": '<img' not in home,
}
for k, v in checks.items():
    print(("PASS " if v else "FAIL ") + k)
PY
```

Expected: every line `PASS`. If `derived pub count 21` fails, print `pub_count` in the layout to see what Liquid computed — `site.publications | size` needs the collection to have `output: true`, which it does.

- [ ] **Step 5: Commit**

```bash
git add _includes/metric-tile.html _sass/_hero.scss _layouts/home.html
git commit -m "feat: homepage hero with CSS-only glow and blueprint grid

Publication count is derived from the collection rather than hardcoded,
so /, /research/ and /cv/ cannot disagree. Hero pill replaces the
mockup's collaboration solicitation with a factual role statement."
```

---

## Task 8: Capability cards and the four CSS glyphs

Homepage section 3. Four cards, each with a glyph drawn entirely in CSS — no images, no SVG, no icon font.

**Files:**
- Create: `_includes/glyph.html`, `_includes/capability-card.html`
- Modify: `_sass/_cards.scss` (first real content)
- Modify: `_layouts/home.html`

- [ ] **Step 1: Write `_includes/glyph.html`**

Four shapes, selected by `type`. Each is a `<span>` tree that CSS paints; markup carries no geometry.

```liquid
{% case include.type %}
  {% when 'bars' %}
    <span class="glyph glyph--bars" aria-hidden="true"><i></i><i></i><i></i></span>
  {% when 'target' %}
    <span class="glyph glyph--target" aria-hidden="true"></span>
  {% when 'matrix' %}
    <span class="glyph glyph--matrix" aria-hidden="true"><i></i><i></i><i></i><i></i><i></i><i></i></span>
  {% when 'dial' %}
    <span class="glyph glyph--dial" aria-hidden="true"></span>
{% endcase %}
```

- [ ] **Step 2: Write `_includes/capability-card.html`**

```liquid
<article class="card card--capability{% if include.lit %} card--lit{% endif %}">
  {% include glyph.html type=include.glyph %}
  <h3 class="card__title">{{ include.title }}</h3>
  <p class="card__body">{{ include.body }}</p>
</article>
```

- [ ] **Step 3: Write `_sass/_cards.scss`**

Full replacement of the placeholder. This is the card primitive plus the capability variant and all four glyphs; the work and blog variants are appended in Tasks 9 and 12.

```scss
// ---------------------------------------------------------------------------
// Cards — one primitive, several variants. No shadows: depth is a 1px border
// over an alpha surface.
// ---------------------------------------------------------------------------

.card {
  position: relative;
  border: 1px solid $line;
  border-radius: $r-card;
  transition: border-color $t-card, background-color $t-card;
}

// Whole card is the click target where it wraps a link.
.card--link:hover {
  border-color: $line-hover;
  background-color: $surface-hover;
}

.card__title {
  margin: 0;
  font: 600 17px/1.28 $sans;
}

.card__body {
  margin: 9px 0 0;
  font: 400 13px/1.6 $sans;
  color: $ink-60;
}

// --- Capability variant --------------------------------------------------

.card--capability {
  padding: 24px 22px 26px;
}

// The first card carries a soft amber wash so the row has an entry point.
.card--lit {
  background: linear-gradient(180deg, rgba(240, 162, 2, 0.09), transparent 70%);
}

.capability-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
}

// --- Glyphs: four shapes, pure CSS ---------------------------------------

.glyph {
  display: block;
  margin-bottom: 22px;
}

// Three vertical bars, first one lit.
.glyph--bars {
  display: flex;
  gap: 3px;

  i {
    width: 7px;
    height: 22px;
    background: $glyph-mute;
  }
  i:first-child { background: $accent; }
}

// Concentric circle with a filled centre.
.glyph--target {
  position: relative;
  width: 22px;
  height: 22px;
  border: 2px solid $accent;
  border-radius: 50%;

  &::after {
    content: "";
    position: absolute;
    left: 50%;
    top: 50%;
    transform: translate(-50%, -50%);
    width: 7px;
    height: 7px;
    background: $accent;
    border-radius: 50%;
  }
}

// Alternating 3x2 dot matrix.
.glyph--matrix {
  display: grid;
  grid-template-columns: repeat(3, 6px);
  gap: 4px;

  i {
    height: 6px;
    background: $glyph-mute;
  }
  i:nth-child(odd) { background: $accent; }
}

// Quarter dial.
.glyph--dial {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: conic-gradient($accent 0 25%, rgba(244, 242, 237, 0.22) 25% 100%);
}
```

- [ ] **Step 4: Add the capability section to `_layouts/home.html`**

Insert immediately after the closing `</section>` of the hero, before `{{ content }}`.

The H2 is `What I work on`, **not** the mockup's `What I can build for you`, and the eyebrow is `/ four recurring problems`, **not** `/ four practice areas`. Those words frame the site as a service offering. The four card bodies are kept verbatim — they are factual and accurate to real work.

```liquid
<section class="band band--divided">
  <div class="band__inner">
    <div class="heading-row">
      <h2 class="heading-row__title">What I work on</h2>
      <span class="heading-row__eyebrow">/ four recurring problems</span>
    </div>
    <div class="capability-grid">
      {% include capability-card.html glyph="bars" lit=true
         title="Vision on the edge"
         body="TensorRT pipelines and visual SLAM running in real time under strict power limits." %}
      {% include capability-card.html glyph="target"
         title="Auditable agentic systems"
         body="LLM-as-a-judge layers so every output can be audited rather than trusted." %}
      {% include capability-card.html glyph="matrix"
         title="Multimodal retrieval"
         body="Fusing vector-indexed image and text embeddings with keyword search." %}
      {% include capability-card.html glyph="dial"
         title="Scarce-label regimes"
         body="One-shot detection for tiny targets, imbalance and almost no labelled failures." %}
    </div>
  </div>
</section>
```

- [ ] **Step 5: Build and verify**

```bash
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jbuild
python3 - <<'PY'
import pathlib
home = pathlib.Path('_site/index.html').read_text()
css = pathlib.Path('_site/assets/css/main.css').read_text()
checks = {
    "four capability cards": home.count('card--capability') == 4,
    "one lit card": home.count('card--lit') == 1,
    "approved H2": "What I work on" in home,
    "mockup H2 gone": "What I can build for you" not in home,
    "approved eyebrow": "four recurring problems" in home,
    "practice areas gone": "practice areas" not in home,
    "glyph bars": 'glyph--bars' in home,
    "glyph target": 'glyph--target' in home,
    "glyph matrix": 'glyph--matrix' in home,
    "glyph dial": 'glyph--dial' in home,
    "conic gradient compiled": 'conic-gradient' in css,
    "no svg": '<svg' not in home and '.svg' not in home.replace('safari-pinned-tab.svg', ''),
}
for k, v in checks.items():
    print(("PASS " if v else "FAIL ") + k)
PY
```

Expected: every line `PASS`. `safari-pinned-tab.svg` is excluded from the SVG check on purpose — it is a favicon asset held out of scope, not a design graphic.

- [ ] **Step 6: Commit**

```bash
git add _includes/glyph.html _includes/capability-card.html _sass/_cards.scss _layouts/home.html
git commit -m "feat: capability cards with four CSS-only glyphs

Section heading and eyebrow drop the mockup's service-offering framing
per the approved copy decisions. Card bodies kept verbatim."
```

---

## Task 9: Selected work — feature card and secondaries

Homepage section 4. A 1.5fr feature card beside two stacked secondaries, and a `View all six →` link. The three items and their kickers derive entirely from front matter: the design's picks are exactly `order` 1, 2 and 3, and its kickers match the `result:` values character for character. **No hardcoded project list.**

**Files:**
- Rewrite: `_includes/work-card.html`
- Modify: `_sass/_cards.scss` (append)
- Modify: `_layouts/home.html`
- Modify: `_pages/work.html:14` (pass the new `post=` parameter — see Step 3b)

- [ ] **Step 1: Rewrite `_includes/work-card.html`**

Two variants through one parameter. The class names stay generic (`card__eyebrow`, not `wcard__result`) — that generic naming from Phase 3.1 is exactly what lets the front-matter keys survive this rewrite unchanged.

```liquid
{% include base_path %}
{% assign variant = include.variant | default: 'secondary' %}

<article class="card card--link card--work card--work-{{ variant }}">
  {% if variant == 'feature' %}
    <span class="card__ring card__ring--lg" aria-hidden="true"></span>
    <span class="card__ring card__ring--sm" aria-hidden="true"></span>
  {% endif %}

  <div class="card__content">
    {% if include.post.result %}
      <p class="kicker">{{ include.post.result }}</p>
    {% elsif include.post.result_note %}
      <p class="kicker">{{ include.post.result_note }}</p>
    {% endif %}

    <h3 class="card__title">
      <a href="{{ base_path }}{{ include.post.url }}" rel="permalink">{{ include.post.title }}</a>
    </h3>

    {% if include.post.excerpt %}
      <p class="card__body">{{ include.post.excerpt | markdownify | strip_html | strip_newlines }}</p>
    {% endif %}

    {% if include.post.tags and include.post.tags.size > 0 %}
      <ul class="chips">
        {% for tag in include.post.tags %}<li>{{ tag }}</li>{% endfor %}
      </ul>
    {% endif %}
  </div>
</article>
```

The include takes `post` as an explicit parameter rather than relying on an ambient `post` variable, because `/work/` loops over an assigned variable and the homepage indexes into a limited array. Callers must pass it.

- [ ] **Step 2: Append the work variants to `_sass/_cards.scss`**

Add at the end of the file.

```scss
// --- Work variants -------------------------------------------------------

.work-grid {
  display: grid;
  grid-template-columns: 1.5fr 1fr;
  gap: 14px;
}

.work-grid__stack {
  display: grid;
  gap: 14px;
}

.card--work {
  border-radius: $r-work;
  overflow: hidden;

  .card__title a { color: inherit; }
  &:hover .card__title a { color: $accent; }
}

.card__content { position: relative; }

// Feature: amber diagonal wash plus two concentric decorative rings.
.card--work-feature {
  padding: 34px 34px 30px;
  background: linear-gradient(135deg, rgba(240, 162, 2, 0.2), rgba(244, 242, 237, 0.05));

  .kicker { margin-bottom: 16px; }

  .card__title {
    max-width: 400px;
    font: 600 30px/1.15 $sans;
    letter-spacing: -0.02em;
  }

  .card__body {
    max-width: 420px;
    margin-top: 12px;
    font-size: 14.5px;
    color: $ink-68;
  }
}

.card__ring {
  position: absolute;
  border: 1px solid $line-ring;
  border-radius: 50%;
  pointer-events: none;

  &--lg {
    right: -40px;
    bottom: -40px;
    width: 200px;
    height: 200px;
  }
  &--sm {
    right: 10px;
    bottom: 10px;
    width: 100px;
    height: 100px;
  }
}

.card--work-secondary {
  padding: 24px;

  .kicker { margin-bottom: 12px; }

  .card__title { font: 600 19px/1.25 $sans; }
}
```

- [ ] **Step 3: Add the selected-work section to `_layouts/home.html`**

Insert after the capability section, before `{{ content }}`.

```liquid
{% assign work_count = site.portfolio | size %}
{% assign ordered_work = site.portfolio | sort: 'order' %}
{% assign featured = ordered_work | slice: 0, 1 %}
{% assign seconds = ordered_work | slice: 1, 2 %}

<section class="band band--tight">
  <div class="band__inner">
    <div class="heading-row heading-row--split">
      <h2 class="heading-row__title">Selected work</h2>
      <a class="heading-row__link" href="{{ base_path }}/work/">View all {{ work_count }} &rarr;</a>
    </div>
    <div class="work-grid">
      {% for post in featured %}
        {% include work-card.html post=post variant="feature" %}
      {% endfor %}
      <div class="work-grid__stack">
        {% for post in seconds %}
          {% include work-card.html post=post variant="secondary" %}
        {% endfor %}
      </div>
    </div>
  </div>
</section>
```

Note the `{% assign %}` before every loop. **Liquid's `for` tag silently ignores piped filters** — `{% for p in site.portfolio | sort: 'order' %}` renders nothing at all, with no error. This has cost time in this repo before.

`View all {{ work_count }}` renders as `View all 6` rather than the design's spelled-out "six", because the count is derived. A number that can never drift beats a word that can.

- [ ] **Step 3b: Update the existing `/work/` call site**

The Step 1 rewrite makes `post` an explicit parameter. `_pages/work.html:14` currently calls the include bare, relying on the ambient `post` from its `for` loop:

```liquid
  {% include work-card.html %}
```

Left alone that renders six empty `<article>` shells — no kicker, no title, no link, and **no error**. Change that one line to:

```liquid
  {% include work-card.html post=post variant="secondary" %}
```

Task 11 rewrites this page properly. This one-line patch is only here so the site is never left in a broken intermediate state, and so Step 4 can assert it.

- [ ] **Step 4: Build and verify the derivation**

```bash
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jbuild
python3 - <<'PY'
import pathlib
home = pathlib.Path('_site/index.html').read_text()
checks = {
    "one feature card": home.count('card--work-feature') == 1,
    "two secondary cards": home.count('card--work-secondary') == 2,
    # Count the modifiers, not the base class: 'card__ring' is a substring of
    # 'card__ring--lg', so each span matches it twice.
    "one large ring": home.count('card__ring--lg') == 1,
    "one small ring": home.count('card__ring--sm') == 1,
    "order 1 = SLAM": "Real-time visual SLAM on edge hardware" in home,
    "order 2 = defect detection": "Defect detection where models plateau" in home,
    "order 3 = agentic": "Agentic" in home,
    "kicker from result:": "9x faster inference" in home.lower().replace("×", "x"),
    "kicker from result_note:": "Auditable by design" in home,
    "derived work count": "View all 6" in home,
    "links to /work/": '/work/' in home,
}
work = pathlib.Path('_site/work/index.html').read_text()
# Same substring trap: 'card--work' is inside 'card--work-secondary'.
checks["/work/ still renders 6 cards"] = work.count('card--work-secondary') == 6
checks["/work/ cards are not empty shells"] = work.count('rel="permalink"') == 6
for k, v in checks.items():
    print(("PASS " if v else "FAIL ") + k)
PY
```

Expected: every line `PASS`. If all three homepage card slots are empty, the `{% assign %}` before a `for` loop is missing — see Step 3. If the two `/work/` checks fail, Step 3b was skipped.

**Never count a BEM base class by substring when a modifier extends it.** `'card__ring'` also matches `card__ring--lg`, so two ring spans count as four; `'card--work'` also matches `card--work-secondary`, so six cards count as twelve. Count the modifier, or parse the `class` attribute. This is the same class of error as using `grep -c` against minified single-line markup.

- [ ] **Step 5: Commit**

```bash
git add _includes/work-card.html _sass/_cards.scss _layouts/home.html _pages/work.html
git commit -m "feat: selected work feature and secondary cards

Cards, kickers and the 'View all' count all derive from portfolio front
matter, so the homepage cannot drift from /work/."
```

---

## Task 10: Writing rows and the inverted contact block

Homepage section 5, and the last of the five. Three real posts as row lists beside an amber-ground contact block. The inverted block is the design's loudest element — **maximum one per page.** The scarcity is what gives it force.

**Files:**
- Create: `_includes/row-list-item.html`
- Modify: `_sass/_layout.scss` (append)
- Modify: `_layouts/home.html`

- [ ] **Step 1: Write `_includes/row-list-item.html`**

Two variants of one primitive. A bare date-and-title row would silently discard `venue`, `paperurl`, `type` and `location` — all of which the deleted `archive-single.html` renders today. The `meta` parameter is what prevents that data loss.

```liquid
{% include base_path %}
{% assign p = include.post %}
<li class="row{% if include.meta and include.meta != '' %} row--meta{% endif %}">
  <span class="row__date">{{ include.date }}</span>
  <span class="row__main">
    <a class="row__title" href="{{ base_path }}{{ p.url }}">{{ p.title }}</a>
    {% if include.meta and include.meta != '' %}<span class="row__meta">{{ include.meta }}</span>{% endif %}
    {% if p.paperurl %}<a class="row__paper" href="{{ p.paperurl }}">Paper &rarr;</a>{% endif %}
  </span>
</li>
```

**Liquid `include` parameters cannot take filters.** `date=post.date | date: "%b"` is a syntax error. Callers must `{% assign %}` or `{% capture %}` the formatted value first, then pass the variable. Every call site below does this.

- [ ] **Step 2: Append the row list and inverted block to `_sass/_layout.scss`**

Add at the end of the file.

```scss
// --- Row list ------------------------------------------------------------
// Fixed-width mono date, baseline-aligned with the title. Used for the
// homepage writing rows and for publications, talks and teaching.

.row-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.row-list__year {
  margin: 30px 0 14px;
  font: 500 11px/1 $mono;
  letter-spacing: 0.12em;
  color: $accent;
}

.row-list__year:first-child { margin-top: 0; }

.row {
  display: flex;
  gap: 16px;
  align-items: baseline;
}

.row__date {
  flex: none;
  width: 60px;
  font: 400 11px/1.5 $mono;
  color: $ink-52;
}

.row__main { min-width: 0; }

.row__title {
  font: 500 15.5px/1.4 $sans;
  color: $ink;

  &:hover { color: $accent; }
}

.row--meta .row__title { display: block; }

.row__meta {
  display: block;
  margin-top: 4px;
  font: 400 11px/1.5 $mono;
  color: $ink-52;
}

.row__paper {
  display: inline-block;
  margin-top: 4px;
  font: 500 11px/1.5 $mono;
  color: $accent;
}

// --- Inverted block ------------------------------------------------------
// Amber ground, teal text. Maximum ONE per page.

.invert {
  padding: 26px;
  border-radius: $r-work;
  background: $accent;
  color: $ground;
}

.invert__title {
  margin: 0;
  font: 700 22px/1.2 $sans;
  letter-spacing: -0.02em;
  color: $ground;
}

.invert__body {
  margin: 10px 0 20px;
  font: 400 13.5px/1.55 $sans;
  color: rgba(8, 48, 42, 0.82);
}

.invert__links {
  display: flex;
  gap: 18px;
  margin: 18px 0 0;
  padding: 0;
  list-style: none;
  font: 500 11px/1 $mono;
}

.invert__links a {
  color: rgba(8, 48, 42, 0.82);

  &:hover { color: $ground; }
}

.btn {
  display: inline-block;
  padding: 11px 18px;
  background: $ground;
  color: $ink;
  border-radius: $r-pill;
  font: 600 12.5px/1 $sans;
  transition: transform $t-lift, filter $t-lift;

  &:hover {
    color: $ink;
    transform: translateY(-1px);
    filter: brightness(1.25);
  }
}

// The writing / contact split.
.closing {
  display: grid;
  grid-template-columns: 1.4fr 1fr;
  gap: 48px;
  padding: 46px $inset;
  border-top: 1px solid $line-soft;
}

.closing__title {
  margin: 0 0 22px;
  font: 600 22px/1 $sans;
  letter-spacing: -0.02em;
}
```

`.invert__body` uses `rgba(8,48,42,0.82)` — teal at alpha on amber, measuring 4.75:1. That is the design's own value and it passes AA. Do not lighten it.

- [ ] **Step 3: Add the closing section to `_layouts/home.html`**

Insert after the selected-work section, before `{{ content }}`.

```liquid
{% assign recent_posts = site.posts | slice: 0, 3 %}

<section class="closing">
  <div>
    <h2 class="closing__title">Writing</h2>
    <ul class="row-list">
      {% for post in recent_posts %}
        {% assign row_date = post.date | date: "%Y.%m" %}
        {% include row-list-item.html post=post date=row_date %}
      {% endfor %}
    </ul>
  </div>
  <div>
    <div class="invert">
      <h2 class="invert__title">Working on something hard?</h2>
      <p class="invert__body">Pune, India.</p>
      <a class="btn" href="{{ base_path }}/contact/">Get in touch &rarr;</a>
    </div>
  </div>
</section>
```

Three copy replacements from the mockup, all approved: the H2 (`Have a problem that doesn't fit the benchmark?` → `Working on something hard?`), the body (`Pune, India. Collaboration, advisory and speaking.` → `Pune, India.`), and the button (`Start a conversation →` → `Get in touch →`, pointing at `/contact/`).

The three writing rows are the three most recent **real** posts, replacing the mockup's three invented headlines.

- [ ] **Step 4: Build and verify, tolerating the untracked draft**

```bash
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jbuild
python3 - <<'PY'
import pathlib
home = pathlib.Path('_site/index.html').read_text()
checks = {
    # Anchor on the tag: 'class="row' would also match the <ul class="row-list">.
    "three writing rows": home.count('<li class="row') == 3,
    "one row list": home.count('class="row-list"') == 1,
    "one inverted block": home.count('class="invert"') == 1,
    "approved contact H2": "Working on something hard?" in home,
    "mockup H2 gone": "doesn&#39;t fit the benchmark" not in home and "doesn't fit the benchmark" not in home,
    "advisory gone": "advisory" not in home.lower(),
    "approved button": "Get in touch" in home,
    "button targets /contact/": '/contact/' in home,
    "invented headline gone": "What auditability actually costs" not in home,
}
for k, v in checks.items():
    print(("PASS " if v else "FAIL ") + k)
PY
```

Expected: every line `PASS`.

**Expect one blank row title locally.** `_posts/2026-05-03-work-love.md` is an untracked draft with an empty `title` and is the newest post by date, so `slice: 0, 3` picks it up here but not in production. Do not "fix" this by editing that file, and do not add a `title` guard to the loop — production has no such post.

- [ ] **Step 5: Commit**

```bash
git add _includes/row-list-item.html _sass/_layout.scss _layouts/home.html
git commit -m "feat: homepage writing rows and inverted contact block

Row primitive carries an optional metadata line so publication and talk
rows do not silently discard venue and paper links."
```

---

## Task 11: `/work/`

Six portfolio items: the first by `order` as the feature card, the remaining five in a 2-up grid.

**Files:**
- Modify: `_pages/work.html`
- Modify: `_sass/_cards.scss` (append)

- [ ] **Step 1: Rewrite the body of `_pages/work.html`**

Keep the front matter from Task 5 Step 14. Replace everything below it.

```liquid
{% include base_path %}

{% assign ordered_work = site.portfolio | sort: 'order' %}
{% assign featured = ordered_work | slice: 0, 1 %}
{% assign rest = ordered_work | slice: 1, 5 %}

<section class="band band--tight">
  <div class="band__inner">
    {% for post in featured %}
      {% include work-card.html post=post variant="feature" %}
    {% endfor %}
    <div class="work-list">
      {% for post in rest %}
        {% include work-card.html post=post variant="secondary" %}
      {% endfor %}
    </div>
  </div>
</section>
```

- [ ] **Step 2: Append the two-up grid to `_sass/_cards.scss`**

```scss
.work-list {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
  margin-top: 14px;
}
```

- [ ] **Step 3: Build and verify all six render with kickers**

```bash
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jbuild
python3 - <<'PY'
import pathlib, re
p = pathlib.Path('_site/work/index.html').read_text()
# Parse the class attribute; never substring-count a BEM base class, because
# 'card--work' also matches 'card--work-secondary'.
cards = re.findall(r'<article class="([^"]*)"', p)
checks = {
    "six work cards": len(cards) == 6,
    "one feature": sum('card--work-feature' in c for c in cards) == 1,
    "five secondary": sum('card--work-secondary' in c for c in cards) == 5,
    "six kickers": p.count('class="kicker"') == 6,
}
for t in ["Real-time visual SLAM", "Defect detection", "Agentic", "retrieval", "survey", "tf-cnnvis"]:
    checks[f"title: {t}"] = t.lower() in p.lower()
for k, v in checks.items():
    print(("PASS " if v else "FAIL ") + k)
PY
```

Expected: every line `PASS` — 6 cards, 1 feature, 5 secondary, **6 kickers**. Every portfolio item has either `result:` or `result_note:`, so a kicker count below 6 means a front-matter key was lost. All six title probes `True`.

- [ ] **Step 4: Commit**

```bash
git add _pages/work.html _sass/_cards.scss
git commit -m "feat: rebuild /work/ on the card primitive"
```

---

## Task 12: `/blog/`

A 2-up card grid: kicker is the post date, body is the hand-written `excerpt:`.

**Files:**
- Rewrite: `_includes/blog-card.html`
- Modify: `_pages/blog.html`
- Modify: `_sass/_cards.scss` (append)

- [ ] **Step 1: Rewrite `_includes/blog-card.html`**

Takes `post` as an explicit parameter, matching `work-card.html`.

```liquid
{% include base_path %}
{% assign p = include.post %}
{% assign card_date = p.date | date: "%B %Y" %}

<article class="card card--link card--blog">
  <p class="kicker">{{ card_date }}</p>

  <h2 class="card__title">
    <a href="{{ base_path }}{{ p.url }}" rel="permalink">{{ p.title }}</a>
  </h2>

  {% if p.excerpt %}
    <p class="card__body">{{ p.excerpt | markdownify | strip_html | strip_newlines }}</p>
  {% endif %}

  {% if p.tags and p.tags.size > 0 %}
    <ul class="chips">
      {% for tag in p.tags %}<li>{{ tag }}</li>{% endfor %}
    </ul>
  {% endif %}
</article>
```

The three real `excerpt:` values were written by hand in Phase 3.1 and are unchanged by this phase.

- [ ] **Step 2: Rewrite the body of `_pages/blog.html`**

Keep the Task 5 front matter. Replace the body.

```liquid
{% include base_path %}

<section class="band band--tight">
  <div class="band__inner">
    <div class="blog-grid">
      {% for post in site.posts %}
        {% include blog-card.html post=post %}
      {% endfor %}
    </div>
  </div>
</section>
```

- [ ] **Step 3: Append the blog variant to `_sass/_cards.scss`**

```scss
.blog-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
}

.card--blog {
  padding: 26px 24px 28px;
  border-radius: $r-work;

  .card__title {
    font: 600 20px/1.28 $sans;

    a { color: inherit; }
  }

  &:hover .card__title a { color: $accent; }

  .card__body { margin-top: 10px; }
}
```

- [ ] **Step 4: Build and verify**

```bash
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jbuild
python3 - <<'PY'
import pathlib, re
p = pathlib.Path('_site/blog/index.html').read_text()
cards = re.findall(r'<article class="([^"]*)"', p)
checks = {
    # 4 locally: 3 tracked posts + 1 untracked draft. 3 in production.
    "one card per post": len(cards) == 4,
    "every card is a blog card": all('card--blog' in c for c in cards),
    "one kicker per card": p.count('class="kicker"') == len(cards),
    # Every card gets a body: the three tracked posts have hand-written
    # excerpt: keys, and the draft gets one auto-generated by Jekyll from
    # excerpt_separator ("\n\n" in _config.yml). Do NOT expect 3 here.
    "one body per card": p.count('class="card__body"') == len(cards),
    "h1 is 'Blog'": '>Blog<' in p,
    "cardgrid stopgap gone": 'cardgrid' not in p,
}
for k, v in checks.items():
    print(("PASS " if v else "FAIL ") + k)
PY
```

Expected: every line `PASS`, with 4 cards locally and 3 in production. If you see 3 cards locally, the untracked draft was deleted — restore it, it is out of scope.

Note on the body count: an earlier draft of this task expected 3 bodies on the theory that the untracked draft has no excerpt. It has no *explicit* `excerpt:` key, but `excerpt_separator` is set in `_config.yml`, so Jekyll auto-generates one from the first paragraph. `{% if p.excerpt %}` is therefore true for all four.

- [ ] **Step 5: Commit**

```bash
git add _includes/blog-card.html _pages/blog.html _sass/_cards.scss
git commit -m "feat: rebuild /blog/ card grid on the new primitive"
```

---

## Task 13: `/research/`

The highest-risk page in the phase. It carries **five paragraphs of hand-written Phase 1 prose** before the Publications heading — the dissertation and its argument about why photographic priors fail on artwork, Odeuropa, the ODOR dataset, SniffyArt, the ODOR challenge at ICPR 2022, and a separate medical-imaging thread. **Losing or truncating any of it is a build failure.**

**Files:**
- Modify: `_pages/research.html`

- [ ] **Step 1: Snapshot the intro prose before touching the file**

```bash
python3 - <<'PY'
import pathlib
src = pathlib.Path('_pages/research.html').read_text()
head, sep, tail = src.partition('<h2')
pathlib.Path('/tmp/research-intro-before.html').write_text(head)
print("intro source chars:", len(head))
print("h2 sections after intro:", src.count('<h2'))
PY
```

Record the character count. You will diff against this in Step 3.

- [ ] **Step 2: Rewrite `_pages/research.html`**

Keep the front matter from Task 5 Step 14. Keep **every intro paragraph byte-for-byte** — copy them across, do not retype them. Then replace the three publication/talk/teaching sections with row lists.

The structure below shows the wrapper markup and the three row-list bands. `<!-- INTRO PROSE — PASTE VERBATIM -->` is the only place you paste; everything else is written as shown.

```liquid
{% include base_path %}

<section class="band band--tight">
  <div class="band__inner">
    <div class="prose prose--intro">
      <!-- INTRO PROSE — PASTE VERBATIM from /tmp/research-intro-before.html,
           dropping only the `{% include base_path %}` line if it appears there.
           Five paragraphs. Do not reword, reorder, or trim. -->
    </div>
  </div>
</section>

{% assign pubs = site.publications | sort: 'date' | reverse %}
{% assign pubs_by_year = pubs | group_by_exp: "p", "p.date | date: '%Y'" %}

<section class="band band--divided">
  <div class="band__inner">
    <div class="heading-row">
      <h2 class="heading-row__title">Publications</h2>
      <span class="heading-row__eyebrow">/ {{ pubs | size }} peer-reviewed</span>
    </div>
    <!-- SIXTH PARAGRAPH — PASTE VERBATIM. The old page carried a paragraph
         after the Publications <h2> linking to the FAU staff page and Google
         Scholar. It is not part of the five-paragraph intro and would be
         silently dropped if you only pasted the intro. Keep it here. -->
    {% for year in pubs_by_year %}
      <p class="row-list__year">{{ year.name }}</p>
      <ul class="row-list">
        {% for post in year.items %}
          {% assign row_date = post.date | date: "%b" %}
          {% include row-list-item.html post=post date=row_date meta=post.venue %}
        {% endfor %}
      </ul>
    {% endfor %}
  </div>
</section>

<section class="band band--divided">
  <div class="band__inner">
    <div class="heading-row">
      <h2 class="heading-row__title">Talks</h2>
      <span class="heading-row__eyebrow">/ {{ site.talks | size }} total</span>
    </div>
    <ul class="row-list">
      {% for post in site.talks reversed %}
        {% assign row_date = post.date | date: "%Y" %}
        {% capture row_meta %}{{ post.type }}{% if post.venue %} &middot; {{ post.venue }}{% endif %}{% if post.location %} &middot; {{ post.location }}{% endif %}{% endcapture %}
        {% include row-list-item.html post=post date=row_date meta=row_meta %}
      {% endfor %}
    </ul>
  </div>
</section>

<section class="band band--divided">
  <div class="band__inner">
    <div class="heading-row">
      <h2 class="heading-row__title">Teaching</h2>
      <span class="heading-row__eyebrow">/ {{ site.teaching | size }} total</span>
    </div>
    <ul class="row-list">
      {% for post in site.teaching reversed %}
        {% assign row_date = post.date | date: "%Y" %}
        {% capture row_meta %}{{ post.type }}{% if post.venue %} &middot; {{ post.venue }}{% endif %}{% if post.location %} &middot; {{ post.location }}{% endif %}{% endcapture %}
        {% include row-list-item.html post=post date=row_date meta=row_meta %}
      {% endfor %}
    </ul>
  </div>
</section>
```

The `group_by_exp` year grouping and the `sort: 'date' | reverse` are carried over unchanged. The reverse sort was a **bug fix** in Phase 3, not styling — publications were previously listed oldest-first. Do not drop it.

**`reversed` on the talks and teaching loops is load-bearing for the same reason.** Jekyll sorts collection documents by date *ascending*, so `{% for post in site.talks %}` without `reversed` silently lists the 2018 talk first — the identical regression, on a different collection. The old page had `reversed` on both loops; keep it on both.

Deleting `_sass/_archive.scss` in Task 18 incidentally resolves the old publication-title styling (ochre + serif + bold + underline, all stacked). That is a side effect of the rewrite, not a re-opened item.

- [ ] **Step 3: Build and assert the prose survived**

This is success criterion 16.

```bash
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jbuild
python3 - <<'PY'
import re, pathlib
html = pathlib.Path('_site/research/index.html').read_text()
intro = html.split('<div class="prose prose--intro">')[1].split('</div>')[0]
text = re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', intro)).strip()
print("intro chars now:", len(text))
print("compare against the figure recorded in baseline-2026-08-24.txt (within 5%)")
for probe in ["Concepts to Computational Constructs", "Odeuropa", "SniffyArt",
              "pulmonary hemosiderophages"]:
    ok = text.count(probe) >= 1
    print(("PASS " if ok else "FAIL ") + repr(probe))
print("paragraphs in intro:", intro.count('<p'), "(expected 5)")
PY
```

Expected: all four probes `PASS`, five paragraphs, and a character count within 5% of the baseline figure from Task 1 Step 5. **If any probe fails, you dropped content — restore it from `/tmp/research-intro-before.html` and re-run.**

- [ ] **Step 4: Assert every publication row carries its venue and paper link**

This is success criterion 17. The old `archive-single.html` rendered `venue`, `date`, `citation`, `paperurl`, `link`, `type` — a bare date-and-title row would have silently thrown most of it away.

```bash
python3 - <<'PY'
import pathlib, yaml, re
html = pathlib.Path('_site/research/index.html').read_text()
pubs = sorted(pathlib.Path('_publications').glob('*.md'))
missing_venue, missing_paper = [], []
for f in pubs:
    fm = yaml.safe_load(f.read_text().split('---')[1])
    if fm.get('venue') and str(fm['venue']) not in html:
        missing_venue.append(f.name)
    if fm.get('paperurl') and str(fm['paperurl']) not in html:
        missing_paper.append(f.name)
print("publications:", len(pubs), "(expected 21)")
print("rows rendered:", html.count('class="row row--meta"') + html.count('class="row"'))
print("missing venue:", missing_venue, "(expected [])")
print("missing paperurl:", missing_paper, "(expected [])")
print("year headings:", html.count('row-list__year'))
talks = sorted(pathlib.Path('_talks').glob('*.md'))
teach = sorted(pathlib.Path('_teaching').glob('*.md'))
gaps = []
for f in talks + teach:
    fm = yaml.safe_load(f.read_text().split('---')[1])
    for k in ('type', 'venue', 'location'):
        if fm.get(k) and str(fm[k]) not in html:
            gaps.append((f.name, k))
print("talks:", len(talks), "teaching:", len(teach))
print("missing talk/teaching metadata:", gaps, "(expected [])")
PY
```

Expected: 21 publications, empty `missing venue`, empty `missing paperurl`, empty `missing talk/teaching metadata`. Year headings should match the number of distinct publication years.

- [ ] **Step 5: Commit**

```bash
git add _pages/research.html
git commit -m "feat: rebuild /research/ with intro prose band and row lists

Row lists render venue and paper links for all 21 publications and
type/venue/location for talks and teaching, preserving everything the
deleted archive-single.html emitted. Intro prose kept verbatim."
```

---

## Task 14: `/about/` and `/contact/`

Two prose-light pages. `/about/` is a single band at a 680px measure; `/contact/` is the one inverted block on its page.

**Files:**
- Modify: `_pages/about.md`
- Modify: `_sass/_prose.scss` (first real content)

- [ ] **Step 1: Give `_pages/about.md` its wrapper**

The front matter and the "Where to go next" deletion were done in Task 5 Step 12. `route.html` already emits the H1, so the page body needs only a prose wrapper around the prose that is already there.

**Insert these three lines directly below the closing `---` of the front matter**, followed by one blank line:

```html
<div class="band band--tight">
<div class="band__inner">
<div class="prose" markdown="1">
```

**Append these three lines at the very end of the file**, preceded by one blank line:

```html
</div>
</div>
</div>
```

Do not retype, reword, or reflow anything between them. After the edit, `about.md` should be six paragraphs of Phase 1 prose — the opening self-description, the Infocusp role, the PhD and dissertation, the through-line sentence, the mathematics-and-writing paragraph, the Descartes quote, and the closing contact line — bracketed by those six HTML lines.

`markdown="1"` is mandatory. kramdown will not process markdown inside a raw HTML block without it, and you will get literal `**bold**` and `[link](url)` on the page. Step 3 asserts this.

- [ ] **Step 2: Write `_sass/_prose.scss`**

Full replacement of the placeholder. This serves `/about/`, the `/research/` intro, and all 36 detail pages. The Banerjee post is the longest piece of long-form content in the repo and is the reference case — check it in Task 16.

```scss
// ---------------------------------------------------------------------------
// Prose — long-form typography for /about/, the /research/ intro, and all 36
// detail pages.
// ---------------------------------------------------------------------------

.prose {
  max-width: $measure;
  font: 400 16.5px/1.7 $sans;
  color: $ink-70;

  > :first-child { margin-top: 0; }
  > :last-child  { margin-bottom: 0; }
}

.prose p { margin: 0 0 1.15em; }

.prose h2 {
  margin: 2em 0 0.6em;
  font: 600 24px/1.2 $sans;
  color: $ink;
}

.prose h3 {
  margin: 1.8em 0 0.5em;
  font: 600 19px/1.25 $sans;
  color: $ink;
}

.prose h4 {
  margin: 1.6em 0 0.4em;
  font: 600 16px/1.3 $sans;
  color: $ink;
}

.prose strong { color: $ink; font-weight: 600; }

.prose em { font-style: italic; }

.prose ul,
.prose ol {
  margin: 0 0 1.15em;
  padding-left: 1.35em;
}

.prose li { margin-bottom: 0.4em; }

.prose a {
  color: $accent;
  border-bottom: 1px solid rgba(240, 162, 2, 0.35);

  &:hover {
    color: $ink;
    border-bottom-color: $ink;
  }
}

.prose blockquote {
  margin: 1.6em 0;
  padding: 2px 0 2px 20px;
  border-left: 2px solid $accent;
  color: $ink-60;
  font-style: italic;
}

.prose code {
  padding: 2px 5px;
  background: $chip;
  border-radius: 4px;
  font: 400 0.86em/1.5 $mono;
  color: $ink;
}

.prose pre {
  margin: 1.6em 0;
  padding: 18px 20px;
  overflow-x: auto;
  background: rgba(0, 0, 0, 0.22);
  border: 1px solid $line-soft;
  border-radius: $r-metric;

  code {
    padding: 0;
    background: none;
    font-size: 13px;
    line-height: 1.6;
  }
}

.prose table {
  width: 100%;
  margin: 1.6em 0;
  border-collapse: collapse;
  font-size: 14px;
}

.prose th,
.prose td {
  padding: 10px 12px;
  text-align: left;
  border-bottom: 1px solid $line-soft;
}

.prose th {
  font: 500 11px/1.4 $mono;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: $ink-52;
}

.prose img {
  max-width: 100%;
  height: auto;
  border-radius: $r-metric;
}

.prose hr {
  margin: 2.4em 0;
  border: 0;
  border-top: 1px solid $line-soft;
}

// Footnotes, as kramdown emits them.
.prose .footnotes {
  margin-top: 2.4em;
  padding-top: 1.2em;
  border-top: 1px solid $line-soft;
  font-size: 13.5px;
  color: $ink-60;
}

// The /research/ intro sits above three row-list bands and needs no top rule.
.prose--intro { margin-bottom: 0; }
```

- [ ] **Step 3: Build and verify both pages**

```bash
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jbuild
python3 - <<'PY'
import pathlib
about = pathlib.Path('_site/about/index.html').read_text()
contact = pathlib.Path('_site/contact/index.html').read_text()
checks = {
    "about has prose wrapper": 'class="prose"' in about,
    "about markdown rendered (links)": 'href="http://www.infocusp.com/' in about or 'infocusp.com' in about,
    "about keeps the Descartes line": "Cogito, ergo sum" in about,
    "about keeps the through-line": "standard models fail" in about.lower(),
    "'Where to go next' removed": "Where to go next" not in about,
    "no raw markdown asterisks left": "**[" not in about,
    "contact has one inverted block": contact.count('class="invert"') == 1,
    "contact mailto": "mailto:prathmesh@infocusp.com" in contact,
    "about has no inverted block": 'class="invert"' not in about,
}
for k, v in checks.items():
    print(("PASS " if v else "FAIL ") + k)
PY
```

Expected: every line `PASS`. `no raw markdown asterisks left` catches the classic failure — forgetting `markdown="1"` leaves literal `**bold**` and `[link](url)` on the page.

- [ ] **Step 4: Commit**

```bash
git add _pages/about.md _sass/_prose.scss
git commit -m "feat: prose styles, /about/ band and /contact/ block"
```

---

## Task 15: `/cv/`

The site **is** the CV — there is no PDF download, by the user's standing rule. The kramdown IAL class names in `cv.md` are unchanged, so `_cv.scss` is a pure restyle.

**One correction to the spec.** The spec says `cv.md`'s markdown body is unchanged. That is true of the IAL blocks but **not** of the whole file: `cv.md` calls `archive-single-cv.html` twice and `archive-single-talk-cv.html` once, and Task 18 deletes both. Those three include calls must be swapped for `row-list-item.html`. Deleting `archive-single-cv.html` also retires the invalid `<li>`-inside-`<div><article>` markup that Phase 3.1 held out of scope.

**Files:**
- Rewrite: `_sass/_cv.scss`
- Modify: `_pages/cv.md` (the three include calls and their `<ul>` wrappers only)

- [ ] **Step 1: Replace the three collection blocks in `_pages/cv.md`**

Everything from line 176 (`## Publications`) to the end of the file. Every `{: .cv-*}` block above line 176 stays untouched.

```liquid
## Publications

{% assign pub_count = site.publications | size %}
{% assign recent_pubs = site.publications | sort: 'date' | reverse %}

{{ pub_count }} peer-reviewed publications, {{ site.scholar_citations }} citations. The five most recent are below; the [full list is on the research page]({{ base_path }}/research/).
{: .cv-note}

<ul class="row-list">
{% for post in recent_pubs limit: 5 %}
  {% assign row_date = post.date | date: "%Y" %}
  {% include row-list-item.html post=post date=row_date meta=post.venue %}
{% endfor %}
</ul>

## Talks

<ul class="row-list">
{% for post in site.talks reversed %}
  {% assign row_date = post.date | date: "%Y" %}
  {% capture row_meta %}{{ post.type }}{% if post.venue %} &middot; {{ post.venue }}{% endif %}{% if post.location %} &middot; {{ post.location }}{% endif %}{% endcapture %}
  {% include row-list-item.html post=post date=row_date meta=row_meta %}
{% endfor %}
</ul>

## Teaching

<ul class="row-list">
{% for post in site.teaching reversed %}
  {% assign row_date = post.date | date: "%Y" %}
  {% capture row_meta %}{{ post.type }}{% if post.venue %} &middot; {{ post.venue }}{% endif %}{% if post.location %} &middot; {{ post.location }}{% endif %}{% endcapture %}
  {% include row-list-item.html post=post date=row_date meta=row_meta %}
{% endfor %}
</ul>
```

`limit: 5` on the `for` **tag** is fine — that is a tag parameter, not a piped filter. It is piped *filters* that Liquid's `for` silently ignores.

`{{ site.scholar_citations }}` is added here, which means the figure now renders on both `/` and `/cv/` from the single config key. Success criterion 8 asserts `320+` appears exactly once **in source**; two render sites reading one key satisfies that.

- [ ] **Step 2: Rewrite `_sass/_cv.scss`**

Full replacement. **The class names are unchanged from Phase 3.1** — that is what lets 175 lines of `cv.md` survive this rewrite untouched.

```scss
// ---------------------------------------------------------------------------
// CV. Class names are fixed by _pages/cv.md's kramdown IALs — .cv-date,
// .cv-role, .cv-org, .cv-cat, .cv-chips, .cv-note. Do not rename them
// without editing cv.md.
// ---------------------------------------------------------------------------

.cv {
  max-width: 820px;
  padding: 0 $inset $band;
  margin: 0 auto;
}

.cv h2 {
  margin: 48px 0 6px;
  padding-bottom: 12px;
  border-bottom: 1px solid $line-soft;
  font: 600 22px/1.2 $sans;
  letter-spacing: -0.02em;
}

.cv h2:first-child { margin-top: 0; }

// An entry: date kicker, role, org, then bullets.
.cv-date {
  margin: 30px 0 0;
  font: 500 11px/1 $mono;
  letter-spacing: 0.12em;
  color: $accent;
}

.cv-role {
  margin: 10px 0 0;
  font: 600 17px/1.3 $sans;
  color: $ink;
}

.cv-org {
  margin: 4px 0 0;
  font: 400 13px/1.5 $mono;
  color: $ink-52;
}

.cv ul {
  margin: 12px 0 0;
  padding-left: 1.2em;
  font: 400 14.5px/1.65 $sans;
  color: $ink-60;
}

.cv ul li { margin-bottom: 6px; }

.cv a {
  color: $accent;

  &:hover { color: $ink; }
}

// Skills: category label above a chip row.
.cv-cat {
  margin: 26px 0 0;
  font: 400 12px/1 $mono;
  color: $ink-52;
}

.cv-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 7px;
  margin: 10px 0 0;
  padding: 0;
  list-style: none;
}

.cv-chips li {
  margin: 0;
  padding: 6px 10px;
  background: $chip;
  border-radius: $r-card;
  font: 500 11px/1 $mono;
  color: $ink-64;
}

.cv-note {
  margin: 16px 0 20px;
  font: 400 14.5px/1.65 $sans;
  color: $ink-70;
}

// The row lists at the bottom (publications, talks, teaching).
.cv .row-list { margin-top: 4px; }
```

- [ ] **Step 3: Wrap the CV body**

`route.html` emits the H1. **Insert this line immediately after `{% include base_path %}` in `cv.md`**, followed by one blank line:

```html
<div class="cv" markdown="1">
```

**Append this line at the very end of the file**, preceded by one blank line:

```html
</div>
```

Everything between them — all six `{: .cv-*}` IAL block types and the three row-list sections from Step 1 — stays exactly as written.

`markdown="1"` is mandatory or every IAL block renders as literal text.

- [ ] **Step 4: Build and verify**

```bash
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jbuild
python3 - <<'PY'
import pathlib
cv = pathlib.Path('_site/cv/index.html').read_text()
checks = {
    "wrapper present": 'class="cv"' in cv,
    "dates styled": cv.count('class="cv-date"') == 8,
    "roles styled": cv.count('class="cv-role"') == 8,
    "orgs styled": cv.count('class="cv-org"') == 8,
    "skill categories": cv.count('class="cv-cat"') == 6,
    "chip lists": cv.count('class="cv-chips"') == 6,
    "note": 'class="cv-note"' in cv,
    "derived pub count": "21 peer-reviewed publications" in cv,
    "citations from config": "320+ citations" in cv,
    # Tag-anchored: 'class="row' alone also matches the three
    # <ul class="row-list"> wrappers, giving 13. Count the <li> tag.
    "five recent pubs + 3 talks + 2 teaching": cv.count('<li class="row') == 10,
    "three row-list wrappers": cv.count('class="row-list"') == 3,
    "no archive-single leftovers": 'archive__item' not in cv,
    "no literal IAL text": '{: .cv-' not in cv,
    "h2 not h1 for sections": '<h1' in cv and cv.count('<h1') == 1,
}
for k, v in checks.items():
    print(("PASS " if v else "FAIL ") + k)
PY
```

Expected: every line `PASS`. `dates styled: 8` is three education entries plus five experience entries — count them in `cv.md` if the assertion fails rather than adjusting the number to match. `no literal IAL text` catches a missing `markdown="1"`. Exactly one `<h1>` preserves the Phase 3.1 heading fix (section headings are `h2`, not `h1`).

- [ ] **Step 5: Commit**

```bash
git add _pages/cv.md _sass/_cv.scss
git commit -m "feat: retheme /cv/ and swap the deleted archive includes

Class names unchanged, so 175 lines of cv.md's kramdown IALs survive
untouched. The three archive-single-cv include calls become row lists,
retiring the invalid li-inside-article markup from Phase 3.1."
```

---

## Task 16: Detail pages

All 36 detail pages behind the seven routes: 21 publications, 6 portfolio items, 3 talks, 2 teaching entries, and 4 posts (3 tracked). The source design draws none of them, so they are composed from the same primitives.

**Files:**
- Rewrite: `_layouts/detail.html`
- Modify: `_sass/_prose.scss` (append)

- [ ] **Step 1: Rewrite `_layouts/detail.html`**

Full replacement of the Task 5 stub. Each collection surfaces a different metadata shape, so the kicker and meta line are conditional on what the front matter actually holds.

```liquid
---
layout: base
---

{% include base_path %}

<article class="detail">
  <div class="page-title">
    <div class="page-title__inner">
      {% if page.result %}
        <p class="kicker">{{ page.result }}</p>
      {% elsif page.result_note %}
        <p class="kicker">{{ page.result_note }}</p>
      {% elsif page.type %}
        <p class="kicker">{{ page.type }}</p>
      {% elsif page.venue %}
        <p class="kicker">{{ page.venue }}</p>
      {% endif %}

      <h1 class="page-title__h1">{{ page.title }}</h1>

      {% capture detail_meta %}{% if page.date %}<span>{{ page.date | date: "%B %Y" }}</span>{% endif %}{% if page.venue and page.type %}<span>{{ page.venue }}</span>{% endif %}{% if page.location %}<span>{{ page.location }}</span>{% endif %}{% endcapture %}
      {% if detail_meta != '' %}<p class="detail__meta">{{ detail_meta }}</p>{% endif %}

      {% if page.paperurl %}
        <p class="detail__actions">
          <a class="btn btn--outline" href="{{ page.paperurl }}">Read the paper &rarr;</a>
        </p>
      {% endif %}
    </div>
  </div>

  <div class="band band--tight">
    <div class="band__inner">
      <div class="prose">
        {{ content }}
      </div>

      {% if page.citation %}
        <p class="detail__citation">{{ page.citation }}</p>
      {% endif %}

      {% if page.tags and page.tags.size > 0 %}
        <ul class="chips">
          {% for tag in page.tags %}<li>{{ tag }}</li>{% endfor %}
        </ul>
      {% endif %}
    </div>
  </div>
</article>
```

`citation` lives here, on the detail page, and deliberately not in the publication row — it is long-form and would wreck the row rhythm.

**Why the meta line is a `capture` and not a bare `<p>`.** Front matter was audited across all 36 files. The six portfolio items carry no `date`, no `venue`, no `type` and no `location` — only `result`/`result_note`, `excerpt`, `order` and `tags`. A bare `<p class="detail__meta">` would render empty on all six, contributing a stray 16px top margin under the H1. The capture emits the element only when it has content, and stays correct if a collection's front matter changes.

**Why there is no `page.link` branch.** No file in any of the five collections carries a `link` key — the audit found `citation`(21), `paperurl`(21), `venue`(26), `type`(5), `location`(5), `result`(4), `result_note`(2), `tags`(10), `order`(6), `excerpt`(9). `link` is a Minimal Mistakes portfolio convention this site never used, so a `{% if page.link %}` branch would be dead code. Do not add it.

- [ ] **Step 2: Append the detail-page styles to `_sass/_prose.scss`**

```scss
// --- Detail pages --------------------------------------------------------

.detail__meta {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  margin: 16px 0 0;
  font: 400 11px/1.5 $mono;
  color: $ink-52;
}

.detail__actions { margin: 24px 0 0; }

.btn--outline {
  background: none;
  border: 1px solid $line-strong;
  color: $ink;

  &:hover {
    border-color: $accent;
    color: $accent;
    filter: none;
  }
}

.detail__citation {
  max-width: $measure;
  margin: 32px 0 0;
  padding: 16px 18px;
  background: $surface;
  border-radius: $r-metric;
  font: 400 12.5px/1.65 $mono;
  color: $ink-60;
}

.detail .chips { margin-top: 26px; }
```

- [ ] **Step 3: Build and verify every detail page renders through `detail.html`**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild
python3 - <<'PY'
import pathlib
root = pathlib.Path('_site')
routes = {'index.html', 'work/index.html', 'research/index.html', 'blog/index.html',
          'about/index.html', 'cv/index.html', 'contact/index.html', '404.html'}
details, misses = [], []
for p in root.rglob('*.html'):
    rel = p.relative_to(root).as_posix()
    if rel in routes or rel.startswith('assets/'):
        continue
    t = p.read_text()
    if 'redirect' in t.lower() and len(t) < 900:
        continue          # jekyll-redirect-from stubs
    (details if 'class="detail"' in t else misses).append(rel)
print("detail pages:", len(details), "(expected 36)")
print("NOT rendered via detail.html:", misses, "(expected [])")

# No empty meta paragraph anywhere, and none at all on the six portfolio items.
empty = [d for d in details if '<p class="detail__meta"></p>' in root.joinpath(d).read_text()]
print("empty meta paragraphs:", empty, "(expected [])")
port = [d for d in details if d.startswith('portfolio/')]
print("portfolio pages:", len(port), "(expected 6)")
print("  with a meta line:", sum('detail__meta' in root.joinpath(d).read_text() for d in port), "(expected 0)")

# Per-collection expectations, from the front matter audit.
pubs = [d for d in details if d.startswith('publications/')]
print("publications:", len(pubs), "(expected 21)")
print("  with a citation:", sum('detail__citation' in root.joinpath(d).read_text() for d in pubs), "(expected 21)")
print("  with a paper button:", sum('btn--outline' in root.joinpath(d).read_text() for d in pubs), "(expected 21)")
PY
```

Expected: `detail pages: 36`, an empty miss list, no empty meta paragraphs, 6 portfolio pages with 0 meta lines, and 21 publications each with a citation and a paper button. If a page appears in `misses`, its collection default in `_config.yml` still points elsewhere — recheck Task 5 Step 1.

- [ ] **Step 4: Check the longest post as the prose reference case**

`_posts/2020-07-12-rip-banerjee-sir.md` is the longest content in the repo at 12.7 KB and is the reference for prose styling.

**Do not glob for this file.** The post carries `redirect_from: /posts/2012/08/rip-banerjee-sir/`, so a glob on `*banerjee*` matches two paths and the alphabetically-first is the 617-byte redirect stub, not the 12.7 KB page. Address the real permalink directly and assert the size, so a stub can never masquerade as the page.

```bash
python3 - <<'PY'
import pathlib
f = pathlib.Path('_site/posts/2020/07/12/rip-banerjee-sir/index.html')
t = f.read_text()
print("path:", f)
print("size:", len(t), "(must be > 10000 — guards against the redirect stub)")
assert len(t) > 10000, "got the redirect stub, not the post"
for tag in ['<p', '<h2', '<h3', '<ul', '<ol', '<blockquote', '<pre', '<table', '<img', 'footnote']:
    print(f"  {tag}: {t.count(tag)}")
print("wrapped in .prose:", 'class="prose"' in t)
PY
```

Expected: a healthy `<p>` count and `wrapped in .prose: True`. Note which elements appear with a count of 0 — those prose rules are written but unexercised, which is fine; they exist for future content.

- [ ] **Step 5: Commit**

```bash
git add _layouts/detail.html _sass/_prose.scss
git commit -m "feat: detail page layout for all 36 collection pages

Kicker, meta line and actions are conditional on what each collection's
front matter actually carries. Citations render on the detail page, not
in the publication row."
```

---

## Task 17: Syntax highlighting on a dark ground

`_config.yml` sets `highlighter: rouge`. One post (`_posts/2020-09-30-why-fastai.md`) contains code. The old theme's `_syntax.scss` was built for a cream ground and would be illegible.

**Files:**
- Rewrite: `_sass/_syntax.scss`

- [ ] **Step 1: Write `_sass/_syntax.scss`**

Full replacement of the placeholder. Deliberately small — the site has one code-bearing post. `_prose.scss` already styles `pre` and `code`; this file only colours tokens.

```scss
// ---------------------------------------------------------------------------
// Rouge token colours on the dark ground. Intentionally minimal — the palette
// is two hues, so code is differentiated by ink alpha, not by rainbow colour.
// ---------------------------------------------------------------------------

.highlight,
.highlighter-rouge .highlight {
  background: transparent;
  color: $ink-70;
}

.highlight {
  .c, .c1, .cm, .cs, .cd { color: $ink-52; font-style: italic; }   // comments
  .k, .kc, .kd, .kn, .kp, .kr, .kt { color: $accent; }             // keywords
  .o, .ow                          { color: $ink-70; }             // operators
  .s, .s1, .s2, .sb, .sc, .sd, .se, .sh, .si, .sx, .sr, .ss { color: #9BD4B4; }
  .m, .mf, .mh, .mi, .mo           { color: #9BD4B4; }             // numbers
  .nf, .nb, .nc                    { color: $ink; }                // functions
  .n, .na, .nn, .nv, .nx           { color: $ink-70; }
  .p, .pi                          { color: $ink-60; }             // punctuation
  .err                             { color: #FF8A7A; }
  .gd  { color: #FF8A7A; }
  .gi  { color: #9BD4B4; }
  .ge  { font-style: italic; }
  .gs  { font-weight: 600; }
}
```

`#9BD4B4` is a desaturated mint — it reads as teal-family rather than as a third brand hue, and it keeps strings distinguishable from keywords. Verify its contrast in Task 21.

- [ ] **Step 2: Build and verify against the one code-bearing post**

```bash
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jbuild
python3 - <<'PY'
import pathlib, glob
css = pathlib.Path('_site/assets/css/main.css').read_text()
print("rouge rules compiled:", '.highlight' in css)
print("light-ground leftovers:", '#f8f8f8' in css or '#fff8f8' in css, "(expected False)")
hits = [p for p in glob.glob('_site/**/*.html', recursive=True)
        if 'highlight' in pathlib.Path(p).read_text()]
print("pages with highlighted code:", len(hits))
for h in hits: print("  ", h)
PY
```

Expected: `rouge rules compiled: True`, `light-ground leftovers: False`. If zero pages carry highlighted code, the fastai post uses indented rather than fenced blocks — that is fine, the rules still exist for future content.

- [ ] **Step 3: Commit**

```bash
git add _sass/_syntax.scss
git commit -m "feat: dark-ground syntax highlighting"
```

---

## Task 18: Delete the Minimal Mistakes visual layer

Everything the new system replaced. This is where the CSS size criterion is won.

**Files:** see the delete list in "File structure" above.

- [ ] **Step 1: Prove nothing references any of it**

Run before deleting. A failed build is the safety net, but a grep is cheaper than a build.

```bash
python3 - <<'PY'
import pathlib
live = ['_layouts', '_includes', '_pages', '_posts', '_portfolio', '_publications',
        '_talks', '_teaching', '_data', 'assets/css', '_config.yml']
doomed = [
  'default.html', 'single.html', 'talk.html', 'archive.html', 'archive-taxonomy.html',
  'splash.html', 'author-profile', 'page__hero', 'page__taxonomy', 'masthead', 'sidebar',
  'nav_list', 'tag-list', 'category-list', 'social-share', 'breadcrumbs', 'paginator',
  'post_pagination', 'read-time', 'browser-upgrade', 'archive-single', 'feature_row',
  'gallery', 'toc', 'comment', 'footer.html',
  'susy', 'font-awesome', 'magnific', 'breakpoint',
  '"variables"', '"mixins"', '"utilities"', '"animations"', '"buttons"', '"notices"',
  '"forms"', '"tables"', '"page"', '"archive"', '"navigation"',
]
hits = {}
for r in live:
    pr = pathlib.Path(r)
    files = [pr] if pr.is_file() else [f for f in pr.rglob('*') if f.is_file()]
    for f in files:
        if f.suffix not in {'.html', '.md', '.scss', '.yml', '.css'}:
            continue
        # Skip the files we are about to delete; self-references do not matter.
        if any(d.strip('"') in f.name for d in doomed):
            continue
        t = f.read_text(errors='ignore')
        for d in doomed:
            if d in t:
                hits.setdefault(d, set()).add(f.as_posix())
for d in doomed:
    v = sorted(hits.get(d, []))
    if v:
        print(f"STILL REFERENCED  {d}: {v}")
print("--- scan complete ---")
PY
```

Expected: only `--- scan complete ---`. Two acceptable exceptions if they appear:

- `footer.html` matching `_includes/footer/custom.html` — a path-fragment false positive, not a reference.
- `'comment'` matching a `<!-- comment -->` in your own new files — read the hit and judge.

Anything else is a real reference. Fix the referring file before deleting.

- [ ] **Step 2: Delete the layouts**

```bash
git rm --quiet _layouts/default.html _layouts/single.html _layouts/talk.html \
  _layouts/archive.html _layouts/archive-taxonomy.html _layouts/splash.html
ls -1 _layouts/
```

Expected exactly: `base.html`, `compress.html`, `detail.html`, `home.html`, `route.html`.

**`compress.html` stays.** It is not dead code — `base.html` declares `layout: compress` and `compress_html:` is configured in `_config.yml`. Deleting it silently un-minifies all 53 pages.

- [ ] **Step 3: Delete the includes**

```bash
git rm -r --quiet \
  _includes/author-profile.html _includes/page__hero.html _includes/page__taxonomy.html \
  _includes/masthead.html _includes/sidebar.html _includes/nav_list \
  _includes/tag-list.html _includes/category-list.html _includes/social-share.html \
  _includes/breadcrumbs.html _includes/paginator.html _includes/post_pagination.html \
  _includes/read-time.html _includes/browser-upgrade.html \
  _includes/archive-single.html _includes/archive-single-cv.html \
  _includes/archive-single-talk.html _includes/archive-single-talk-cv.html \
  _includes/feature_row _includes/gallery _includes/toc \
  _includes/comment.html _includes/comments.html _includes/comments-providers \
  _includes/footer.html
ls -1 _includes/
```

Expected exactly: `analytics-providers`, `analytics.html`, `base_path`, `blog-card.html`, `capability-card.html`, `footer`, `glyph.html`, `group-by-array`, `head`, `head.html`, `metric-tile.html`, `row-list-item.html`, `scripts.html`, `seo.html`, `site-footer.html`, `site-header.html`, `work-card.html`.

Comments are already off — `comments.provider` is blank in `_config.yml` — so the comment includes were dead before this phase.

- [ ] **Step 4: Delete the Sass partials and all three vendor libraries**

```bash
git rm -r --quiet \
  _sass/_masthead.scss _sass/_sidebar.scss _sass/_archive.scss _sass/_page.scss \
  _sass/_navigation.scss _sass/_utilities.scss _sass/_animations.scss \
  _sass/_buttons.scss _sass/_notices.scss _sass/_forms.scss _sass/_tables.scss \
  _sass/_mixins.scss _sass/_variables.scss \
  _sass/vendor
ls -1 _sass/
```

Expected exactly twelve files: `_base.scss`, `_cards.scss`, `_cv.scss`, `_footer.scss`, `_header.scss`, `_hero.scss`, `_layout.scss`, `_print.scss`, `_prose.scss`, `_reset.scss`, `_syntax.scss`, `_tokens.scss`. No `vendor` directory.

Deleting `_variables.scss` also removes the latent bug where `$medium` was declared twice and the non-`!default` declaration won at **500px** — which is why the Phase 3 and 3.1 card grids went two-up on a large phone. `_tokens.scss` replaces it with `$bp-md: 768px`.

- [ ] **Step 5: Clean-build and measure the CSS**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild
python3 - <<'PY'
import pathlib
root = pathlib.Path('_site')
css = (root / 'assets/css/main.css')
size = css.stat().st_size
print(f"main.css: {size} bytes  (baseline 102456, budget 25600)")
print("PASS" if size < 25600 else "FAIL — over budget")
body = css.read_text()
for needle in ['fa-', 'susy', 'magnific', 'font-awesome', 'academicons', 'greedy']:
    print(f"  {needle!r} in css:", needle in body, "(expected False)")
pages = list(root.rglob('*.html'))
print("html pages:", len(pages), "(expected 53)")
for needle in ['author_profile', 'page__content', 'masthead', 'fa fa-', 'fab fa-']:
    n = sum(p.read_text(errors='ignore').count(needle) for p in pages)
    print(f"  {needle!r} in built html:", n, "(expected 0)")
PY
```

Expected: `main.css` well under 25,600 bytes, every `in css` line `False`, `html pages: 53`, and every `in built html` count `0`.

`sass.style: compressed` is already set in `_config.yml`, so both the 102,456-byte baseline and this figure are **minified**. The old number was not unminified bloat — it was genuinely that much CSS, most of it Font Awesome.

- [ ] **Step 6: Commit**

```bash
git add -u
git commit -m "refactor: delete the Minimal Mistakes visual layer

Six layouts, twenty-five includes, thirteen sass partials, and the susy,
font-awesome and magnific-popup vendor libraries. Also removes the
double-declared \$medium that broke card grids at 500px."
```

---

## Task 19: Responsive behaviour

Three breakpoints: ≥1024, 768–1023, <768. The design's own tables specify these, with H1 dropping to ~38px on mobile.

**Files:**
- Modify: `_sass/_hero.scss`, `_sass/_cards.scss`, `_sass/_layout.scss` (append responsive blocks)

- [ ] **Step 1: Append the responsive block to `_sass/_hero.scss`**

```scss
// --- Responsive ----------------------------------------------------------

@media (max-width: $bp-lg - 1px) {
  .hero__inner {
    grid-template-columns: 1fr;
    gap: 40px;
    align-items: start;
  }

  .hero__h1 { font: 700 48px/1.02 $sans; letter-spacing: -0.03em; }
}

@media (max-width: $bp-md - 1px) {
  .hero {
    padding: 36px $inset-sm 0;
  }

  .hero__inner { padding-bottom: 36px; }

  .hero__h1 { font: 700 38px/1.05 $sans; letter-spacing: -0.028em; }

  .hero__lede { font-size: 15.5px; }

  .metric { padding: 18px; }

  .metric__value { font-size: 32px; }
}
```

- [ ] **Step 2: Append the responsive block to `_sass/_cards.scss`**

```scss
// --- Responsive ----------------------------------------------------------

@media (max-width: $bp-lg - 1px) {
  .capability-grid { grid-template-columns: 1fr 1fr; }

  .work-grid { grid-template-columns: 1fr; }

  .card--work-feature .card__title { font-size: 26px; }
}

@media (max-width: $bp-md - 1px) {
  .capability-grid,
  .work-list,
  .blog-grid {
    grid-template-columns: 1fr;
  }

  .card--work-feature {
    padding: 26px 22px 24px;

    .card__title { font-size: 23px; }
  }

  // Decorative rings crowd a narrow card.
  .card__ring { display: none; }
}
```

Hiding `.card__ring` below 768px is deliberate: at phone width the 200px ring overlaps the body text.

- [ ] **Step 3: Append the responsive block to `_sass/_layout.scss`**

```scss
// --- Responsive ----------------------------------------------------------

@media (max-width: $bp-md - 1px) {
  .band { padding: $band-sm $inset-sm; }

  .page-title { padding: 32px $inset-sm $band-sm; }

  .page-title__h1 { font: 700 32px/1.08 $sans; }

  .page-title__lede { font-size: 15.5px; }

  .heading-row {
    flex-wrap: wrap;
    gap: 8px;
    margin-bottom: 22px;
  }

  .heading-row__title { font-size: 22px; }

  .closing {
    grid-template-columns: 1fr;
    gap: 32px;
    padding: $band-sm $inset-sm;
  }

  .row { gap: 12px; }

  .row__date { width: 52px; }

  .row__title { font-size: 14.5px; }

  .cv { padding: 0 $inset-sm $band-sm; }

  .site-footer { padding: 28px $inset-sm 32px; }
}
```

- [ ] **Step 4: Assert no fixed widths can overflow the viewport**

There is no headless browser here, so this is a static check on the compiled CSS: nothing may declare a `width` or `min-width` in `px` larger than the smallest target viewport.

```bash
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jbuild
python3 - <<'PY'
import re, pathlib
css = pathlib.Path('_site/assets/css/main.css').read_text()
bad = []
for prop, val in re.findall(r'(?<![-\w])(min-width|width)\s*:\s*(\d+)px', css):
    # min-width inside a media query is a breakpoint, not a box width.
    if int(val) > 375 and prop == 'width':
        bad.append(f"{prop}:{val}px")
print("fixed widths wider than 375px:", sorted(set(bad)), "(expected [])")
print("max-width declarations:", len(re.findall(r'max-width\s*:\s*\d+px', css)))
print("grid-template-columns count:", css.count('grid-template-columns'))
print("media queries:", len(re.findall(r'@media', css)))
overflow = re.findall(r'overflow\s*:\s*hidden', css)
print("overflow:hidden guards:", len(overflow))
PY
```

Expected: `fixed widths wider than 375px: []`, at least four media queries, and at least one `overflow:hidden` guard (the hero, which clips the glow).

`max-width` declarations are fine at any size — they shrink. It is `width` that overflows.

- [ ] **Step 5: Visual spot-check at the four target widths**

No headless browser is installed, so this step is manual. Serve the built site and resize:

```bash
python3 -m http.server 4000 --directory _site
```

Open `http://localhost:4000/` and check **1440, 1024, 768 and 375 px** for horizontal overflow on all seven routes plus one detail page. Below 768 px, confirm the burger toggles the nav and the `Let's talk` pill stays visible in the bar.

Record what you checked. This is success criterion 11 and it cannot be automated here.

- [ ] **Step 6: Commit**

```bash
git add _sass/_hero.scss _sass/_cards.scss _sass/_layout.scss
git commit -m "feat: responsive behaviour at 1024 and 768

Fixes the inherited 500px card-grid breakpoint by using the tokens'
\$bp-md throughout."
```

---

## Task 20: Print stylesheet

Someone will press Ctrl+P on `/cv/` — the site **is** the CV, there is no PDF download. A dark-teal page prints as a black rectangle, or with backgrounds suppressed, as cream text on white paper. Neither is acceptable, so this is a required deliverable.

**Files:**
- Rewrite: `_sass/_print.scss`

- [ ] **Step 1: Write `_sass/_print.scss`**

Full replacement of the placeholder.

```scss
// ---------------------------------------------------------------------------
// Print. The site is the CV — there is no PDF download — so /cv/ must print
// as black text on white paper, not as a dark rectangle.
// ---------------------------------------------------------------------------

@media print {
  html,
  body {
    background: #fff !important;
    color: #000 !important;
    font-size: 11pt;
  }

  // Chrome and decoration: gone.
  .site-header,
  .site-footer,
  .skip-link,
  .nav,
  .nav__toggle,
  .nav__burger,
  .pill,
  .btn,
  .hero__glow,
  .hero__grid,
  .card__ring,
  .glyph,
  .invert,
  .closing {
    display: none !important;
  }

  main { display: block; }

  // Flatten every alpha surface and amber fill to paper.
  .card,
  .metric,
  .detail__citation,
  .prose pre {
    background: none !important;
    border: 1px solid #999 !important;
    border-radius: 0 !important;
  }

  h1, h2, h3, h4,
  .page-title__h1,
  .heading-row__title,
  .card__title,
  .cv-role,
  .row__title {
    color: #000 !important;
  }

  p,
  li,
  .prose,
  .card__body,
  .page-title__lede,
  .cv-note,
  .cv ul {
    color: #000 !important;
  }

  // Colour cannot carry hierarchy on paper — weight and size must.
  .kicker,
  .cv-date {
    color: #000 !important;
    font-weight: 700;
    letter-spacing: 0.08em;
  }

  .cv-org,
  .row__date,
  .row__meta,
  .detail__meta,
  .cv-cat,
  .heading-row__eyebrow {
    color: #333 !important;
  }

  .metric__value { color: #000 !important; }

  a {
    color: #000 !important;
    border-bottom: 0 !important;
    text-decoration: underline;
  }

  // Expand external URLs, which are otherwise lost on paper.
  a[href^="http"]::after,
  a[href^="mailto:"]::after {
    content: " (" attr(href) ")";
    font-size: 9pt;
    word-break: break-all;
  }

  // Chips become plain comma-separated text — filled pills waste ink and
  // read as boxes.
  .cv-chips,
  .chips {
    display: block;
    padding: 0;
  }

  .cv-chips li,
  .chips li {
    display: inline;
    padding: 0;
    background: none !important;
    border-radius: 0;
    color: #000 !important;

    &::after { content: ", "; }
    &:last-child::after { content: ""; }
  }

  // Never split a CV entry across a page.
  .cv-date,
  .cv-role,
  .cv-org,
  .cv h2,
  .card,
  .row {
    break-inside: avoid;
    page-break-inside: avoid;
  }

  .cv-date { break-before: auto; }

  .cv h2 {
    break-after: avoid;
    page-break-after: avoid;
  }

  .band,
  .page-title,
  .cv {
    padding: 0 !important;
  }
}
```

- [ ] **Step 2: Verify the print rules compiled and invert correctly**

This is success criterion 6.

```bash
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jbuild
python3 - <<'PY'
import re, pathlib
css = pathlib.Path('_site/assets/css/main.css').read_text()
blocks = re.findall(r'@media print\{(.*?)\}(?=@media|$)', css, re.S)
block = max(blocks, key=len) if blocks else ''
print("print block found:", bool(block), "chars:", len(block))
checks = {
    "white ground": '#fff' in block,
    "black text": '#000' in block,
    "header hidden": '.site-header' in block,
    "inverted amber block hidden": '.invert' in block,
    "glow hidden": 'hero__glow' in block,
    "rings hidden": 'card__ring' in block,
    "url expansion": 'attr(href)' in block,
    "chips inlined": 'cv-chips' in block,
    "break-inside guard": 'break-inside' in block,
    "no teal ground survives": '#08302a' not in block.lower(),
}
for k, v in checks.items():
    print(("PASS " if v else "FAIL ") + k)
PY
```

Expected: every line `PASS`. If `print block found` is `False`, `@import "print"` is missing from `main.scss` — check Task 4 Step 7.

- [ ] **Step 3: Eyeball the print preview**

```bash
python3 -m http.server 4000 --directory _site
```

Open `http://localhost:4000/cv/`, press Ctrl+P, and confirm: white paper, black text, no amber block, skills as comma-separated text rather than pills, and no CV entry split across a page boundary. Do the same on one detail page.

- [ ] **Step 4: Commit**

```bash
git add _sass/_print.scss
git commit -m "feat: print stylesheet inverting the dark ground to paper

The site is the CV, so Ctrl+P on /cv/ has to produce something usable."
```

---

## Task 21: Full verification sweep

Run all seventeen success criteria against a clean build. Every criterion here is **structural** — these assertions can prove the CSS is under budget, the links resolve, the contrast maths is right and the counts are derived. **They cannot prove the site looks good.** That is why Task 21 ends in a human review gate, not a merge.

**Files:**
- Create: `docs/superpowers/plans/verification-2026-08-24.txt` (the recorded result)

- [ ] **Step 1: Clean build**

```bash
jclean() { docker run --rm -v "$PWD":/srv/jekyll -w /srv/jekyll ruby:3.2 bash -c "rm -rf _site"; }
jbuild() { docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"; }
jclean && jbuild
```

Expected: `done in N seconds.` with zero warnings about missing layouts or includes. **Criterion 1, part one.**

- [ ] **Step 2: Run criteria 1–4 and 7–16**

```bash
python3 - <<'PY' | tee docs/superpowers/plans/verification-2026-08-24.txt
import pathlib, re, yaml
root = pathlib.Path('_site')
pages = sorted(root.rglob('*.html'))
html_all = {p: p.read_text(errors='ignore') for p in pages}
css = (root / 'assets/css/main.css').read_text()
css_bytes = (root / 'assets/css/main.css').stat().st_size
results = []
def check(n, desc, ok, detail=''):
    results.append((n, desc, ok, detail))

# 1 — page count
check(1, "exactly 53 html pages", len(pages) == 53, f"got {len(pages)}")

# 2 — internal links. GitHub Pages serves extensionless URLs, so try three
# forms; and match both root-relative and absolute hrefs.
site_url = "https://prathmeshrmadhu.github.io"
broken = set()
for p, t in html_all.items():
    for href in re.findall(r'href="([^"#?]+)', t):
        if href.startswith('mailto:') or href.startswith('http') and not href.startswith(site_url):
            continue
        path = href[len(site_url):] if href.startswith(site_url) else href
        if not path.startswith('/'):
            continue
        rel = path.lstrip('/')
        if any((root / c).exists() for c in (rel, rel + 'index.html', rel.rstrip('/') + '/index.html', rel.rstrip('/') + '.html')):
            continue
        broken.add((p.relative_to(root).as_posix(), href))
check(2, "zero broken internal links", not broken, f"{sorted(broken)[:8]}")

# 3 — css budget
check(3, "main.css under 25KB", css_bytes < 25600, f"{css_bytes} bytes (was 102456)")

# 4 — theme residue
residue = {n: sum(t.count(n) for t in html_all.values())
           for n in ('author_profile', 'page__content', 'fa-', 'susy', 'magnific')}
check(4, "no theme residue in built html", all(v == 0 for v in residue.values()), str(residue))

# 7 — derived counts
home = html_all[root / 'index.html']
pubs = len(list(pathlib.Path('_publications').glob('*.md')))
work = len(list(pathlib.Path('_portfolio').glob('*.md')))
home_rows = home.count('class="row')
check(7, "derived counts hold", pubs == 21 and work == 6 and home_rows == 3,
      f"pubs={pubs} work={work} home_rows={home_rows}")

# 8 — the one manual number, exactly once in source. Scan everything that can
# render, not just _pages: the homepage metric caption lives in _layouts.
src_files = [pathlib.Path('_config.yml')]
for d in ('_pages', '_layouts', '_includes', '_data'):
    src_files += [p for p in pathlib.Path(d).rglob('*') if p.is_file()]
occurrences = {p.as_posix(): p.read_text(errors='ignore').count('320+') for p in src_files}
src_320 = sum(occurrences.values())
where = [k for k, v in occurrences.items() if v]
no_27 = not any('>27<' in t for t in html_all.values())
check(8, "320+ exactly once in source, no hardcoded paper count",
      src_320 == 1 and no_27, f"count={src_320} in {where}, hardcoded 27 absent: {no_27}")

# 9 — banned copy
banned = ['advisory', 'practice areas', 'what i can build for you', 'open to collaboration']
found = {b: sum(t.lower().count(b) for t in html_all.values()) for b in banned}
check(9, "banned service-offering copy absent", all(v == 0 for v in found.values()), str(found))

# 10 — /about/ resolves, uniquely
about_claims = [p.relative_to(root).as_posix() for p in pages
                if p.relative_to(root).as_posix() in ('about/index.html', 'about.html')]
check(10, "/about/ resolves and nothing else claims it",
      about_claims == ['about/index.html'], str(about_claims))

# 12 — detail pages
routes = {'index.html','work/index.html','research/index.html','blog/index.html',
          'about/index.html','cv/index.html','contact/index.html','404.html'}
details = [p for p, t in html_all.items()
           if p.relative_to(root).as_posix() not in routes and 'class="detail"' in t]
check(12, "36 detail pages via detail.html", len(details) == 36, f"got {len(details)}")

# 13 — fonts
fonts = sorted(p.name for p in (root / 'assets/fonts').iterdir())
woff2 = [f for f in fonts if f.endswith('.woff2')]
third_party = any('fonts.googleapis' in t or 'fonts.gstatic' in t for t in html_all.values())
check(13, "two families, four woff2, no third-party font requests",
      len(woff2) == 4 and not third_party, f"{woff2}, third_party={third_party}")

# 14 — no images in the body of /. The <head> legitimately references
# mstile-144x144.png and safari-pinned-tab.svg as favicon metadata; both are
# held out of scope and neither is fetched during a normal page load.
home_body = home.split('<body', 1)[1] if '<body' in home else home
img_hits = [n for n in ('<img', '.png', '.jpg', '.jpeg', '.gif', 'background-image: url')
            if n in home_body]
check(14, "zero image requests in the body of /", not img_hits, f"found {img_hits}")

# 15 — no javascript. JSON-LD structured data from seo.html is metadata, not a
# script request, and is excluded.
js = [p.relative_to(root).as_posix() for p in root.rglob('*.js')]
execs = []
for p, t in html_all.items():
    for tag in re.findall(r'<script[^>]*>', t):
        if 'application/ld+json' not in tag:
            execs.append((p.relative_to(root).as_posix(), tag))
check(15, "zero javascript", not js and not execs, f"js={js} executable_scripts={execs[:3]}")

# 16 — research prose
res = html_all[root / 'research/index.html']
intro = res.split('<div class="prose prose--intro">')[1].split('</div>')[0] if 'prose--intro' in res else ''
text = re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', intro)).strip()
probes = ["Concepts to Computational Constructs", "Odeuropa", "SniffyArt", "pulmonary hemosiderophages"]
check(16, "research intro prose survives", all(p in text for p in probes) and len(text) > 1000,
      f"{len(text)} chars; compare to baseline within 5%")

# 17 — row metadata
gaps = []
for coll, keys in (('_publications', ('venue',)), ('_talks', ('type','venue','location')),
                   ('_teaching', ('type','venue','location'))):
    for f in pathlib.Path(coll).glob('*.md'):
        fm = yaml.safe_load(f.read_text().split('---')[1])
        for k in keys:
            if fm.get(k) and str(fm[k]) not in res:
                gaps.append((f.name, k))
paper_gaps = [f.name for f in pathlib.Path('_publications').glob('*.md')
              if (yaml.safe_load(f.read_text().split('---')[1]).get('paperurl') or '') not in res]
check(17, "row metadata complete", not gaps and not paper_gaps, f"meta={gaps[:5]} paper={paper_gaps[:5]}")

print("PHASE 4 VERIFICATION")
print("=" * 60)
for n, desc, ok, detail in sorted(results):
    print(f"[{'PASS' if ok else 'FAIL'}] {n:>2}. {desc}")
    if detail:
        print(f"          {detail}")
print("=" * 60)
print("failed:", [n for n, _, ok, _ in results if not ok] or "none")
PY
```

Expected: `failed: none`. Criteria 5, 6 and 11 are covered separately in Steps 3–5.

- [ ] **Step 3: Criterion 5 — contrast, measured against the compiled CSS**

Do not trust the spec's numbers, and do not trust this plan's numbers either. The criterion says **re-measured against the compiled CSS**, so this runs in two passes: named design pairs first, then every ink alpha the compiled stylesheet actually declares as a `color`.

```bash
python3 - <<'PY'
import re, pathlib

def lin(c):
    c = c / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def lum(rgb):
    r, g, b = [lin(x) for x in rgb]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
def over(fg, alpha, bg):
    return tuple(fg[i] * alpha + bg[i] * (1 - alpha) for i in range(3))
def ratio(a, b):
    la, lb = lum(a), lum(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)

GROUND = (8, 48, 42)
INK    = (244, 242, 237)
AMBER  = (240, 162, 2)
MINT   = (155, 212, 180)

rows = [
    ("H1 / hero title",      INK,   1.00, GROUND, 3.0),
    ("amber on teal",        AMBER, 1.00, GROUND, 3.0),
    ("lede (ink-70)",        INK,   0.70, GROUND, 4.5),
    ("feature body (68)",    INK,   0.68, GROUND, 4.5),
    ("chip label (64)",      INK,   0.64, GROUND, 4.5),
    ("nav (62)",             INK,   0.62, GROUND, 4.5),
    ("card body (60)",       INK,   0.60, GROUND, 4.5),
    ("metric caption (55)",  INK,   0.55, GROUND, 4.5),
    ("date/eyebrow (52)",    INK,   0.52, GROUND, 4.5),
    ("code strings (mint)",  MINT,  1.00, GROUND, 4.5),
]
bad = []
for name, fg, a, bg, need in rows:
    r = ratio(over(fg, a, bg), bg)
    ok = r >= need
    if not ok: bad.append(name)
    print(f"[{'PASS' if ok else 'FAIL'}] {name:<22} {r:.2f} (need {need})")

# Teal-on-amber, for the inverted block.
for name, alpha, need in [("contact H2 on amber", 1.00, 3.0), ("contact body on amber", 0.82, 4.5)]:
    r = ratio(over(GROUND, alpha, AMBER), AMBER)
    ok = r >= need
    if not ok: bad.append(name)
    print(f"[{'PASS' if ok else 'FAIL'}] {name:<22} {r:.2f} (need {need})")

print("\nnamed-pair failures:", bad or "none")

# --- Pass 2: every ink alpha the compiled CSS actually declares as a colour.
# This is the part that measures what shipped rather than what was designed.
css = pathlib.Path('_site/assets/css/main.css').read_text()
alphas = set()
for m in re.finditer(r'color:\s*rgba\(244,\s*242,\s*237,\s*([0-9.]+)\)', css):
    alphas.add(float(m.group(1)))
print("\nink alphas used as `color` in compiled CSS:", sorted(alphas))
shipped_bad = []
for a in sorted(alphas):
    r = ratio(over(INK, a, GROUND), GROUND)
    ok = r >= 4.5
    if not ok:
        shipped_bad.append((a, round(r, 2)))
    print(f"[{'PASS' if ok else 'FAIL'}] alpha {a:<5} {r:.2f} (need 4.5 for body text)")
print("\nshipped alphas below AA:", shipped_bad or "none")
PY
```

Expected: `named-pair failures: none` and `shipped alphas below AA: none`. `date/eyebrow (52)` should measure about **4.54** — that is the AA floor on this ground and the reason the design's 0.40 and 0.42 values were rejected.

Pass 2 is the authoritative check. **If it flags an alpha, raise the value in `_sass/_tokens.scss`; never lower the threshold in the test.**

Two known false positives to judge rather than blindly fix: `$line`, `$line-soft` and friends are borders, not text, and if any of them ever appears in a `color:` declaration it is a genuine bug worth finding. Large text (≥24px or ≥18.66px bold) legitimately needs only 3:1 — if pass 2 flags an alpha used *exclusively* on an H1 or H2, record the exemption in the verification file with the selector named.

- [ ] **Step 4: Criterion 6 — print**

Already asserted in Task 20 Step 2. Re-run that assertion block against the clean build and record the result.

- [ ] **Step 5: Criterion 11 — no horizontal overflow**

Manual. Serve the site and check all seven routes plus one detail page at 1440, 1024, 768 and 375 px.

```bash
python3 -m http.server 4000 --directory _site
```

Append what you checked, and any overflow found, to `docs/superpowers/plans/verification-2026-08-24.txt`.

- [ ] **Step 6: Commit the verification record**

```bash
git add docs/superpowers/plans/verification-2026-08-24.txt
git commit -m "docs: record Phase 4 verification results"
```

- [ ] **Step 7: Push the branch**

Plain `git push` fails — it authenticates as the wrong GitHub account.

```bash
GIT_SSH_COMMAND="ssh -F /dev/null -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -i $HOME/.ssh/id_ed25519_prathmesh_personal" git push -u origin redesign
```

Expected: the branch is created on the remote. **Do not push to `master` and do not merge.** `master` is what GitHub Pages serves.

- [ ] **Step 8: Hand off for visual review — STOP HERE**

Report to the user:

1. The verification table from Step 2, plus contrast, print, and what you checked manually at each width.
2. `main.css`: 102,456 → the new figure.
3. Shipped JavaScript: 131,019 bytes → 0.
4. Icon fonts: 2.9 MB → 0; self-hosted text fonts ~82 KB.
5. The nav duplication flag from "Before you start" — `Contact` appears both as a nav item and as the `Let's talk` pill, both pointing at `/contact/`. Ask whether to drop one.
6. The three real posts date `2026.03`, `2020.09` and `2020.07`. The design's writing section implies regular output; the reality is one post in 2026 and two from 2020. This is accurate content and ships as-is — flagged so the sparseness reads as expected rather than as a bug.
7. How to review locally: `python3 -m http.server 4000 --directory _site`.

**Then stop.** A human visual review of the `redesign` branch is a merge precondition. Do not merge to `master` without explicit approval.

Once approved, announce: "I'm using the finishing-a-development-branch skill to complete this work." — **REQUIRED SUB-SKILL:** `superpowers:finishing-a-development-branch`.
