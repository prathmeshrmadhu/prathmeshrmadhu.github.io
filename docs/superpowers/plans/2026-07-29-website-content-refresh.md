# Website Content Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring every page of `prathmeshrmadhu.github.io` up to date, remove theme placeholder content, and add the first two case studies so the site serves both research and industry readers.

**Architecture:** Plain markdown edits in place, following the existing Academic Pages collection structure. No new infrastructure. Repeating content (publications, talks, teaching) is rendered on the CV page from the same collections that feed the standalone pages, so those sections cannot drift. Verification is a Dockerised Jekyll build plus string checks against the built output.

**Tech Stack:** Jekyll 3 (`github-pages` gem), Liquid, Minimal Mistakes / Academic Pages theme, Docker (Ruby 3.2 container — Ruby is not installed on this machine).

**Spec:** `docs/superpowers/specs/2026-07-29-website-content-refresh-design.md`

---

## The build and verification loop

Ruby is not installed locally. All builds run in a container. Define this helper once per shell session:

```bash
jbuild() {
  docker run --rm \
    -v "$PWD":/srv/jekyll \
    -v jekyll_gems:/usr/local/bundle \
    -w /srv/jekyll \
    ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"
}
```

Gems are cached in the `jekyll_gems` named volume, so the first run takes a few minutes and subsequent runs about 8 seconds.

**Fallback:** if Task 1's config fix does not resolve the repo-name error, add `-e PAGES_REPO_NWO=prathmeshrmadhu/prathmeshrmadhu.github.io` to the `docker run` line. This is confirmed to work.

**Baseline before any work** (all of these currently indicate breakage):

| Check | Current | Target |
|---|---|---|
| `grep -rl "Portfolio item number" _site/ \| wc -l` | 7 | 0 |
| `grep -rl "500x300" _site/ \| wc -l` | 5 | 0 |
| `grep -rl "Ongoing" _site/ \| wc -l` | 3 | 0 |
| `_site/markdown/index.html` | present | absent |
| `_site/non-menu-page/index.html` | present | absent |
| `_site/terms/index.html` | present | absent |
| `_site/archive-layout-with-content/index.html` | present | absent |

Note: do not grep the built site for "Erlangen" as a staleness check — the word legitimately appears in every FAU reference. Check `_config.yml` directly instead.

---

### Task 1: Fix the repository config so local builds work

The `repository` key is set to the bare repo name. `jekyll-github-metadata` requires `owner/name`. GitHub Pages masks this by supplying the value from its environment; local builds fail without it.

**Files:**
- Modify: `_config.yml:16`

- [ ] **Step 1: Confirm the build currently fails**

```bash
docker run --rm -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle \
  -w /srv/jekyll ruby:3.2 bash -c "bundle install --quiet && bundle exec jekyll build"
```

Expected: `ERROR: YOUR SITE COULD NOT BE BUILT: No repo name found.`

- [ ] **Step 2: Set the full owner/name**

In `_config.yml`, change line 16 from:

```yaml
repository               : "prathmeshrmadhu.github.io"
```

to:

```yaml
repository               : "prathmeshrmadhu/prathmeshrmadhu.github.io"
```

- [ ] **Step 3: Verify the build now succeeds**

```bash
jbuild
```

Expected: `done in N seconds.` with no `ERROR:` line. A `GitHub Metadata: No GitHub API authentication could be found` warning is expected and harmless.

- [ ] **Step 4: Commit**

```bash
git add _config.yml
git commit -m "Fix repository config to owner/name so the site builds locally"
```

---

### Task 2: Correct site identity in _config.yml

Three stale facts live here: the site description says Vice President, the author bio is written in third person and leads with a years-of-experience claim, and the location still says Erlangen although the resume says Pune.

**Files:**
- Modify: `_config.yml:13` (description), `_config.yml:85-86` (bio, location)

- [ ] **Step 1: Update the site description**

Change line 13 from:

```yaml
description              : &description "Vice President - Machine Learning at InFoCusp Innovations"
```

to:

