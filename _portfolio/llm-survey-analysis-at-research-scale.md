---
title: "LLM survey analysis at research scale"
excerpt: "An LLM/RAG platform for user-research teams that cut analysis time per project by 40%, measured against human-coded baselines."
collection: portfolio
order: 5
result: "−40% analysis time"
tags: [RAG, LangChain, FAISS]
---

**Context** — A user research and insights team was drowning in open-ended survey responses. Analysts read, coded, and tagged thousands of free-text answers by hand for every study.

**Problem** — This looks like an obvious LLM use case, and that is the trap. Summarisation is easy to demo and hard to trust: researchers stake published findings on their coding, so a system that is convincing but subtly wrong is worse than no system at all. The real problem was never generating summaries — it was proving they were faithful enough to act on.

**Approach** — A retrieval-augmented pipeline that summarises responses, tags them against each study's coding scheme, and drafts report sections with citations back to the source responses, so any claim can be traced to the text behind it. Evaluation was built alongside the product rather than bolted on afterwards: outputs were scored against human-coded baselines on the same data, which is what made the gain measurable instead of merely asserted.

**Result** — A 40% reduction in researcher time per project, validated against those human-coded baselines. I built and led the R&D team through the initial platform; a larger team later extended it into a broader agentic system.

**Stack** — Python · RAG · LangChain · FAISS · ElasticSearch · Streamlit
