# Website Structure and Navigation Implementation Plan (Phase 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Collapse six flat nav items into four coherent sections, rename every URL to match its label with redirects behind it, and delete the unused theme scaffolding.

**Architecture:** Pure Jekyll content and config edits — no new infrastructure. Publications, Talks, and Teaching merge into one `_pages/research.html` that keeps rendering from the same collections, so it cannot drift from `/cv/`. Old URLs survive as `jekyll-redirect-from` entries on the new pages. Verification is a Dockerised Jekyll build plus string and count checks against the built output in `_site`.

**Tech Stack:** Jekyll 3.10 via the `github-pages` gem, Academic Pages / Minimal Mistakes theme, Liquid, `jekyll-redirect-from`, Docker (Ruby is not installed locally).

**Spec:** `docs/superpowers/specs/2026-08-13-website-structure-navigation-design.md`

---

## The build and verification loop

Ruby is not installed locally. All builds run in a container. Define these two helpers once per shell session:

```bash
jbuild() {
  docker run --rm \
    -v "$PWD":/srv/jekyll \
    -v jekyll_gems:/usr/local/bundle \
    -w /srv/jekyll \
    ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"
}

jclean() {
  docker run --rm \
    -v "$PWD":/srv/jekyll \
    -w /srv/jekyll \
    ruby:3.2 bash -c "rm -rf _site"
}
```

Gems are cached in the `jekyll_gems` named volume, so a build takes about 8 seconds.

**`jclean` is mandatory before any deletion check.** Jekyll does not remove stale output, and `_site` is created root-owned by the container, so a host-side `rm -rf _site` fails with a permission error. Any step that verifies a page is *gone* must run `jclean && jbuild`, not `jbuild` alone.

**Baseline counts, captured before any work.** Each is the number of `archive__item-title` elements on the built page:

| Page | Entries now | Entries after |
|---|---|---|
| `_site/publications/index.html` | 21 | — (page removed, becomes a redirect) |
| `_site/talks/index.html` | 3 | — (page removed, becomes a redirect) |
| `_site/teaching/index.html` | 3 | — (page removed, becomes a redirect) |
| `_site/portfolio/index.html` | 6 | — (page removed, becomes a redirect) |
| `_site/year-archive/index.html` | 4 | — (page removed, becomes a redirect) |
| `_site/research/index.html` | absent | 26 (21 publications + 3 talks + 2 teaching) |
| `_site/work/index.html` | absent | 6 |
| `_site/blog/index.html` | absent | 4 |

**Why 26 and not 27:** Task 5 deletes one teaching entry, taking Teaching from 3 to 2.

**The Research page must be `.html`, not `.md`.** This was found the hard way during execution — the original plan said `.md` and that produced broken output.

`archive-single-talk.html` ends with `{% if post.excerpt %}<p …>{{ post.excerpt | markdownify }}</p>{% endif %}`. `markdownify` emits a trailing blank line *inside* the surrounding `<div>`. In a markdown page, a blank line terminates kramdown's raw-HTML block, so the include's own closing `</article>` and `</div>` are then parsed as markdown text and escaped to `&lt;/article&gt;` — malformed DOM, one per talk. Worse, everything after that point stops being treated as markdown, so a following `## Teaching` heading survives into the output as literal text.

Writing the page as `.html` avoids kramdown entirely, which is exactly the context the old `_pages/talks.html` had. Consequences for this plan: the framing prose is written as `<p>` elements, and the three section headings are written as explicit `<h2 id="…" class="archive__subtitle">` rather than relying on kramdown auto-ids.

`_pages/publications.md` and `_pages/teaching.html` were both safe in either context because `archive-single.html` does not markdownify an excerpt in a way that breaks the block. `/cv/` is also unaffected — it uses `archive-single-talk-cv.html`, verified to emit 0 escaped tags.

---

### Task 1: Rename the portfolio page to `/work/` and give the case studies an explicit order

The portfolio loop has no sort key, so Jekyll emits entries in filename order — alphabetically. That puts the 9× SLAM result fifth and lands tf-cnnvis last only because of the letter "t".

**Files:**
- Rename: `_pages/portfolio.html` → `_pages/work.html`
- Modify: all six `_portfolio/*.md` (add `order:`)

- [ ] **Step 1: Confirm the current alphabetical ordering**

