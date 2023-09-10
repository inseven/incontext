# Frontmatter

Markdown and Frontmatter are used throughout InContext as a way to add content and metadata to documents. The most common form is in Markdown files (e.g., 'index.markdown' or 'index.md') on disk. These might be pages or posts in your site:

```markdown
---
category: pages
title: Hello, World!
tags:
- about
---

Hi! I'm Jason. Welcome to my corner of the Internet!

I hope you find many **fun** and _exciting_ things here.
```

## Schema

In order to help make things predictable, and surface data issues, the default importers require that top-level Frontmatter properties conform to specific types, allowing for user-defined properties in the 'metadata' field:

```yaml
category: String
template: String
title: String
subtitle: String
date: Date
thumbnail: String
tags: [String]
queries: [QueryDescription]
metadata: [String: Any]
```

**Note:** All properties are optional, meaning you can safely omit Frontmatter from any Markdown or structured content field.