```yaml
description              : &description "Senior Vice President - Machine Learning at Infocusp Innovations"
```

- [ ] **Step 2: Update the author bio and location**

Change lines 85-86 from:

```yaml
  bio              : "An AI and machine learning leader with 10+ years of experience in advanced computer vision, large language models, and agentic AI systems. He combines strong research expertise with practical product development to deliver impactful AI-driven solutions."
  location         : "Erlangen, Germany"
```

to:

```yaml
  bio              : "Computer vision researcher and machine learning leader. I work on problems where standard models fail — non-standard imagery, scarce labels, and tight compute budgets."
  location         : "Pune, India"
```

- [ ] **Step 3: Exclude planning docs from the build**

The `docs/` directory holds this plan and its spec. Jekyll copies it into `_site/`, which would publish both documents at `prathmeshrmadhu.github.io/docs/`. Add `docs` to the `exclude` list in `_config.yml` (the list beginning at line 125), keeping it alphabetically placed near `config`:

```yaml
  - config
  - docs
  - gulpfile.js
```

- [ ] **Step 4: Rebuild and verify**

```bash
rm -rf _site && jbuild
printf 'location:      '; grep -c "Pune, India" _site/index.html
printf 'description:   '; grep -c "Senior Vice President" _site/feed.xml
printf 'docs excluded: '; test -d _site/docs && echo LEAKED || echo ok
```

Expected: location `1` or greater, description `1` or greater, docs `ok`.

Note the description is checked in `feed.xml`, not `index.html`. The theme uses the site `description` for feed metadata only; it does not render it on the homepage. (After Task 3 the phrase will also appear in `index.html`, but that comes from the about page body, not from this config value.)

- [ ] **Step 5: Commit**

```bash
git add _config.yml
git commit -m "Update site identity to Senior VP and current location"
```

---

### Task 3: Rewrite the landing page

**Files:**
- Modify: `_pages/about.md` (full replacement)

- [ ] **Step 1: Replace the file contents**

```markdown
---
permalink: /
title: "About"
excerpt: "Computer vision researcher and machine learning leader."
author_profile: true
redirect_from:
  - /about/
  - /about.html
---

I'm Prathmesh — a computer vision researcher and machine learning leader with over ten years spanning peer-reviewed research and production systems.

I'm Senior Vice President of Machine Learning at [Infocusp Innovations](http://www.infocusp.com/), where I lead the computer vision group across concurrent LLM and computer vision programmes. Recent work includes TensorRT-accelerated visual SLAM for aerial platforms, agentic systems with LLM-as-a-judge evaluation pipelines, hybrid multimodal retrieval, and defect detection on production lines.

I hold a PhD from the [Chair of Pattern Recognition](https://lme.tf.fau.de/) at FAU Erlangen-Nürnberg. My dissertation addressed scene understanding in digital humanities — art history, classical archaeology, and Christian archaeology — extending object detection, pose estimation, and compositional analysis to artwork. That work produced ICC and ICC++, explainable feature learning methods for understanding image composition.

The through-line across both halves of my work: I take on problems where standard models fail — non-standard imagery, scarce labels, tight compute budgets, and outputs that have to be auditable.

## Where to go next

* **[Selected work](/portfolio/)** — what I've built, and what it measurably did
* **[Research](/publications/)** — publications, [talks](/talks/), and [teaching](/teaching/)

Outside of that, I'm fascinated by mathematics and drawn to problems built on it. I also [write occasionally](/year-archive/) about work, focus, and how this field keeps changing.

*Cogito, ergo sum.* — René Descartes

If you'd like to start a conversation, message me on [X](https://x.com/prathmeshmadhu) or [LinkedIn](https://www.linkedin.com/in/prathmeshrmadhu/).
```

- [ ] **Step 2: Rebuild and verify the routing links resolve**

```bash
jbuild
for p in portfolio publications talks teaching year-archive; do
  printf '%-16s ' "$p:"; test -f "_site/$p/index.html" && echo OK || echo MISSING
done
```

Expected: all five report `OK`.

- [ ] **Step 3: Verify the Descartes line survived**

