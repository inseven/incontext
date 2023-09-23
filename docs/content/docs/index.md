---
title: Documentation
---

<ul>
  {% for _, descendant in ipairs(document.descendents()) %}
    <li><a href="{{ descendant.url }}">{{ descendant.title }}</a></li>
  {% end %}
</ul>

- [Configuration](configuration/)
- [Templates](templates/)
- [Directory Structure](directory-structure/)
