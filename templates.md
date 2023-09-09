# Templates

Templates are written in [Tilt](https://github.com/tomsci/tomscis-lua-templater). Tilt is, itself, written in Lua and the templating language and leans heavily on Lua and Lua syntax. Within reason, if you can do it in Lua, you can do it in Tilt. This makes the templates incredibly powerful and helps avoid the bloat that comes from trying to do more programmatic things with templating languages like [Jinja](https://jinja.palletsprojects.com/en/3.1.x/), while also keeping things pretty simple and readable.

## Examples

### Single Page

The simplest template renders the HTML contents of a single document, processing any inline Tilt in the document's contents.

``` html
<html>
  <head>
    <title>{{ site.title }}</title>
  </head>
  <body>
    <h1>{{ incontext.titlecase(document.title) }}</h1>
    {{ incontext.renderDocumentHTML(document) }}
    <p>Published {{ document.date.format("MMMM d, yyyy") }}</p>
  </body>
</html>
```

### Index Pages

It's very common to want to list all documents within a specific category, with a specific tag, or within a specific tree structure. For example, the following template uses Tilt's Lua code-blocks to iterate over the current document's immediate children and output an unordered list:

```html
<html>
  <head>
    <title>{{ site.title }} &mdash; {{ incontext.titlecase(document.title) }}</title>
  </head>
  <body>
    <h1>{{ incontext.titlecase(document.title) }}</h1>
    {{ incontext.renderDocumentHTML(document) }}
    <ul>
      {% for _, child in ipairs(document.children) do %}
        <li><a href="{{ document.url }}">{{ incontext.titlecase(child.title) }}</a></li>
      {% end %}
    </ul>
  </body>
</html>
```

Note that this template still includes the document's HTML–this can be helpful in creating reusable listings pages which can be easily annotated in their source Markdown.

## Global Variables

### `document`

Document being rendered.

**Example**

```lua
{% if document.title then %}
  <h1>{{ document.title }}</h1>
{% end %}
```

### `site`

Top-level site object containing site-wide properties and store accessors.

## Utilities

#### `incontext.titlecase(string)`

Returns a titlecased version of the input string

Titles detected from the filename are automatically transformed using titlecase (we might rethink this in the future), but custom document metadata is not automatically processed in this way and it may be desirable to do something like this in your template:

```lua
{% if document.subtitle then %}
  <h2>{{ titlecase(document.subtitle) }}</h2>
{% end %}
```

## Site

### `site.title`

String containing the site title, as defined in 'site.yaml'.

### `site.url`

String containing the site URL, as defined in 'site.yaml'.

### `site.metadata`

Table containing the site metadata, as defined in 'site.yaml'.

### `site.documents()`

Returns all the documents in the site.

## Document

### `document.nearestAnscestor()`

Returns the first document found by walking up the document path; nil if no ancestor can be found.

### `document.children(sort: String = "ascending")`

Return all immediate children, sorted by date, "ascending" or "descending".

```lua
<ul>
  {% for _, child in ipairs(document.children { sort = "descending" }) %}
    <li>{{ child.title }}</li>
  {% end %}
</ul>
```

