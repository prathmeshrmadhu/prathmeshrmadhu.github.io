---
title: "Defect detection where models plateau"
excerpt: "A 20% F1 improvement on production inspection data defined by tiny targets, severe class imbalance, and almost no labelled failures."
collection: portfolio
---

**Context** — An industrial manufacturer inspecting parts on a production line, where the defects that matter occupy a handful of pixels in a high-resolution frame.

**Problem** — The client had already tried the obvious thing, and it had plateaued. Detection architectures are trained and benchmarked on datasets where objects occupy a meaningful fraction of the image; a defect a few pixels across sits far outside that regime. Worse, the data is pathologically imbalanced in the direction that hurts most — a working production line produces overwhelmingly good parts, so the failures you most need to learn from are the examples you have fewest of. Collecting more data is not an option when the thing you want more of is the thing the client is trying to eliminate.

**Approach** — Transfer learning from TF Model Garden detection backbones rather than training from scratch, because with this few positive examples the pretrained features are doing most of the work. Augmentation targeted specifically at the failure modes visible in the confusion matrix, rather than applied generically. Evaluation was reframed around F1 rather than accuracy from the outset — on data this imbalanced, accuracy is a metric that rewards a model for saying nothing is ever wrong. I carried the work from data pipeline through to customer proof-of-concept.

**Result** — A 20% F1-score improvement on the client's own production data, on the same imagery where their previous approach had stalled.

**Stack** — Python · TensorFlow · TF Model Garden · OpenCV · NumPy