```bash
grep -o 'rel="permalink"' _site/portfolio/index.html | wc -l
python3 -c "
import re
h=open('_site/portfolio/index.html').read()
print(re.findall(r'archive__item-title\" itemprop=\"headline\">\s*<a href=\"([^\"]+)\"',h))
"
```

Expected: `6`, then six `/portfolio/…` URLs in alphabetical order beginning with `agentic-systems-in-a-regulated-domain`.

- [ ] **Step 2: Rename the file with git so history follows**

```bash
git mv _pages/portfolio.html _pages/work.html
```

- [ ] **Step 3: Replace the contents of `_pages/work.html`**

```liquid
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
{% for post in ordered_work %}
  {% include archive-single.html %}
{% endfor %}
```

The `assign` is required, not stylistic. Liquid's `for` tag parses its collection expression with `Expression.parse`, which handles variable lookups and literals but **not filters**, so `{% for post in site.portfolio | sort: 'order' %}` silently does nothing. (The repo already contains that mistake at `_includes/group-by-array:21`, inherited from the theme. Leave it alone — out of scope.)

- [ ] **Step 4: Add `order:` to each case study**

Insert one line after the `collection: portfolio` line in each file. Values must be unquoted integers so Jekyll sorts them numerically rather than as strings.

| File | Line to add |
|---|---|
| `_portfolio/real-time-slam-on-edge-hardware.md` | `order: 1` |
| `_portfolio/defect-detection-where-models-plateau.md` | `order: 2` |
| `_portfolio/agentic-systems-in-a-regulated-domain.md` | `order: 3` |
| `_portfolio/hybrid-multimodal-retrieval.md` | `order: 4` |
| `_portfolio/llm-survey-analysis-at-research-scale.md` | `order: 5` |
| `_portfolio/tf-cnnvis-open-source-cnn-visualisation.md` | `order: 6` |

So for example `_portfolio/real-time-slam-on-edge-hardware.md` becomes:

```yaml
---
title: "Real-time visual SLAM on edge hardware"
excerpt: "..."
collection: portfolio
order: 1
---
```

Leave every `title` and `excerpt` exactly as it is.

- [ ] **Step 5: Rebuild clean and verify the new order**

```bash
jclean && jbuild
python3 -c "
import re
h=open('_site/work/index.html').read()
for u in re.findall(r'archive__item-title\" itemprop=\"headline\">\s*<a href=\"([^\"]+)\"',h): print(u)
"
```

Expected, in exactly this sequence:

```
/portfolio/real-time-slam-on-edge-hardware/
/portfolio/defect-detection-where-models-plateau/
/portfolio/agentic-systems-in-a-regulated-domain/
/portfolio/hybrid-multimodal-retrieval/
/portfolio/llm-survey-analysis-at-research-scale/
/portfolio/tf-cnnvis-open-source-cnn-visualisation/
```

Note the individual entry URLs still contain `/portfolio/` — that is correct and intended. The collection permalink in `_config.yml` is unchanged; only the index page moved. Do not "fix" these.

- [ ] **Step 6: Verify the old URL redirects and the old page is gone**

```bash
test -f _site/work/index.html && echo "work: OK" || echo "work: MISSING"
grep -o 'http-equiv="refresh"[^>]*' _site/portfolio/index.html
```

Expected: `work: OK`, then a refresh meta tag pointing at `/work/`.

- [ ] **Step 7: Commit**

```bash
git add _pages/work.html _portfolio/
git commit -m "Move portfolio index to /work/ with an explicit case-study order"
```

---

### Task 2: Rename the blog archive to `/blog/`

`/year-archive/` leaks a theme implementation detail into the address bar.

**Files:**
- Rename: `_pages/year-archive.html` → `_pages/blog.html`

- [ ] **Step 1: Rename the file with git**

```bash
git mv _pages/year-archive.html _pages/blog.html
```

- [ ] **Step 2: Change only the front matter of `_pages/blog.html`**

The body — the year-grouping Liquid — stays exactly as it is. Replace the front matter block with:

```yaml
---
layout: archive
permalink: /blog/
title: "Blog posts"
author_profile: true
redirect_from:
  - /year-archive/
  - /wordpress/blog-posts/
---
```

`/wordpress/blog-posts/` is an **existing** redirect that the old file already declared. Dropping it would break a URL that currently resolves. Carry it over.

