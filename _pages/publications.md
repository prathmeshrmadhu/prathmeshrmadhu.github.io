---
layout: archive
title: "Publications"
permalink: /publications/
author_profile: true
---

{% include base_path %}

For the full list of academic publications, check out my [official-webpage](https://lme.tf.fau.de/person/madhu/), [Google Scholar](https://scholar.google.co.in/citations?user=tEe1-TYAAAAJ&hl=en) profile.

{% for post in site.publications reversed %}
  {% include archive-single.html %}
{% endfor %}
