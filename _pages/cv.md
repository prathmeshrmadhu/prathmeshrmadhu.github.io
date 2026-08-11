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
