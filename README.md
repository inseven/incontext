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

1. **Deleted documents aren't removed from the store**
2. **Check adaptive images work**
3. **Don't automatically replace non-Markdown image tags**
6. Pass-through site metadata so that things like tags can be rendered correctly
7. Check that gifs are transformed correctly
8. Markdown issues (Footnotes, Strikethrough, mdash)
9. Scale videos
11. Timezone handling is currently inconsistent and unclear (this could be improved by using the time and date HTML tags)
    1. https://developer.mozilla.org/en-US/docs/Web/HTML/Element/time
    2. https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/date
    3. https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/datetime-local
12. Render caching currently means that it's not possible to use incremental builds for deployments
14. Galleries aren't appearing in the infinite scroll (e.g. PowerBook, Vision of the Future, Weeknotes #1)

### Background

- Support loading the existing site configuration
- Track resources and clean them up when files are deleted or importers change
- Test that the relative paths are correct for the destination directory; this likely needs to be per-importer, but it would be much easier if we had a way to generate these as part of the site so importers don't have to think too hard
- SQLite is mangling mtimes meaning that some files always get regenerated
- Store the origin mime type in the database and expose through `DocumentContext`
- Log at at different levels, error, warning, etc
- Intoduce a render-time `resolve` method that can figure out what happened to a document and include it
- Update jbmorley.co.uk to include working examples of the common.lua conveniences
  - Adaptive image
  - STL
- Add a --Werror flag
- Port legacy InContext 2 tests
- Video playback doesn't work with the built-in web server
- The `serve` command doesn't cancel cleanly with the `--watch` flag
- Provide a simple, clean API to inline a relative document
- The current `resolve` implementation is hand-tuned and isn't guaranteed to work with new document types
- Detect circular rendering dependencies
- Build failures with `--watch` cause the command to exit
- Show progress when rendering by default instead of logging for every file
- Test resolving relative paths '.'
- Write up Info.plist experiments
- Ensure the build fails even if the build script fails silently (perhaps I could use the presence of a file to indicate success and check this in GitHub?)
- Check the notarization response and fetch the error in the case of a failure
- Support building to a custom build destination; this will make it much easier to use for GitHub Pages based deployments

### Improvements

- Use Swift DSL to unify file and image handlers (this would allow easy checking of glob, regex, extension, and mime type)
- Typesafe configuration
  - Explicit user-defined metadata section in the site and frontmatter
  - The derived thumbnail property is overwriting the user metadata (this should somehow be protected)
- Consider special files in directories for nested behaviours
