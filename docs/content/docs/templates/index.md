Templates are written in [Tilt](https://github.com/tomsci/tomscis-lua-templater). Tilt is, itself, written in Lua and the templating language and leans heavily on Lua and Lua syntax. Within reason, if you can do it in Lua, you can do it in Tilt. This makes the templates incredibly powerful and helps avoid the bloat that comes from trying to do more programmatic things with templating languages like [Jinja](https://jinja.palletsprojects.com/en/3.1.x/), while also keeping things pretty simple and readable.

# Inheritance

Tilt doesn't explicitly support inheritance, but it's possible to achieve something very similar using partial code blocks.

1. The parent template calls a function–`content` in the example below–to render customizable elements:

   ```html
   [[
   <!DOCTYPE html>
   <html lang="en-US">
     {% include "head.html"  %}
     <body>
       {% include "navigation.html" %}
       <div class="content">
           {% content() %}
       </div>
       {% include "footer.html" %}
     </body>
   </html>]]
   ```

2. The inheriting template provides an implementation of the content functions using partial code blocks and, finally, includes the the parent template:

   ```html
   [[
   {% function content() %}
       <div class="post">
           {% include "post_header.html" %}
           <article class="post-content">
               {% incontext.renderDocumentHTML(document) %}
           </article>
       </div>
   {% end %}
   {% include "default.html" %}]]
   ```

# Global Variables

## `document`

Document being rendered.

**Example**

```html
[[
{% if document.title then %}
  <h1>{{ document.title }}</h1>
{% end %}]]
```

## `site`

Top-level site object containing site-wide properties and store accessors.

# Utilities

## `incontext.generateUUID()`

Returns a new [RFC 4122 version 4  UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier#Version_4_(random)) string.

## `incontext.titlecase(string)`

Returns a titlecased version of the input string.

Titles detected from the filename are automatically transformed using titlecase (we might rethink this in the future), but custom document metadata is not automatically processed in this way and it may be desirable to do something like this in your template:

```html
[[
{% if document.subtitle then %}
  <h2>{{ titlecase(document.subtitle) }}</h2>
{% end %}]]
```

## `incontext.thumbnail(url)`

# Site

## `site.title`

String containing the site title, as defined in 'site.yaml'.

## `site.url`

String containing the site URL, as defined in 'site.yaml'.

## `site.metadata`

Table containing the site metadata, as defined in 'site.yaml'.

## `site.documents()`

Returns all the documents in the site.

# Document

## `document.nearestAnscestor()`

Returns the first document found by walking up the document path; nil if no ancestor can be found.

## `document.children(options)`

### Options

<table>
  <tr>
    <td><code>sort</code></td>
    <td>"ascending" or "descending"</td>
    <td>
      Document sort order.<br />
      Defaults to "ascending".
    </td>
  </tr>
</table>

### Details

Returns all children, sorted by date, "ascending" or "descending".

### Example

```html
[[
<ul>
  {% for _, child in ipairs(document.children({ sort = "descending" })) do %}
    <li>{{ child.title }}</li>
  {% end %}
</ul>]]
```

## `document.descendants(options)`

### Options

<table>
  <tr>
    <td><code>maximumDepth</code></td>
    <td>Integer</td>
    <td>Maximum depth of children to return, relative to the parent.</td>
  </tr>
  <tr>
		<td><code>sort</code></td>
    <td>"ascending" or "descending"</td>
    <td>
      Document sort order.<br />
      Defaults to "ascending".
    </td>
  </tr>
</table>

### Details

Returns all descendants of a document, with a primary sort on the `date` property, and secondary sort the `title` property of the returned documents.

Specifying a maximum depth of 1 will return the document's immediate children. Omitting the maximum depth will return all descendants.

💡 Note `document.children(options)` exists as a convenience for listing the documents immediate children and may be cleaner to use in templates if that's all you require.

### Example

Generate a table of contents including all the document's descendants:


```html
[[
<ul>
  {% for _, descendant in ipairs(document.descendants()) do %}
    <li><a href="{{ descendant.url }}">{{ descendant.title }}</a></li>
  {% end %}
</ul>]]
```

Generate a list of the document's immediate children:

```html
[[
<ul>
  {% for _, descendant in ipairs(document.descendants({ maximumDepth = 1 })) do %}
    <li>{{ descendant.title }}</li>
  {% end %}
</ul>]]
```

