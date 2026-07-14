---
template: home.html
category: page
title: Home
---

<div style="margin-bottom: 2em;">
    <p style="font-size: 46px; text-align: center; margin-bottom: 0.4em; font-weight: 700;">InContext</p>
    <p style="font-size: 36px; max-width: 600px; text-align: center; margin: auto; font-weight: 300;">Multimedia-Focused Static Site Builder</p>
</div>

Most existing static site generators do a great job with text content, but treat media as an afterthought. InContext handles Markdown just as well as generators like Jekyll, uses Lua for templating, and adds native support for photos and video.

InContext follows some basic design principles:

- No media type is more important than any other; images are just as important as text, as video, etc.
- Every URL has a corresponding file backing it in the content directory of the site.

# Install

- [macOS](#macos)
- [Linux](#linux)

## macOS

You can use InContext in one of two ways: on the [command line](#command-line); or with a [GUI](#gui) helper-app that lives in the Menu Bar, monitors a collection of sites,  and builds them for you in the background.

### Command Line

```sh
brew install inseven/incontext/incontext
```

### GUI

Download from [GitHub](https://github.com/inseven/incontext/releases/latest).

## Linux

### Ubuntu

```sh
curl -fsSL https://releases.jbmorley.co.uk/apt/public.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/jbmorley.gpg
echo "deb https://releases.jbmorley.co.uk/apt $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/jbmorley.list
sudo apt update
sudo apt install incontext
```