`author_profile: true` was already on this file and is preserved. Sidebar decisions are Phase 3, so it is not touched either way.

- [ ] **Step 3: Rebuild clean and verify**

```bash
jclean && jbuild
grep -c 'archive__item-title' _site/blog/index.html
grep -o 'id="20[0-9][0-9]"' _site/blog/index.html
grep -o 'http-equiv="refresh"[^>]*' _site/year-archive/index.html
grep -o 'http-equiv="refresh"[^>]*' _site/wordpress/blog-posts/index.html
```

Expected: `4`, then `id="2020"` and `id="2026"` (the year headings still group correctly), then two refresh tags pointing at `/blog/`.

- [ ] **Step 4: Commit**

```bash
git add _pages/blog.html
git commit -m "Move blog archive to /blog/, preserving the wordpress redirect"
```

---

### Task 3: Write the Research framing text

Written as its own task, before the page is assembled, because this is the only prose in Phase 2 and it deserves review on its own terms.

**Files:**
- Create: `/tmp/research-framing.md` (scratch, outside the repo)

The scratch file goes in `/tmp`, **not** in `_pages/`. `_pages` is listed under `include:` in `_config.yml`, and Jekyll copies any file it does not recognise as a page straight through to `_site` as a static asset — so a draft parked there would be published.

- [ ] **Step 1: Write the draft to a scratch file**

Write this to `/tmp/research-framing.md`:

```markdown
My doctoral work, at the [Chair of Pattern Recognition](https://lme.tf.fau.de/) at FAU Erlangen-Nürnberg, asked what happens to computer vision when you point it at images that were never photographs. The dissertation — *Concepts to Computational Constructs: Advanced Scene Understanding for Heterogeneous Artworks Using Deep Learning* — worked across art history, classical archaeology, and Christian archaeology, where the objects of study are paintings, vase decorations, and iconographic programmes rather than camera output.

That distinction is not cosmetic. Detection and pose estimation models inherit their priors from photographic data, so they fail on artwork in ways that are specific and instructive: a figure on an ancient vase is rendered by convention, not by projection. Labels are scarce, because producing them requires an art historian. And an art historian has no use for a prediction they cannot interrogate.

Those three constraints shaped the work — pose estimation on vase paintings through perceptually-grounded style transfer, one-shot detection for heterogeneous artwork collections, and ICC and ICC++, which learn image composition as an explainable feature. The point of the latter was to recover the compositional structures art historians already reason about, in a form that lets them check the machine's reasoning against their own.

The same three constraints recur across the rest of my publications: olfactory object recognition for the Odeuropa project, and mammography and cytology work where annotation is expensive and an unexplainable classifier is unusable.
```

Every factual claim here is checkable against files already in the repo: the dissertation title and FAU venue against `_publications/…concepts-to-computational-constructs….md`, the pose-estimation and one-shot claims against `_publications/` titles, ICC++ against its own entry, and Odeuropa/ODOR and the mammography and cytology papers against the remaining entries.

- [ ] **Step 2: Verify no claim is unsupported**

```bash
grep -il 'perceptually-grounded style transfer' _publications/*
grep -il 'One-Shot Object Detection in Heterogeneous' _publications/*
grep -il 'ICC++' _publications/*
grep -ilE 'olfactory|odeuropa|ODOR' _publications/* | wc -l
grep -ilE 'mammogra|cytology|breast' _publications/* | wc -l
```

Expected: a filename for each of the first three, then a count of at least 3 for the olfactory group and at least 5 for the medical group.

- [ ] **Step 3: Ask the user to read the four paragraphs before they are published**

Show the draft. Two specific things to raise:

1. The publication list has a substantial medical-imaging cluster — roughly seven papers on mammography, breast density, and cytology. A framing that spoke only about art history would misrepresent what a reader actually sees below it, which is why the closing paragraph names that thread. Confirm that framing is right.
2. The paragraph claims his art-historical work and his medical-imaging work share one methodological through-line. That is an interpretive claim about his own research, not a fact from a file. He should agree with it before it goes on the site.

Do not proceed to Task 4 until the text is approved. There is no commit in this task; the draft is scratch.

---

### Task 4: Create `/research/` and retire the three pages it replaces

**Files:**
- Create: `_pages/research.html`
- Delete: `_pages/publications.md`, `_pages/talks.html`, `_pages/teaching.html`, `/tmp/research-framing.md`

