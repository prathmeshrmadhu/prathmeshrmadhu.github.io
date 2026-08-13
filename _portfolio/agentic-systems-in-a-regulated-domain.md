---
title: "Agentic generation in a regulated domain"
excerpt: "Health-protocol generation with an LLM-as-a-judge review layer, built so that every output can be audited rather than trusted."
collection: portfolio
order: 3
result_note: "Auditable by design"
tags: [LangChain, Agentic orchestration, LLM-as-a-judge]
---

**Context** — Generating health protocols in a domain where the output is subject to review, and where being wrong carries consequences beyond a bad user experience.

**Problem** — A regulated domain inverts the usual priorities of a generative system. The question is not whether the model can produce a good protocol — it can — but whether anyone can demonstrate afterwards *why* a particular protocol was produced, and catch the cases where it should not have been. A single-shot LLM call fails this on both counts: it gives you an answer with no reviewable reasoning and no signal about its own reliability. Human review of every output would solve the trust problem and destroy the reason for building the system at all.

**Approach** — Decompose generation into agent steps whose intermediate reasoning is recorded rather than discarded, so the path to an output is inspectable. Then a separate LLM-as-a-judge review layer evaluates each generated protocol against explicit criteria before it reaches a human, so that reviewer attention lands on the outputs that need it instead of being spread evenly across all of them. The judge is not there to replace human sign-off; it is there to make human sign-off tractable.

**Result** — An auditable generation pipeline in which every output carries its reasoning trace and an independent review verdict, designed so that scaling throughput does not mean scaling unreviewed output.

**Stack** — Python · LLMs · LangChain · agentic orchestration · LLM-as-a-judge evaluation
