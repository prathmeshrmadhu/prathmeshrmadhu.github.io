# Website Content Refresh — Design

**Date:** 2026-07-29
**Phase:** 1 of 3
**Status:** Approved

## Context

`prathmeshrmadhu.github.io` is a Jekyll site on the Academic Pages theme. Its content has drifted badly:

- `_pages/cv.md` lists the PhD as "2018 -- Ongoing" and stops at 2018. It omits the PhD as a role, and all three Infocusp roles since 2023.
- `_pages/about.md` says "Vice President" — correct until 2026-08-01, when the Senior VP promotion takes effect.
- `_portfolio/` contains unmodified theme placeholders ("Portfolio item number 1" / "number 2") with 500x300 dummy images. Live and indexable, but unlinked from navigation, which is why they went unnoticed.
- Four theme demo pages are live and indexable.
- `_talks/` stops at 2018. `_teaching/` is missing the FAU TA role entirely.
- The skills list leads with `keras`, `fastai`, `nltk`, `[Basic] Apache pyspark` and omits everything current.

The revamp runs in three phases: **content (this spec) → structure/navigation → visual design.** Content comes first because structural and visual decisions depend on knowing what content exists and how much of it.

## Goals

1. Nothing factually wrong or embarrassing remains on the live site.
2. The site serves two audiences explicitly: research peers and industry readers.
3. Establish the case-study format that Phases 2 and 3 will design around.

## Locked decisions

| Decision | Choice | Rationale |
|---|---|---|
| Primary audience | Both, explicitly routed | Chosen knowingly over single-audience, accepting roughly double the content work |
| Client confidentiality | Unnamed but specific | Real numbers and technical detail retained; no client names. Measured deltas are the persuasive core |
| Commercial framing | Credibility only | No rates, no engagement models, no commercial ask. Positioning-doc pricing material stays private |
| Implementation approach | Straight markdown in place | Structured `_data` YAML rejected as speculative infrastructure for a single-author site |
| Downloadable PDF CV | No | The website itself is the CV; readers should not have to download anything |
| Service/reviewing CV section | Excluded | Explicitly out of scope |

## Out of scope

- **Talks content after 2018.** `/talks/` stays in navigation, untouched. Revisit once Phase 1 is done.
- **Structural reorganisation** beyond one navigation addition (below) — Phase 2.
- **Visual and theme work** — Phase 3.
- **Blog posts.** Existing posts stay as-is.
- **Medical imaging as a case study.** The mammography work is peer-reviewed and is better served by `/publications/`.
- **The 1M-candidates/day recommendation engine as a case study.** Covered on the CV; leading with 2016–18 work undercuts the recent-work framing.

## Page inventory after Phase 1

| Page | Serves | Change |
|---|---|---|
| `/` (`_pages/about.md`) | Both — routes them | Rewritten: positioning + two paths |
| `/portfolio/` → "Selected Work" | Industry | New case studies; retitled; **added to navigation** |
| `/publications/` | Research | Reconciled against Google Scholar |
| `/cv/` | Both | Full rewrite |
| `/teaching/` | Research | Add missing FAU TA entry |
| `/talks/` | Research | Untouched (deferred) |
| `/year-archive/` (blog) | Both | Untouched |

Adding "Selected Work" to `_data/navigation.yml` is a structural change made in Phase 1 by explicit agreement: case studies nobody can reach are pointless.

The **permalink stays `/portfolio/`** in Phase 1 — only the page title and navigation label change to "Selected Work". Renaming the collection and its URL is a Phase 2 structural decision, and doing it now would mean either broken links or redirect handling for no immediate benefit.

## Work item 0 — Site configuration (`_config.yml`)

Added during planning, when a local build was first attempted.

**Build blocker.** `repository` is set to `"prathmeshrmadhu.github.io"`, but `jekyll-github-metadata` requires `owner/name`. GitHub Pages masks this by supplying the value from its own environment, so the bug is invisible in production and fatal locally. Correct it to `"prathmeshrmadhu/prathmeshrmadhu.github.io"`.

