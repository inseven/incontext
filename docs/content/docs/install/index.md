---
title: Install
---

# macOS

You can use InContext in one of two ways: on the [command line](#command-line); or with a [GUI](#gui) helper-app that lives in the Menu Bar, monitors a collection of sites,  and builds them for you in the background.

## Command Line

```sh
brew tap inseven/incontext
brew trust --formula inseven/incontext/incontext
brew install incontext
```

## GUI

Download from [GitHub](https://github.com/inseven/incontext/releases/latest).

# Linux

## Ubuntu

```sh
curl -fsSL https://releases.jbmorley.co.uk/apt/public.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/jbmorley.gpg
echo "deb https://releases.jbmorley.co.uk/apt $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/jbmorley.list
sudo apt update
sudo apt install incontext
```

