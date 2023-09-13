---
title: InContext
template: page.html
category: page
---

Most existing static site generators do a great job with text content, but treat media as an afterthought. InContext handles Markdown just as well as generators like Jekyll, and adds native support for photos and video.

# Installation

```bash
brew install inseven/incontext/incontext
```

# Design Principals

To keep things simple, InContext follows some basic design principles:

- No media type is more important than any other; images are just as important as text, as video, etc.
- Every URL has a corresponding file backing it in the content directory of the site.
