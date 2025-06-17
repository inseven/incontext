---
title: Configuration
---

The site configuration is stored as [YAML](https://yaml.org) in 'site.yaml' in the root of the site.

# Example

A typical configuration (the one for this site) looks something like this:

```yaml
version: 2

title: InContext
url: "https://incontext.jbmorley.co.uk"

port: 8003

steps:

  # Ignore temporary and hidden files.
  - when: '(.*/)?(\.DS_Store|.*~|\..*)'
    then: ignore

  # Import markdown files.
  - when: '.*\.(markdown|md)'
    then: markdown
    args:
        defaultCategory: recipes
        defaultTemplate: page.html

  # Import image files.
  - when: '(.*/)?.*\.(jpg|jpeg|png|gif|tiff|heic)'
    then: image
    args:
        category: images
        titleFromFilename: False
        defaultTemplate: photo.html
        inlineTemplate: image.html

  # Copy everything else.
  - when: '.*'
    then: copy

```

# Properties

## `version` (String)

Configuration version.

This is expected to change quickly as the latest iteration of InContext stabilises. During this initial development
phase, only the latest version (currently version 2) will be supported, but there are plans to offer backwards
compatibility where possible following a period of stabilisation.

## `title` (String)

Site title.

Available to templates as `site.title`.

## `url` (URL)

Public URL for the site.

Where the site will be hosted. It's available to templates as `site.url` and will be used by the Helper app and
command-line app to open the site in the system browser.

## `port` (Int, Default = 8000)

Port number used for the local development server.

Both the Helper app and command-line app use the port number when creating a local development server. When running
multiple development servers for different sites (the Helper app will do this by default), you should ensure you select
different ports for each sites.
