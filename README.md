# InContext 3 – Waialua

Swift implementation of the InContext static site builder

## Overview

[InContext](https://incontext.app) is a static site generator written in Python that runs inside Docker to try to mitigate the issues of Python dependencies. I use it to publish [jbmorley.co.uk](https://jbmorley.co.uk). Thanks to Python and Docker, it's proven difficult to make InContext fast--a full build of my photo-heavy website (roughly 40 GB source files) takes over 4 hours on my build server.

InContext 3 (Waialua) is a Swift rewrite that follows the design principals of InContext but tries to address the performance issues with some more modern language choices.

## Build

```
git submodule update --init --recursive
swift build
```

# Templates

Templates are written in [Tilt](https://github.com/tomsci/tomscis-lua-templater). Tilt is, itself, written in Lua and the templating language and leans heavily on Lua and Lua syntax. Within reason, if you can do it in Lua, you can do it in Tilt. This makes the templates incredibly powerful and helps avoid the bloat that comes from trying to do more programmatic things with templating languages like [Jinja](https://jinja.palletsprojects.com/en/3.1.x/), while also keeping things pretty simple and readable.

## Global Variables

- `page`

  **Description**

  Document being rendered.

  **Example**

  ```lua
  {% if page.title then %}
      <h1>{{ page.title }}</h1>
  {% end %}
  ```

- `site`

  **Description**

  Top-level site object containing site-wide properties and store accessors.

## Global Functions

- `titlecase(String) -> string`

  **Description**

  Convert the input string to titlecase.

  **Example**

  Titles detected from the filename are automatically transformed using titlecase (we might rethink this in the future), but custom document metadata is not automatically processed in this way and it may be desirable to do something like this in your template:

  ```lua
  {% if page.subtitle then %}
      <h2>{{ titlecase(page.subtitle) }}</h2>
  {% end %}
  ```

## Site



## Document

- `nearestAnscestor() -> Document?`

  **Description**

  Returns the first document found by walking up the document path; nil if no ancestor can be found.

- `children(sort: String = "ascending") -> [Document]`

  **Description**

  Return all immediate children, sorted by date, "ascending" or "descending".

  **Example**

  ```lua
  <ul>
      {% for _, child in ipairs(site.children { sort = "descending" }) %}
          <li>{{ child.title }}</li>
      {% end %}
  </ul>
  ```

## Issues

### High Priority

These changes impact the rendering of jbmorley.co.uk and block switching to InContext 3.

1. **Deleted documents aren't removed from the store**
3. **Check adaptive images work**
4. **Don't automatically replace non-Markdown image tags**
5. **Videos** (Location, Titles)
6. **Promote metadata dates (see the reading and game lists)**
7. **Check that the JSON feed works**
8. Pass-through site metadata so that things like tags can be rendered correctly
9. Check that gifs are transformed correctly
10. Migrate EXIF sidecars
11. The vertical spacing seems off on jbmorley.co.uk (this is probably a legacy stylesheet issue)
12. Markdown issues (Footnotes, Strikethrough, mdash)
13. Scale videos
14. Preserve image and video alt-text when transforming markdown media
15. Timezone handling is currently inconsistent and unclear
16. Render caching currently means that it's not possible to use incremental builds for deployments
17. 360 degree mini worlds aren't generated
18. Galleries aren't appearing in the infinite scroll (e.g. PowerBook, Vision of the Future, Weeknotes #1)
19. Comments aren't correctly parsed as Markdown

### Background

- Inner template evaluation identifiers aren't set (update Tilt)
- Support loading the existing site configuration
- Track resources and clean them up when files are deleted or importers change
- Test that the relative paths are correct for the destination directory; this likely needs to be per-importer, but it would be much easier if we had a way to generate these as part of the site so importers don't have to think too hard
- SQLite is mangling mtimes meaning that some files always get regenerated
- Store the origin mime type in the database and expose through `DocumentContext`
- Log at at different levels, error, warning, etc
- Rename page to document in the render context
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
- Address TODOs in code
- Test resolving relative paths '.'

### Improvements

- Try using a multi-reader / single-writer model for the database to improve template render performance
- Use Swift DSL to unify file and image handlers (this would allow easy checking of glob, regex, extension, and mime type)
- Typesafe configuration
  - Explicit user-defined metadata section in the site and frontmatter
  - The derived thumbnail property is overwriting the user metadata (this should somehow be protected)
- Evaluation EvaluationContexts should be enumerable to assist with documentation
- Linux support
- Consider special files in directories for nested behaviours
- Support querying for posts without or with dates
- Clean up and document the context variables and functions