**Stale identity.** Three facts here are wrong or dated, and the author sidebar renders on every page:

- `description` says "Vice President" and misspells the employer as "InFoCusp".
- `author.bio` is written in the third person and leads with a years-of-experience claim.
- `author.location` says "Erlangen, Germany"; the resume says Pune, India.

## Work item 1 — Landing page (`_pages/about.md`)

Rewrite. Structure:

1. **Dual-identity opening** — researcher *and* ML leader in the first sentence. This is the routing job.
2. **Current role** — Senior VP at Infocusp, the CV group, and concrete recent work (TensorRT-accelerated SLAM, agentic systems with LLM-as-a-judge evals, hybrid multimodal retrieval, defect detection).
3. **Research** — PhD at FAU Chair of Pattern Recognition; scene understanding in digital humanities; ICC / ICC++.
4. **The through-line** — problems where standard models fail: non-standard imagery, scarce labels, tight compute budgets, outputs that must be auditable. This paragraph is the honest synthesis of both halves and does more persuasive work than either credential list.
5. **Two routes** — "Research" (publications, talks, teaching) and "Selected work" (case studies).
6. **Personal register** — retain the mathematics line and *"Cogito, ergo sum — René Descartes."*
7. **Contact** — X and LinkedIn, as now.

Deliberate omissions: publication and citation counts (they read as self-promotion here and `/publications/` proves them anyway), and the "10+ years / VP" seniority framing (concrete recent work is stronger).

## Work item 2 — CV page (`_pages/cv.md`)

**Education** — PhD, FAU (Dec 2018 – Nov 2022); M.Tech ICT, DAIICT (2014–2016); B.E. Electronics & Communication, LD College of Engineering (2014). The B.E. is dropped from the one-page resume but retained here, where space is not scarce.

**Experience** — five roles, replacing the current two:

- Senior Vice President – ML, Infocusp (Aug 2026 – Present) — deliberately modest; the role begins 2026-08-01
- Vice President – ML, Infocusp (Jan 2025 – Jul 2026)
- Technical Lead – ML, Infocusp (Aug 2023 – Jan 2025)
- PhD Researcher, FAU (Dec 2018 – Jun 2023)
- Machine Learning Engineer, Infocusp (Jul 2016 – Nov 2018)

Scope escalates across the three recent roles and nothing repeats: TL is technical depth and one team; VP is multiple teams plus productionised systems and the 10+ person group; Senior VP is a short, honest entry for a role that has just started. Bullets are those agreed in conversation on 2026-07-29.

**Skills** — replaced wholesale from the resume: Python, C; TensorFlow, PyTorch, scikit-learn, OpenCV, HuggingFace, Transformers, ONNX, TensorRT; prompt engineering, Docker, CI/CD; LangChain, LlamaIndex, Streamlit; ElasticSearch, FAISS, TFRecords, Protobuf; AWS, GCP.

**Publications / Talks / Teaching** — uncomment the existing Liquid loops at `_pages/cv.md:80-95`. These render from the same collections that feed the standalone pages, so the CV cannot drift from them. This delivers single-source-of-truth for the repeating content without building any new infrastructure.

**Academic teaching roles** — `_teaching/` currently holds two entries: `TA-Daiict.md`, which already consolidates all three DAIICT TA roles (Advanced Calculus, Linear Algebra, Communication Systems), and `personal-coaching-2014.md`. The consolidation is fine and stays as-is.

The gap is exactly one entry: the **FAU Teaching Assistant** role (Introduction to Computer Vision, Summer 2020, supervisor Dr. Ronak Kosti), which appears in the CV prose but has no collection entry. Add it so the uncommented loop renders it.

## Work item 3 — Case studies (`_portfolio/`)

Delete both placeholders. Retitle `_pages/portfolio.html` to "Selected Work" and add it to navigation.

**Format** — consistent across all entries, 150–250 words each:

- **Title** — named after the problem, not the client
- **Context** — the domain, unnamed ("a drone analytics company")
- **Problem** — what was failing, and why standard approaches did not work
- **Approach** — the actual technical decisions
- **Result** — the measured delta
- **Stack** — tools, as a footer line

