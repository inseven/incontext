# InContext

Multimedia-focused static site builder for macOS

## Installation

InContext can be installed using [Homebrew](https://brew.sh):

```bash
brew install inseven/incontext/incontext
```

## Documentation

See [https://incontext.app/docs](https://incontext.app/docs).

## Frontmatter

Frontmatter is supported in Markdown files and image and video descriptions. InContext will pass through all unknown markdown fields, but puts type constraints on fields that have specific meaning:

- `title` String?
- `subtitle` String?
- `date` Date?
- `queries` [[String: Any]]?
- `tags` [String]?

## Issues

### High Priority

These changes impact the rendering of jbmorley.co.uk and block switching to InContext 3.

1. **Check adaptive images work**
2. Check that gifs are transformed correctly
3. Markdown issues (Footnotes, Strikethrough, mdash)
4. Timezone handling is currently inconsistent and unclear (this could be improved by using the time and date HTML tags)
   1. https://developer.mozilla.org/en-US/docs/Web/HTML/Element/time
   2. https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/date
   3. https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/datetime-local
5. Galleries aren't appearing in the infinite scroll (e.g. PowerBook, Vision of the Future, Weeknotes #1)

### Background

- Test that the relative paths are correct for the destination directory; this likely needs to be per-importer, but it would be much easier if we had a way to generate these as part of the site so importers don't have to think too hard
- Store the origin mime type in the database and expose through `DocumentContext`
- Provide a simple, clean API to inline a relative document
- Resolve
  - Introduce a render-time `resolve` method that can figure out what happened to a document and include it
  - The current `resolve` implementation is hand-tuned and isn't guaranteed to work with new document types

- Test resolving relative paths '.'
- Support building to a custom build destination; this will make it much easier to use for GitHub Pages based deployments

### Improvements

- Consider special files in directories for nested behaviours