- [ ] **Step 1: Create `_pages/research.html`**

Use the approved framing text from Task 3. This is the file as actually built and verified:

```liquid
---
layout: archive
title: "Research"
permalink: /research/
author_profile: true
redirect_from:
  - /publications/
  - /talks/
  - /teaching/
---

{% include base_path %}

<p>My doctoral work, at the <a href="https://lme.tf.fau.de/">Chair of Pattern Recognition</a> at FAU Erlangen-Nürnberg, asked what happens to computer vision when you point it at images that were never photographs. The dissertation — <em>Concepts to Computational Constructs: Advanced Scene Understanding for Heterogeneous Artworks Using Deep Learning</em> — worked across art history, classical archaeology, and Christian archaeology, where the objects of study are paintings, vase decorations, and iconographic programmes rather than camera output.</p>

<p>That distinction is not cosmetic. Detection and pose estimation models inherit their priors from photographic data, so they fail on artwork in ways that are specific and instructive: a figure on an ancient vase is rendered by convention, not by projection. Labels are scarce, because producing them requires an art historian. And an art historian has no use for a prediction they cannot interrogate.</p>

<p>Those constraints shaped the work — pose estimation on vase paintings through perceptually-grounded style transfer, one-shot detection for heterogeneous artwork collections, and ICC and ICC++, which learn image composition as an explainable feature. The point of the latter was to recover the compositional structures art historians already reason about, in a form that lets them check the machine's reasoning against their own.</p>

<p>I was also part of the computer vision team on <a href="https://odeuropa.eu/odeuropa-team/">Odeuropa</a>, a European research project on olfactory heritage, where the vision problem was to find references to smell in historical images — the objects that carry scent, and the people caught in the act of smelling. That work produced the ODOR dataset for olfactory object detection, SniffyArt for smelling persons, and the ODOR challenge at ICPR 2022. The targets are small, densely packed, and scattered across the frame, which makes olfactory reference detection a genuinely hard detection problem quite apart from its interest to historians.</p>

<p>A separate thread runs through medical imaging: quantifying pulmonary hemosiderophages in cytology slides, and a series of mammography papers on breast density, luminal subtype, calcification, and abnormality classification in contrast-enhanced spectral mammography. The methods there are transfer learning and augmentation — attention-guided erasing, random histogram equalization, and a neighbourhood representation loss.</p>

<h2 id="publications" class="archive__subtitle">Publications</h2>

<p>For the full list of academic publications, check out my <a href="https://lme.tf.fau.de/person/madhu/">official-webpage</a>, <a href="https://scholar.google.co.in/citations?user=tEe1-TYAAAAJ&amp;hl=en">Google Scholar</a> profile.</p>

{% for post in site.publications reversed %}
  {% include archive-single.html %}
{% endfor %}

<h2 id="talks" class="archive__subtitle">Talks</h2>

{% for post in site.talks reversed %}
  {% include archive-single-talk.html %}
{% endfor %}

<h2 id="teaching" class="archive__subtitle">Teaching</h2>

{% for post in site.teaching reversed %}
  {% include archive-single.html %}
{% endfor %}
```

Four things are deliberate. The page is `.html` for the kramdown reason given in the verification-loop section above. The headings carry explicit `id` and `class="archive__subtitle"` because there is no kramdown to auto-generate them. The publications intro line is verbatim from `_pages/publications.md` — the only prose on any of the merged pages — with its `&` escaped to `&amp;` now that it is raw HTML. And Talks uses `archive-single-talk.html` while the other two use `archive-single.html`, which is correct: the talk include renders venue and date differently. All three loops keep `reversed`.

- [ ] **Step 2: Delete the three replaced pages and the scratch draft**

```bash
git rm _pages/publications.md _pages/talks.html _pages/teaching.html
rm -f /tmp/research-framing.md
```

- [ ] **Step 3: Rebuild clean and verify entry counts**

```bash
jclean && jbuild
grep -c 'archive__item-title' _site/research/index.html
```

Expected: `27` at this point — 21 publications + 3 talks + 3 teaching. Task 5 removes the tuition entry and brings this to 26. If you get 27 here, that is correct, not a bug.

- [ ] **Step 4: Verify the three section headings exist with anchor ids**

