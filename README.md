# InContext 3

Swift implementation of the InContext static site builder

## Overview

[InContext](https://incontext.app) is a static site generator written in Python that runs inside Docker to try to
mitigate the issues of Python dependencies. I use it to publish [jbmorley.co.uk](https://jbmorley.co.uk). Thanks to
Python and Docker, it's proven difficult to make InContext fast--a full build of my photo-heavy website (roughly 40 GB
source files) takes over 4 hours on my build server.

InContext 3 (`ic3`) is an experimental Swift rewrite that follows the design principals of InContext but tries to
address the performance issues with some more modern language choices. It is most assuredly not production ready and,
while I'd love to use it to build my own website in the future, we're not there yet.

## Issues

- [ ] Is MarkdownKit or Ink faster?
- [ ] Is YamlSwift fast enough?
- [ ] What is the performance hit of using a regex in the frontmatter parser?
- [ ] Use the Swift `Regex` DSL
- [ ] Saved named importers and their version and intermediate data when they change
- [ ] Titles are not being correctly saved in the store or document
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
- [ ] I still don't have a good solution for many-to-one compiles
- [ ] I could, like Jekyll have an explicit way to ignore files and then have a way for importers to explicitly return
      their dependencies
- [ ] swift-sass includes binary dependencies and is unacceptable long-term
- [ ] It might be nice to add type checking to the frontmatter, or perhaps even Swift struct frontmatter