```bash
grep -c "Cogito, ergo sum" _site/index.html
```

Expected: 1

- [ ] **Step 4: Commit**

```bash
git add _pages/about.md
git commit -m "Rewrite landing page to route research and industry readers"
```

---

### Task 4: Rewrite the CV page

The current page lists the PhD as ongoing, stops at 2018, and has its publications, talks and teaching loops commented out.

**Files:**
- Modify: `_pages/cv.md` (full replacement)

- [ ] **Step 1: Replace the file contents**

````markdown
---
layout: archive
title: "CV"
permalink: /cv/
author_profile: true
redirect_from:
  - /resume
---

{% include base_path %}

Education
======
* **Ph.D., Computer Science (Computer Vision)** — Friedrich-Alexander-Universität Erlangen-Nürnberg, Dec 2018 – Nov 2022
  * Chair of Pattern Recognition. Dissertation on scene understanding in digital humanities.
  * Cumulative GPA: 1.3/4.0 (1.0 best)
* **M.Tech., Information & Communication Technology** — DAIICT, Gandhinagar, Jul 2014 – May 2016
  * Cumulative GPA: 9.23/10.0
* **B.E., Electronics & Communication Engineering** — LD College of Engineering, Ahmedabad, 2014

Experience
======

**Senior Vice President – Machine Learning** · Infocusp Innovations, Pune · Aug 2026 – Present
* Promoted to lead the machine learning practice, with accountability for technical direction and delivery quality across the computer vision and LLM portfolio.
* Developing technical leads and strengthening evaluation and delivery standards across teams.

**Vice President – Machine Learning** · Infocusp Innovations, Pune · Jan 2025 – Jul 2026
* Led the computer vision group (10+ engineers) across multiple concurrent LLM and computer vision projects, converting open-ended client requirements into crisp project definitions, task breakdowns, and agreed success criteria.
* Led a 4-engineer team optimising MASt3R-SLAM for drone trajectory tracking on Jetson Orin NX, delivering a ~9× inference speedup (0.26 → 2.4 FPS) under tight compute and power budgets using TensorRT and ONNX, plus adaptive retrieval that skips redundant relocalisations during turns.
* Led a 5-engineer team building agentic AI systems for user researchers — agents that execute analysis workflows and generate reports — with LLM-as-a-judge evaluation harnesses as a first-class deliverable.
* Delivered a production hybrid multimodal retrieval system fusing vector-indexed image and text search with keyword search, for heterogeneous visual collections where off-the-shelf embeddings fail.
* Designed agentic health-protocol generation for a regulated domain with an auditable LLM review layer.

**Technical Lead – Machine Learning** · Infocusp Innovations, Pune · Aug 2023 – Jan 2025
* Fine-tuned TF Model Garden detection models for industrial defect inspection, achieving a 20% F1-score improvement on production data characterised by tiny targets, severe class imbalance, and few labelled failure examples; carried the work from data pipeline to customer POC.
* Built and led a 4-person R&D team on an LLM/RAG survey-analysis platform that summarises, tags, and reports on user-research data, cutting researcher time per project by 40%, validated against human-coded baselines.
* Translated peer-reviewed small-data techniques — transfer learning, attention-guided augmentation, one-shot detection — into repeatable delivery patterns for engagements where off-the-shelf models plateau.

**PhD Researcher** · Friedrich-Alexander-Universität Erlangen-Nürnberg · Dec 2018 – Jun 2023
* Pioneered ICC and ICC++, explainable feature learning methods leveraging human pose to uncover semantics and link iconography across image datasets.
* Enhanced pose estimation in ancient Greek vase paintings through style transfer and a perceptual metric, and improved one-shot object detection for heterogeneous artwork images using data contextualisation strategies.
* Improved classification performance for breast calcification analysis using histogram equalisation.

