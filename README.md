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