```bash
grep -o 'id="publications"\|id="talks"\|id="teaching"' _site/research/index.html
```

Expected: all three ids. kramdown auto-generates them from the `##` headings. If any is missing, the heading was written as HTML rather than markdown — fix the heading, do not hand-write an id.

- [ ] **Step 5: Verify the framing text rendered as prose, not as a code block**

```bash
grep -c 'Concepts to Computational Constructs' _site/research/index.html
grep -o '<pre>' _site/research/index.html | wc -l
```

Expected: `1`, then `0`. A non-zero `<pre>` count means kramdown treated indented include output as a code block — the opposite of what the baseline note predicts, and worth stopping to investigate rather than working around.

- [ ] **Step 6: Verify all three old URLs redirect**

```bash
for p in publications talks teaching; do
  printf "%-14s " "$p"; grep -o 'url=[^"]*' _site/$p/index.html | head -1
done
```

Expected: each prints a URL ending `/research/`.

- [ ] **Step 7: Commit**

```bash
git add _pages/research.html
git commit -m "Merge publications, talks, and teaching into a framed /research/ page"
```

---

### Task 5: Drop the 2011 tuition entry

Fifteen years old, and high-school tutoring sits oddly beside an FAU computer vision TA role.

**Files:**
- Delete: `_teaching/personal-coaching-2014.md`

- [ ] **Step 1: Confirm what is about to be deleted**

```bash
cat _teaching/personal-coaching-2014.md
```

Expected: title "Assistant Tutor Personal Coaching", venue "Jharna Tuition Class", date 2011-02-01. If the file does not match this, stop — the wrong entry is about to go.

- [ ] **Step 2: Delete it**

```bash
git rm _teaching/personal-coaching-2014.md
```

- [ ] **Step 3: Rebuild clean and verify it is gone from all three places it appeared**

```bash
jclean && jbuild
grep -rl 'Jharna' _site/ | wc -l
grep -c 'archive__item-title' _site/research/index.html
grep -c 'Teaching Assistant' _site/cv/index.html
```

Expected: `0`, then `26`, then a non-zero count — the CV still renders its teaching loop, now with two entries.

- [ ] **Step 4: Commit**

```bash
git commit -m "Remove the 2011 tuition entry from teaching"
```

---

### Task 6: Cut navigation from six items to four

**Files:**
- Modify: `_data/navigation.yml`

- [ ] **Step 1: Replace the whole file**

The current file has six entries and a trailing-whitespace artifact on the teaching line. Replacing wholesale is correct here because five of the six entries change.

```yaml
# main links links
main:
  - title: "Selected Work"
    url: /work/

  - title: "Research"
    url: /research/

  - title: "Blog"
    url: /blog/

  - title: "CV"
    url: /cv/
```

- [ ] **Step 2: Rebuild and verify the masthead has exactly four links**

```bash
jbuild
python3 -c "
import re
h=open('_site/index.html').read()
m=re.search(r'visible-links\">(.*?)</ul>',h,re.S).group(1)
print(re.findall(r'href=\"([^\"]*)\">([^<]*)</a>',m))
"
```

Expected: five pairs — the site title linking `/`, then `/work/`, `/research/`, `/blog/`, `/cv/`. The site title is part of the masthead template, not the nav data, so five is correct.

- [ ] **Step 3: Commit**

```bash
git add _data/navigation.yml
git commit -m "Reduce navigation to Selected Work, Research, Blog, and CV"
```

---

### Task 7: Point the landing page at the new URLs

`_pages/about.md` links `/portfolio/`, `/publications/`, `/talks/`, `/teaching/`, and `/year-archive/`. All five now resolve only through a redirect. Internal links should go direct.

**Files:**
- Modify: `_pages/about.md:21-24`

- [ ] **Step 1: Replace the two routing bullets**

Find:

```markdown
* **[Selected work](/portfolio/)** — what I've built, and what it measurably did
* **[Research](/publications/)** — publications, [talks](/talks/), and [teaching](/teaching/)
```

Replace with:

```markdown
* **[Selected work](/work/)** — what I've built, and what it measurably did
* **[Research](/research/)** — publications, talks, and teaching
```

The three separate links collapse into one because talks and teaching are now sections of the same page. Do not link them as `/research/#talks` anchors; a reader who lands on `/research/` sees all three sections.

