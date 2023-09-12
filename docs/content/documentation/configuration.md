---
title: Configuration
---

Looks something like this:

```yaml
version: 1

title: InContext
url: "https://incontext.app"

port: 8003

build_steps:

  - task: "process_files"
    args:
      handlers:

        # Ignore temporary and hidden files.
        - when: '(.*/)?(\.DS_Store|.*~|\..*)'
          then: ignore

        # Import markdown files.
        - when: '.*\.(markdown|md)'
          then: markdown
          args:
              default_category: recipes
              default_template: page.html

        # Import image files.
        - when: '(.*/)?.*\.(jpg|jpeg|png|gif|tiff|heic)'
          then: image
          args:
              category: images
              title_from_filename: False
              default_template: photo.html
              inline_template: image.html

        # Copy everything else.
        - when: '.*'
          then: copy
```
