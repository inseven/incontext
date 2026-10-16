---
title: AI
---

## Generation

InContext is not vibe coded. Code is predominantly human-authored, with some targeted AI assistance and code generation in specific areas to improve cross-platform support and test coverage. Generated code has been manually reviewed thoroughly.

{% function link(path) %}
  <a href="https://github.com/inseven/incontext/blob/main/{{ path }}">{{ path }}</a>
{% end %}

## Core

- {% link("Sources/InContextCore/LiveReloadMiddleware.swift") %} -- injects reloader script

## Tests

- {% link("Tests/InContextTests/Tests/LiveReloadMiddlewareTests.swift") %}

## Tools

InContext was created using Xcode, Helix, and VS Code, on operating systesms (macOS and Linux) known to be developed in part using AI. [Claude](https://claude.com/) was used as a research and search proxy, and to assist in dependency management and updates.
