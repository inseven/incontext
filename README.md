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

- [ ] What is the performance hit of using a regex in the frontmatter parser?
- [ ] Use the Swift `Regex` DSL
- [ ] Support loading the existing site configuration
- [ ] Track resources and clean them up when files are deleted or importers change
- [ ] Try using a multi-reader / single-writer model for the database to improve template render performance
- [ ] Use Swift DSL to unify file and image handlers (this would allow easy checking of glob, regex, extension, and mime
      type)
- [ ] Check that gifs are transformed correctly
- [ ] Test that the relative paths are correct for the destination directory; this likely needs to be per-importer, but
      it would be much easier if we had a way to generate these as part of the site so importers don't have to think too
      hard
- [ ] SQLite is mangling mtimes meaning that some files always get regenerated
- [ ] Typesafe configuration
  - [ ] Explicit user-defined metadata section in the site and frontmatter
- [ ] Support mdash in Markdown content
- [ ] Consider whether I should support EXIF sidecars and, if so, handle dependency management for them
- [ ] Store the document mime type in the database; this should make it possible to automatically select
      all images etc
- [ ] Consider special files in directories for nested behaviours
- [ ] Log at at different levels, error, warning, etc
- [ ] Rename page to document in the render context
- [ ] Evaluation EvaluationContexts should be enumerable to assist with documentation
- [ ] RenderStatus needs to fingerprint documents
- [ ] Intoduce a render-time `resolve` method that can figure out what happened to a document and include it
- [ ] Promote metadata dates
- [ ] Support querying for posts without or with dates
- [ ] Update jbmorley.co.uk to include working examples of the common.lua conveniences
  - [ ] Adaptive image
  - [ ] Video
  - [ ] STL
  - [ ] Audio
- [ ] Add a --Werror flag
- [ ] Import image dates
- [ ] Video documents aren't being loaded correctly
- [ ] Figure out how to do per-item templates (inline templates)?
- [ ] Consider making thumbnail an explicit property on document types and moving user metadata into a substructure
- [ ] Port legacy InContext 2 tests
- [ ] Remove template language from the identifiers
- [ ] Rename the importers to simply 'image', 'markdown', etc.
- [ ] Extract location data from videos
- [ ] Don't automatically replace non-Markdown image tags 
- [ ] Provide a mechanism to specify the sort of child queries
- [ ] Footnotes don't work
- [ ] Strikethrough doesn't work
- [ ] Markdown m-dashes don't work
- [ ] Not all image titles work
- [ ] 360 photos aren't processed correctly
- [ ] Thumbnail detection doesn't work
- [ ] Video playback doesn't work with the built-in web server
- [ ] The `serve` command doesn't cancel cleanly with the `--watch` flag
- [ ] Check that the JSON feed works
- [ ] The vertical spacing seems off on jbmorley.co.uk (this is probably a legacy stylesheet issue)
- [ ] It needs to be possible to pass-through site metadata so that things like tags can be rendered correctly
- [ ] Next / previous functions always return nil
- [ ] InContext is currently macOS only
- [ ] The game list and reading lists are broken
- [ ] Provide a simple, clean API to inline a relative document
- [ ] The current `resolve` implementation is hand-tuned and isn't guaranteed to work with new document types
- [ ] The derived thumbnail property is overwriting the user metadata (this should somehow be protected)
- [ ] Detect circular rendering dependencies

