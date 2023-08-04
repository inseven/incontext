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
- [ ] Detect sites in roots above the current directory (git-like)
- [ ] Support loading the existing stie configuration
- [ ] Track resources and clean them up when files are deleted or importers change
- [ ] Try using a multi-reader / single-writer model for the database to improve template render performance
- [ ] Use Swift DSL to unify file and image handlers (this would allow easy checking of glob, regex, extension, and mime
      type)
- [ ] Drop the now-unnecessary dependency on Sass
- [ ] Check that gifs are transformed correctly
- [ ] Test that the relative paths are correct for the destination directory; this likely needs to be per-importer, but
      it would be much easier if we had a way to generate these as part of the site so importers don't have to think too
      hard
- [ ] SQLite is mangling mtimes meaning that some files always get regenerated
- [ ] I still don't have a good solution for many-to-one compiles (e.g., Sass)
- [ ] swift-sass includes binary dependencies and is unacceptable long-term
- [ ] It might be nice to add type checking to the frontmatter, or perhaps even Swift struct frontmatter
- [ ] Rename 'type' to category because that's what it is and it's currently misleading
- [ ] Clean up `set`, `update`, and `with` parser errors to make them easier to understand
- [ ] Support mdash in Markdown content
- [ ] Consider whether I should support EXIF sidecars and, if so, handle dependency management for them
- [ ] Store the document mime type in the database; this should make it possible to automatically select
      all images etc
- [ ] Add support for audio
- [ ] Add support for generating podcast feeds
- [ ] Typesafe configuration
- [ ] Consider supporting filters in the `set` tag
- [ ] Consider special files in directories for nested behaviours
- [ ] Log at at different levels, error, warning, etc
- [ ] Rename page to document in the render context
- [ ] Evaluation EvaluationContexts should be enumerable to assist with documentation
- [ ] RenderStatus needs to fingerprint documents
- [ ] Intoduce a render-time `resolve` method that can figure out what happened to a document and include it
- [ ] Promote metadata dates
- [ ] Support querying for posts without or with dates
- [ ] Queries should support a maximum count
- [ ] Specify default sort by title
- [ ] Update jbmorley.co.uk to include the common.lua conveniences
  - [ ] Adaptive image
  - [ ] Video
  - [ ] STL
  - [ ] Audio
- [ ] Add a --Werror flag
- [ ] Consider using SQLite.swift custom type support (https://github.com/stephencelis/SQLite.swift/blob/master/Documentation/Index.md#custom-types)
- [ ] Import image dates
- [ ] Adopt the latest Tilt
- [ ] Video documents aren't being loaded correctly
- [ ] Figure out how to do per-item templates (inline templates)?
- [ ] Better error reporting for incorrect types
- [ ] Consider making thumbnail an explicit property on document types and moving user metadata into a substructure