The "why standard approaches did not work" line is what makes these read as engineering rather than marketing.

**Write two first**, then review before batching the rest. Validating the format once beats discovering it is wrong six times.

1. **Real-time visual SLAM on edge hardware** — MASt3R-SLAM for drone trajectory tracking; ~9× FPS (0.26 → 2.4) on Jetson Orin NX under tight compute and power budgets; TensorRT/ONNX plus adaptive retrieval skipping redundant relocalisations during turns.
2. **LLM/RAG survey analysis at research scale** — summarising, tagging and reporting on user-research data; 40% researcher time saved per project, validated against human-coded baselines.

**Remaining four**, pending format approval:

3. Defect detection where models plateau — 20% F1 improvement on production data; tiny targets, class imbalance, few labelled failures.
4. Hybrid multimodal retrieval for visual collections — vector-indexed image + text search fused with keyword search, where off-the-shelf embeddings fail.
5. Agentic systems in a regulated domain — health-protocol generation with an LLM-as-a-judge review layer for auditable outputs.
6. `tf-cnnvis` — open-source CNN visualisation tool. Already public, so zero confidentiality friction, and a real GitHub artifact does credibility work prose cannot.

## Work item 4 — Deletions

Delete four theme demo pages, all live and indexable:

- `_pages/markdown.md` — Academic Pages template documentation, available upstream
- `_pages/non-menu-page.md` — demo page
- `_pages/archive-layout-with-content.md` — theme styling showcase
- `_pages/terms.md` — boilerplate privacy policy dated 2016. Deleted because `_config.yml` sets `analytics.provider: "google-universal"` with an empty `tracking_id`, so no analytics run and the policy describes collection that is not happening. If analytics are ever enabled, a privacy page should be written fresh.

## Work item 5 — Publications reconciliation

The repo has 21 entries in `_publications/`; the resume claims "18+". Reconcile against Google Scholar (`user=tEe1-TYAAAAJ`) rather than trusting either number. Add anything missing; correct metadata mismatches. Citation and i10-index figures belong on `/publications/`, not the landing page.

## Work item 6 — Optional: finish the untracked blog post

`_posts/2026-05-03-work-love.md` is written but untracked, so not live. It needs: a title (currently `title: ''`), tags (currently empty), a corrected permalink (currently `/posts/2026/03/31/work-love/`, copy-pasted from the information-overload post and inconsistent with its own `2026-05-03` date), and an ending — the final sentence stops mid-thought at "...learn how to say NO more than you thought you SHOULD".

Optional because it is authorial work, not a correctness fix. Requires the user to supply the ending.

## Success criteria

Phase 1 is done when all of the following hold:

1. A clean Jekyll build completes without errors. Ruby is not installed on this machine, so builds run in a Ruby 3.2 Docker container; see the implementation plan for the exact command.
2. No occurrence of "Portfolio item number", "500x300", or "Ongoing" anywhere in built output.
3. `/cv/` shows five roles, correct dates, and renders publications, talks and teaching from collections.
4. `/` names Senior Vice President and offers two working navigation paths; the author sidebar shows Pune, India.
5. "Selected Work" appears in navigation and lists two complete case studies.
6. The four demo pages return 404.
7. `/teaching/` includes the FAU TA role alongside the existing DAIICT and coaching entries.
8. `_publications/` count and metadata match Google Scholar.
9. No rates, engagement models, or commercial asks anywhere; no PDF CV download link.
10. Every case study is unnamed as to client while retaining its measured delta.
11. Internal links resolve — no 404s from navigation or the landing page routes.

## Known risks

- **The Senior VP entry predates the role by three days.** If the site publishes before 2026-08-01, "Aug 2026 – Present" is technically ahead of itself. Publishing on or after 2026-08-01 resolves this.
- **Google Scholar blocks automated access.** Reconciliation may need to be manual, with the user pasting the list.
- **Case-study numbers are client-derived.** Although unnamed, the user should sanity-check each measured claim before publication.
