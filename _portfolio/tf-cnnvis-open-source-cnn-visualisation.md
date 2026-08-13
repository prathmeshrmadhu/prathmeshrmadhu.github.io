---
title: "tf-cnnvis — seeing inside a convolutional network"
excerpt: "An open-source CNN visualisation library for TensorFlow, now past 750 stars and 200 forks."
collection: portfolio
order: 6
result: "750+ stars, 200+ forks"
tags: [TensorFlow, TensorBoard, NumPy]
---

**Context** — An open-source project at Infocusp, built while I was a machine learning engineer there. Unlike the rest of the work on this page, it is public: [github.com/InFoCusp/tf_cnnvis](https://github.com/InFoCusp/tf_cnnvis).

**Problem** — In 2017, convolutional networks were being deployed far faster than they were being understood. The interpretability literature existed — Zeiler and Fergus had published their deconvolution technique, Google had published DeepDream — but the gap between a paper describing a method and an engineer being able to run it on their own model was wide. Reimplementing a visualisation technique correctly from a paper is a research task in itself, which meant in practice most teams simply did not look inside their models.

**Approach** — A library that implements deconvolution-based reconstruction and DeepDream against arbitrary TensorFlow graphs, and renders the output straight into TensorBoard rather than inventing a new viewer. That last decision mattered more than it sounds: it meant the tool fitted the workflow engineers already had, so using it cost them nothing new to learn. My contribution was in design discussion, debugging, and analysis of the generated visualisations as the implementation came together.

**Result** — Past 750 stars and 200 forks, MIT-licensed. The value of a public artifact is that it is inspectable — you can read the code and judge the work yourself, which is not something a case study can offer.

**Stack** — Python · TensorFlow · TensorBoard · NumPy