**Machine Learning Engineer** · Infocusp Innovations, Ahmedabad · Jul 2016 – Nov 2018
* Designed and deployed an enterprise candidate recommendation system processing 1M candidates daily to optimise hiring across multiple job positions.
* Led end-to-end development of a scalable hiring infrastructure using Python, PySpark and AWS, supporting concurrent multi-user access.
* Designed and implemented algorithms for reel, jerk, jigging and catch detection from fishing-rod sensor data — Python for development, C for deployment — with verification and validation testing.
* Contributed to [tf-cnnvis](https://github.com/InFoCusp/tf_cnnvis), an open-source CNN visualisation tool.

Skills
======
* **Programming languages:** Python, C
* **AI/ML frameworks:** TensorFlow, PyTorch, Scikit-learn, OpenCV, Hugging Face, Transformers, ONNX, TensorRT
* **Technologies:** Prompt engineering, Docker, CI/CD (GitHub Actions, Jenkins)
* **Tools:** Git, VSCode, Pandas, NumPy, IceVision, LangChain, LlamaIndex, Tensorboard, JupyterLab, Streamlit
* **Databases:** ElasticSearch, FAISS, TFRecords, Protobuf
* **Cloud:** AWS (EC2, S3, Lambda, SageMaker), GCP

Publications
======
  <ul>{% for post in site.publications reversed %}
    {% include archive-single-cv.html %}
  {% endfor %}</ul>

Talks
======
  <ul>{% for post in site.talks %}
    {% include archive-single-talk-cv.html %}
  {% endfor %}</ul>

Teaching
======
  <ul>{% for post in site.teaching reversed %}
    {% include archive-single-cv.html %}
  {% endfor %}</ul>
````

- [ ] **Step 2: Rebuild and verify the stale text is gone**

```bash
jbuild && grep -c "Ongoing" _site/cv/index.html
```

Expected: `0` (grep exits non-zero with count 0 — that is the pass condition).

- [ ] **Step 3: Verify all five roles render**

```bash
for r in "Senior Vice President" "Vice President" "Technical Lead" "PhD Researcher" "Machine Learning Engineer"; do
  printf '%-28s ' "$r:"; grep -c "$r" _site/cv/index.html
done
```

Expected: each returns 1 or greater.

- [ ] **Step 4: Verify the collection loops rendered**

```bash
grep -c "ICC++" _site/cv/index.html
```

Expected: 1 or greater — confirms the publications loop is producing entries, since ICC++ is a publication title.

- [ ] **Step 5: Commit**

```bash
git add _pages/cv.md
git commit -m "Rewrite CV with current roles and render publications from collections"
```

---

### Task 5: Add the missing FAU teaching entry

`_teaching/TA-Daiict.md` already consolidates all three DAIICT roles. The FAU role is the only one absent.

**Files:**
- Create: `_teaching/TA-fau-computer-vision.md`

- [ ] **Step 1: Create the file**

```markdown
---
title: "Teaching Assistant, Introduction to Computer Vision"
collection: teaching
type: "Graduate course"
permalink: /teaching/TA-fau-computer-vision
venue: "Friedrich-Alexander-Universität Erlangen-Nürnberg, Chair of Pattern Recognition"
date: 2020-04-01
location: "Erlangen, Germany"
---

Teaching assistant for Introduction to Computer Vision at the Chair of Pattern Recognition, under the supervision of Dr. Ronak Kosti.

Duties and Responsibilities:
------

  * Conducting the programming exercises accompanying the lecture course.
  * Supporting students through practical implementation of core computer vision methods.
  * Reviewing submitted exercise solutions and giving feedback.
```

- [ ] **Step 2: Rebuild and verify it appears on both pages**

```bash
jbuild
printf 'teaching page: '; grep -c "Introduction to Computer Vision" _site/teaching/index.html
printf 'cv page:       '; grep -c "Introduction to Computer Vision" _site/cv/index.html
```

Expected: both return 1 or greater. The CV hit confirms Task 4's teaching loop works.

- [ ] **Step 3: Commit**

```bash
git add _teaching/TA-fau-computer-vision.md
git commit -m "Add FAU teaching assistant entry"
```

---

### Task 6: Replace portfolio placeholders with the first two case studies

**Files:**
- Delete: `_portfolio/portfolio-1.md`, `_portfolio/portfolio-2.html`
- Create: `_portfolio/real-time-slam-on-edge-hardware.md`, `_portfolio/llm-survey-analysis-at-research-scale.md`
- Modify: `_pages/portfolio.html:3` (title), `_data/navigation.yml`

- [ ] **Step 1: Delete the placeholders**

```bash
git rm _portfolio/portfolio-1.md _portfolio/portfolio-2.html
```

- [ ] **Step 2: Create the SLAM case study**

File: `_portfolio/real-time-slam-on-edge-hardware.md`

```markdown
---
title: "Real-time visual SLAM on edge hardware"
excerpt: "A state-of-the-art SLAM pipeline taken from 0.26 to 2.4 FPS on a Jetson Orin NX — a ~9× speedup under strict power and compute limits."
collection: portfolio
---

**Context** — A drone analytics team needed visual SLAM for trajectory tracking, running on the aircraft rather than in the cloud.

**Problem** — MASt3R-SLAM produces excellent reconstructions, but at 0.26 FPS on the target board it was unusable for real-time flight. The usual answers — a smaller model, or a bigger board — were both unavailable: accuracy was the reason they chose the pipeline, and the compute and power budget was fixed by the airframe. Published optimisation guidance assumes server GPUs and stops being useful at the edge.

**Approach** — Two lines of attack. First, systematic inference optimisation for the Jetson Orin NX: ONNX export and TensorRT compilation, precision tuning, and removing host-to-device transfer stalls from the hot path. Second, an algorithmic change — adaptive retrieval, which raises the threshold for relocalisation during drone turns, exactly when candidate frames are least informative and the backend is doing the most redundant work.

**Result** — Roughly 9× faster inference, from 0.26 to 2.4 FPS, on unchanged hardware and with reconstruction quality intact. The optimisation sequence generalised into a playbook now applied to other models targeting constrained devices.

**Stack** — Jetson Orin NX · PyTorch · TensorRT · ONNX · CUDA · OpenCV
```

- [ ] **Step 3: Create the survey analysis case study**

File: `_portfolio/llm-survey-analysis-at-research-scale.md`

```markdown
---
title: "LLM survey analysis at research scale"
excerpt: "An LLM/RAG platform for user-research teams that cut analysis time per project by 40%, measured against human-coded baselines."
collection: portfolio
---

**Context** — A user research and insights team was drowning in open-ended survey responses. Analysts read, coded, and tagged thousands of free-text answers by hand for every study.

**Problem** — This looks like an obvious LLM use case, and that is the trap. Summarisation is easy to demo and hard to trust: researchers stake published findings on their coding, so a system that is convincing but subtly wrong is worse than no system at all. The real problem was never generating summaries — it was proving they were faithful enough to act on.

**Approach** — A retrieval-augmented pipeline that summarises responses, tags them against each study's coding scheme, and drafts report sections with citations back to the source responses, so any claim can be traced to the text behind it. Evaluation was built alongside the product rather than bolted on afterwards: outputs were scored against human-coded baselines on the same data, which is what made the gain measurable instead of merely asserted.

**Result** — A 40% reduction in researcher time per project, validated against those human-coded baselines. I built and led the R&D team through the initial platform; a larger team later extended it into a broader agentic system.

**Stack** — Python · RAG · LangChain · FAISS · ElasticSearch · Streamlit
```

- [ ] **Step 4: Retitle the portfolio page**

In `_pages/portfolio.html`, change line 3 from:

```yaml
title: "Portfolio"
```

to:

```yaml
title: "Selected Work"
```

Leave `permalink: /portfolio/` unchanged — renaming the URL is a Phase 2 decision.

- [ ] **Step 5: Add Selected Work to navigation**

Replace the contents of `_data/navigation.yml` with:

```yaml
# main links links
main:
  - title: "Selected Work"
    url: /portfolio/

  - title: "Publications"
    url: /publications/

  - title: "Talks"
    url: /talks/

  - title: "Teaching"
    url: /teaching/

  - title: "Blog Posts"
    url: /year-archive/

  - title: "CV"
    url: /cv/
```

- [ ] **Step 6: Rebuild and verify placeholders are gone**

```bash
jbuild
printf 'Portfolio item number: '; grep -rl "Portfolio item number" _site/ | wc -l
printf '500x300:               '; grep -rl "500x300" _site/ | wc -l
```

Expected: both `0`.

- [ ] **Step 7: Verify both case studies render and are reachable from navigation**

```bash
printf 'slam:     '; grep -c "2.4 FPS" _site/portfolio/index.html
printf 'survey:   '; grep -c "40%" _site/portfolio/index.html
printf 'nav:      '; grep -c "Selected Work" _site/index.html
```

Expected: all three return 1 or greater.

- [ ] **Step 8: Commit**

```bash
git add _portfolio/ _pages/portfolio.html _data/navigation.yml
git commit -m "Replace portfolio placeholders with first two case studies"
```

---

### Task 7: Delete theme demo pages

Four unmodified theme pages are live and indexable.

**Files:**
- Delete: `_pages/markdown.md`, `_pages/non-menu-page.md`, `_pages/terms.md`, `_pages/archive-layout-with-content.md`

- [ ] **Step 1: Confirm they are currently built**

```bash
for p in markdown non-menu-page terms archive-layout-with-content; do
  printf '%-28s ' "$p:"; test -f "_site/$p/index.html" && echo present || echo absent
done
```

Expected: all four `present`.

- [ ] **Step 2: Delete them**

```bash
git rm _pages/markdown.md _pages/non-menu-page.md _pages/terms.md _pages/archive-layout-with-content.md
```

- [ ] **Step 3: Rebuild and verify they are gone**

```bash
rm -rf _site && jbuild
for p in markdown non-menu-page terms archive-layout-with-content; do
  printf '%-28s ' "$p:"; test -f "_site/$p/index.html" && echo STILL_PRESENT || echo gone
done
```

Expected: all four `gone`. The `rm -rf _site` matters — Jekyll does not remove stale output from previous builds.

- [ ] **Step 4: Commit**

```bash
git add -u _pages/
git commit -m "Remove unmodified theme demo pages"
```

---

### Task 8: Reconcile publications against Google Scholar

`_publications/` holds 21 entries; the resume claims "18+" and Google Scholar is the authority. This task needs the user, because Scholar blocks automated access.

**Files:**
- Potentially create: new files in `_publications/`

- [ ] **Step 1: List what the site currently claims**

```bash
grep -h "^title:" _publications/*.md | sed 's/^title: //' | sort
```

- [ ] **Step 2: Ask the user to compare**

Present the sorted list and ask them to open [their Scholar profile](https://scholar.google.co.in/citations?user=tEe1-TYAAAAJ&hl=en) and identify anything missing or wrong. Do not attempt to scrape Scholar — it blocks automated requests and a partial scrape is worse than asking.

- [ ] **Step 3: Add any missing publications**

For each missing entry, create `_publications/YYYY-01-01-slugified-title.md` using exactly this shape (taken from the existing ICC++ entry — every field is required, and `permalink` must match the filename without the `.md`):

```markdown
---
title: "ICC++: Explainable feature learning for art history using image compositions"
collection: publications
permalink: /publication/2023-01-01-icc-explainable-feature-learning-for-art-history-using-image-compositions
date: 2023-01-01
venue: 'Pattern Recognition 136, 109153'
paperurl: 'https://scholar.google.com/citations?view_op=view_citation&hl=en&user=tEe1-TYAAAAJ&citation_for_view=tEe1-TYAAAAJ:Se3iqnhoufwC'
citation: 'P Madhu, T Marquart, R Kosti, D Suckow, P Bell, A Maier, V Christlein. (2023). &quot;ICC++: Explainable feature learning for art history using image compositions.&quot; <i>Pattern Recognition 136, 109153</i>.'
---

<a href='https://scholar.google.com/citations?view_op=view_citation&hl=en&user=tEe1-TYAAAAJ&citation_for_view=tEe1-TYAAAAJ:Se3iqnhoufwC'>Download paper here</a>

Recommended citation: P Madhu, T Marquart, R Kosti, D Suckow, P Bell, A Maier, V Christlein. (2023). "ICC++: Explainable feature learning for art history using image compositions." <i>Pattern Recognition 136, 109153</i>.
```

Note the `&quot;` escaping inside `citation` — the theme renders that field as HTML.

**Alternative:** `markdown_generator/publications.py` generates these files from `markdown_generator/new_publications.tsv` (currently header-only). It requires Python with pandas. Hand-writing is simpler for a handful of entries; if you use the generator instead, add the new rows to `publications.tsv` as well so it stays the record of what was generated.

- [ ] **Step 4: Rebuild and verify the count**

```bash
jbuild && ls _publications/*.md | wc -l
```

Expected: matches the agreed Scholar-reconciled count.

- [ ] **Step 5: Commit (only if files changed)**

```bash
git add _publications/
git commit -m "Reconcile publications against Google Scholar"
```

---

### Task 9: Final verification pass

- [ ] **Step 1: Clean build from scratch**

```bash
rm -rf _site && jbuild
```

Expected: `done in N seconds.`, no `ERROR:`.

- [ ] **Step 2: Run every success criterion from the spec**

```bash
echo "--- placeholders (expect 0) ---"
for s in "Portfolio item number" "500x300" "Ongoing"; do
  printf '%-24s ' "$s:"; grep -rl "$s" _site/ 2>/dev/null | wc -l
done

echo "--- demo pages (expect gone) ---"
for p in markdown non-menu-page terms archive-layout-with-content; do
  printf '%-28s ' "$p:"; test -f "_site/$p/index.html" && echo STILL_PRESENT || echo gone
done

echo "--- key pages (expect OK) ---"
for p in portfolio publications talks teaching cv year-archive; do
  printf '%-16s ' "$p:"; test -f "_site/$p/index.html" && echo OK || echo MISSING
done

echo "--- identity (expect >=1) ---"
printf 'Senior VP on home: '; grep -c "Senior Vice President" _site/index.html
printf 'Pune on home:      '; grep -c "Pune, India" _site/index.html
printf 'Descartes:         '; grep -c "Cogito, ergo sum" _site/index.html

echo "--- planning docs must not be published (expect ok) ---"
test -d _site/docs && echo LEAKED || echo ok
```

- [ ] **Step 3: Confirm no commercial content leaked in**

```bash
grep -ril -e "150/hr" -e "retainer" -e "advisory" -e "engagement model" _site/ | wc -l
```

Expected: `0`. The spec forbids any money angle; this catches accidental copying from the positioning document.

- [ ] **Step 4: Confirm no PDF CV link was added**

```bash
grep -ril -e "download.*cv" -e "cv.pdf" -e "resume.pdf" _site/ | wc -l
```

Expected: `0`. The website is the CV.

- [ ] **Step 5: Visual spot check**

```bash
docker run --rm -p 4000:4000 -v "$PWD":/srv/jekyll -v jekyll_gems:/usr/local/bundle \
  -w /srv/jekyll ruby:3.2 \
  bash -c "bundle exec jekyll serve --host 0.0.0.0"
```

Open `http://localhost:4000` and check: the two routing links work, navigation shows Selected Work, both case studies render, and the CV page shows five roles with publications, talks and teaching populated beneath.

- [ ] **Step 6: Report status to the user**

Do not push. Summarise what changed and confirm the remaining Phase 1 open items: talks after 2018 (deferred by agreement) and the untracked draft post `_posts/2026-05-03-work-love.md` (left alone by agreement).

---

## Deliberately not in this plan

- **Talks after 2018** — deferred; `/talks/` stays in navigation untouched.
- **`_posts/2026-05-03-work-love.md`** — the user asked to leave the untracked draft alone.
- **Case studies 3–6** (defect detection, hybrid retrieval, agentic health protocols, `tf-cnnvis`) — written after the format is validated on the first two.
- **Structural and visual work** — Phases 2 and 3.
- **Pushing to origin** — never without an explicit request.