- [ ] **Step 2: Update the blog link in the closing paragraph**

Find `[write occasionally](/year-archive/)` and change it to `[write occasionally](/blog/)`. Leave the rest of that sentence and the Descartes line untouched.

- [ ] **Step 3: Rebuild and verify no stale internal links remain on the landing page**

```bash
jbuild
grep -o 'href="/\(portfolio\|publications\|talks\|teaching\|year-archive\)/"' _site/index.html | wc -l
grep -o 'href="/\(work\|research\|blog\)/"' _site/index.html | sort -u
grep -c 'Cogito, ergo sum' _site/index.html
```

Expected: `0`, then the three new hrefs, then `1`.

- [ ] **Step 4: Commit**

```bash
git add _pages/about.md
git commit -m "Route landing page links to the new section URLs"
```

---

### Task 8: Delete the six orphaned theme pages and their dependencies

Two of these deletions break the site if done naively. Both fixes are in this task, not deferred.

**Files:**
- Delete: `_pages/category-archive.html`, `_pages/tag-archive.html`, `_pages/page-archive.html`, `_pages/collection-archive.html`, `_pages/sitemap.md`, `_pages/talkmap.html`, `talkmap/`, `talkmap.py`, `talkmap.ipynb`
- Modify: `_includes/footer/custom.html`, `_config.yml:22`, `_config.yml:288-293`

- [ ] **Step 1: Confirm the current state, including the two dependencies**

```bash
grep -c 'rel="tag"' _site/posts/2026/03/31/information-overload/index.html
grep -o 'href="/sitemap/"' _site/index.html | wc -l
```

Expected: `3` (the post renders three tag links), then `1` (the footer sitemap link is on the landing page). These are the two things about to break if the dependencies are not handled.

- [ ] **Step 2: Delete the pages and the talkmap assets**

```bash
git rm _pages/category-archive.html _pages/tag-archive.html \
       _pages/page-archive.html _pages/collection-archive.html \
       _pages/sitemap.md _pages/talkmap.html
git rm -r talkmap
git rm talkmap.py talkmap.ipynb
```

Keep `_pages/404.md`.

- [ ] **Step 3: Empty the footer snippet but keep the file**

`_layouts/default.html:23` does `{% include footer/custom.html %}`, and Jekyll raises a build error on a missing include. So the file stays; only the anchor goes. `_includes/footer/custom.html` becomes exactly:

```html
<!-- start custom footer snippets -->
<!-- end custom footer snippets -->
```

- [ ] **Step 4: Remove the archive config that generates links to the deleted pages**

`_includes/page__taxonomy.html` renders tag links on every post whenever `site.tag_archive.type` is set. Leaving these keys with the pages deleted produces links to a 404 on every post — the theme warns about exactly this at `_config.yml:283`.

Delete these six lines from `_config.yml`:

```yaml
category_archive:
  type: liquid
  path: /categories/
tag_archive:
  type: liquid
  path: /tags/
```

Leave the surrounding `# Archives` comment block in place — it is inert, and removing it is not required to make this work.

- [ ] **Step 5: Remove the talkmap config key**

Delete this line from `_config.yml` (line 22):

```yaml
talkmap_link             : false #change to true to add link to talkmap on talks page
```

The only thing that read it was `_pages/talks.html`, which Task 4 already deleted.

- [ ] **Step 6: Rebuild clean and verify all six pages are gone**

```bash
jclean && jbuild
for p in categories tags page-archive collection-archive sitemap; do
  printf "%-20s " "$p"
  test -e _site/$p && echo PRESENT || echo absent
done
printf "%-20s " talkmap.html; test -e _site/talkmap.html && echo PRESENT || echo absent
printf "%-20s " talkmap/; test -e _site/talkmap && echo PRESENT || echo absent
```

Expected: `absent` on all seven.

- [ ] **Step 7: Verify no page links to anything deleted, and that tags no longer render**

```bash
grep -rlo 'href="/sitemap/"' _site/ | wc -l
grep -rlo 'href="[^"]*/tags/' _site/ | wc -l
grep -rlo 'href="[^"]*/categories/' _site/ | wc -l
grep -c 'rel="tag"' _site/posts/2026/03/31/information-overload/index.html
```

Expected: `0`, `0`, `0`, then `0` — the last one confirming the intended, user-confirmed consequence that posts no longer display tags.

