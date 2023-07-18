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
