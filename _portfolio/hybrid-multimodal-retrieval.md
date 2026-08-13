---
title: "Hybrid multimodal retrieval for visual collections"
excerpt: "Search across a heterogeneous image collection by fusing vector-indexed image and text embeddings with keyword search."
collection: portfolio
---

**Context** — A large, heterogeneous collection of images and accompanying text that people needed to search meaningfully, not just browse.

**Problem** — Off-the-shelf embeddings underperform badly on collections like this. They are trained on web-scale photographic data, and a collection that is stylistically or domain-specifically unlike that distribution falls outside what the embedding space represents well. But the naive alternative fails differently: pure vector search is fluent at semantic similarity and unreliable at exact matching, so a user searching for a specific identifier, name, or code — the queries people actually issue most — gets plausible neighbours instead of the right record. Keyword search has the mirror-image failure. Choosing either one alone means accepting a whole class of queries it cannot serve.

**Approach** — Index both modalities as vectors, image and text, and fuse those results with a keyword index rather than picking a winner. Semantic queries are served by the embedding side, exact-match queries by the lexical side, and the fusion step decides how to combine them per query rather than applying one fixed strategy to all of them.

**Result** — Shipped to production and serving live queries across the collection, handling both semantic and exact-match retrieval in a single interface.

**Stack** — Python · FAISS · ElasticSearch · Transformers · Docker