Note `sitemap.xml` at the site root is generated by the `jekyll-sitemap` plugin and is unrelated to the deleted `/sitemap/` page. It should still exist:

```bash
test -f _site/sitemap.xml && echo "sitemap.xml: OK"
```

- [ ] **Step 8: Commit**

```bash
git add -u _config.yml _includes/footer/custom.html
git commit -m "Delete unused theme archive pages and the config that linked to them"
```

---

### Task 9: Correct the Banerjee post permalink

Optional and skippable — cosmetic only. The post is dated 2020-07-12 but published at `/posts/2012/08/rip-banerjee-sir/`. Included because the redirect machinery is already being touched. **If the user declined this in review, skip straight to Task 10.**

**Files:**
- Modify: `_posts/2020-07-12-rip-banerjee-sir.md`

- [ ] **Step 1: Change the permalink and leave a redirect**

Replace the front matter with:

```yaml
---
title: 'Rest in Peace, Banerjee Sir.'
date: 2020-07-12
permalink: /posts/2020/07/12/rip-banerjee-sir/
redirect_from:
  - /posts/2012/08/rip-banerjee-sir/
tags:
  - personal
---
```

Leave the post body untouched.

- [ ] **Step 2: Rebuild clean and verify both URLs resolve**

```bash
jclean && jbuild
test -f _site/posts/2020/07/12/rip-banerjee-sir/index.html && echo "new: OK"
grep -o 'url=[^"]*' _site/posts/2012/08/rip-banerjee-sir/index.html | head -1
grep -c 'archive__item-title' _site/blog/index.html
```

Expected: `new: OK`, a refresh URL ending in the 2020 path, then `4`.

- [ ] **Step 3: Commit**

```bash
git add _posts/2020-07-12-rip-banerjee-sir.md
git commit -m "Correct the Banerjee post permalink to match its date"
```

---

### Task 10: Full-site verification against the success criteria

**Files:** none modified — this task only reads.

- [ ] **Step 1: Clean build with no errors**

```bash
jclean && jbuild
```

Expected: `done in N seconds`, with no `Error:` and no `Warning:` lines.

- [ ] **Step 2: Verify the four new pages and their entry counts**

```bash
printf "research %s\n" "$(grep -c 'archive__item-title' _site/research/index.html)"
printf "work     %s\n" "$(grep -c 'archive__item-title' _site/work/index.html)"
printf "blog     %s\n" "$(grep -c 'archive__item-title' _site/blog/index.html)"
test -f _site/cv/index.html && echo "cv       OK"
python3 -c "
import re
h=open('_site/index.html').read()
m=re.search(r'visible-links\">(.*?)</ul>',h,re.S).group(1)
print('nav items:', re.findall(r'href=\"([^\"]*)\">([^<]*)</a>',m))
"
```

Expected: `research 26`, `work 6`, `blog 4`, `cv OK`, then five nav pairs — the site title plus the four sections.

- [ ] **Step 3: Verify every old URL redirects**

```bash
for p in portfolio publications talks teaching year-archive wordpress/blog-posts; do
  printf "%-22s " "$p"
  grep -o 'url=[^"]*' "_site/$p/index.html" 2>/dev/null | head -1 || echo "NO REDIRECT"
done
```

Expected: six redirect URLs, pointing at `/work/`, `/research/` ×3, and `/blog/` ×2.

- [ ] **Step 4: Verify the CV still renders every section**

The CV was fully rebuilt in Phase 1 and must not have regressed.

```bash
for s in Education Experience Skills Publications Talks Teaching; do
  printf "%-14s %s\n" "$s" "$(grep -c ">$s<\|>$s\b" _site/cv/index.html)"
done
```

Expected: a non-zero count for all six.

- [ ] **Step 5: Run an internal link check across the whole built site**

