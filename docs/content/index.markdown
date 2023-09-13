---
template: page.html
category: page
---

<div style="margin-bottom: 2em;">
    <p style="font-size: 46px; text-align: center; margin-bottom: 0.4em; font-weight: 700;">InContext</p>
    <p style="font-size: 36px; max-width: 600px; text-align: center; margin: auto; font-weight: 300;">a multimedia-focused static site builder for macOS</p>
</div>

Most existing static site generators do a great job with text content, but treat media as an afterthought. InContext handles Markdown just as well as generators like Jekyll, and adds native support for photos and video.

# Installation

```bash
brew install inseven/incontext/incontext
```

# Design Principals

To keep things simple, InContext follows some basic design principles:

- No media type is more important than any other; images are just as important as text, as video, etc.
- Every URL has a corresponding file backing it in the content directory of the site.