```bash
python3 - <<'PY'
import os, re, urllib.parse
root = '_site'
pages = []
for d, _, fs in os.walk(root):
    for f in fs:
        if f.endswith('.html'):
            pages.append(os.path.join(d, f))

def exists(p):
    p = p.split('#')[0].split('?')[0]
    if not p or p == '/':
        return os.path.isfile(os.path.join(root, 'index.html'))
    fs = os.path.join(root, p.lstrip('/'))
    return (os.path.isfile(fs) or os.path.isfile(fs + '.html')
            or os.path.isfile(os.path.join(fs, 'index.html')))

broken = {}
for pg in pages:
    html = open(pg, encoding='utf-8', errors='ignore').read()
    for href in re.findall(r'(?:href|src)="([^"]+)"', html):
        if href.startswith(('http', 'mailto:', 'data:', '#', '//')):
            continue
        if not href.startswith('/'):
            continue
        if not exists(urllib.parse.unquote(href)):
            broken.setdefault(href, set()).add(os.path.relpath(pg, root))

imgs = {h: v for h, v in broken.items() if re.search(r'\.(png|jpg|jpeg|ico|gif|svg|webp)$', h, re.I)}
pgs  = {h: v for h, v in broken.items() if h not in imgs}
print('broken PAGE links :', len(pgs))
for h, v in sorted(pgs.items()):
    print('   ', h, '<-', sorted(v)[:3])
print('broken IMAGE refs :', len(imgs), '(pre-existing favicon debt, Phase 3)')
PY
```

Expected: `broken PAGE links : 0`. The image count will be non-zero — those are the 13 favicon references in `_includes/head/custom.html` pointing at images that have never existed in this repo. They are pre-existing and explicitly out of scope.

- [ ] **Step 6: Verify the deleted pages 404 and nothing links to them**

```bash
for p in categories tags page-archive collection-archive sitemap talkmap.html; do
  printf "%-20s " "$p"; test -e "_site/$p" && echo PRESENT || echo absent
done
grep -rl 'Jharna' _site/ | wc -l
```

Expected: `absent` six times, then `0`.

- [ ] **Step 7: Visual check in a browser**

Start the server and look at all four pages plus one entry page from each collection:

```bash
docker run --rm -p 4000:4000 \
  -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle \
  -w /srv/jekyll ruby:3.2 \
  bash -c "bundle exec jekyll serve --host 0.0.0.0"
```

Check `/`, `/work/`, `/research/`, `/blog/`, `/cv/`. Confirm by eye: nav shows four items; `/research/` opens with the framing prose and then three headed sections; `/work/` lists SLAM first and tf-cnnvis last; the footer no longer shows a Sitemap link.

- [ ] **Step 8: Report to the user and ask before pushing**

Summarise what changed and what the verification showed. Do not push without being asked.

When asked, push needs the personal SSH key — a plain `git push` authenticates as the wrong GitHub account and is denied:

```bash
GIT_SSH_COMMAND='ssh -F /dev/null -i ~/.ssh/id_ed25519_prathmesh_personal -o IdentitiesOnly=yes' \
  git push origin master
```

- [ ] **Step 9: Verify the live site once GitHub Pages has rebuilt**

```bash
for u in / work/ research/ blog/ cv/ portfolio/ publications/ talks/ teaching/ year-archive/; do
  printf "%-16s %s\n" "$u" "$(curl -s -o /dev/null -w '%{http_code}' -L "https://prathmeshrmadhu.github.io/$u")"
done
```

Expected: `200` for all ten — the last five resolving through their redirects because of `-L`.

---

## Known risks

**The `sort: 'order'` filter is silent when it fails.** If `order:` is quoted in YAML it becomes a string and sorts lexicographically, which happens to look correct for values 1–6 but would break at 10. Task 1 Step 4 specifies unquoted integers; Step 5 verifies the actual rendered sequence rather than trusting the filter.

**Deleting `tag_archive` changes how posts look.** This is a user-confirmed forced consequence of removing `/tags/`, not an independent decision. Posts will no longer display their tags. The `tags:` front matter stays in the post files, so this is reversible by restoring the config and the page.

**Stale `_site` output produces false passes.** Jekyll never deletes old output. Any check that a page is *gone* must follow `jclean`, and `jclean` must run inside the container because `_site` is root-owned. A deletion check run after a plain `jbuild` will report PRESENT for something already deleted.

**`/research/` and `/cv/` still render the same three collections.** This is intended, not duplication to fix: the CV is the complete formal record, `/research/` is the framed reading. The framing paragraph in Task 3 is what makes them different documents. Do not "resolve" this by removing the CV loops — that would reintroduce the drift Phase 1 fixed.

**Publications are still unreconciled against Google Scholar.** Scholar blocks automated fetching; the user is doing this comparison himself. Nothing in this plan should attempt it.
