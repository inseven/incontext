# Single Page

The simplest template renders the HTML contents of a single document, processing any inline Tilt in the document's contents.

``` html
[[
<html>
  <head>
    <title>{{ site.title }}</title>
  </head>
  <body>
    <h1>{{ incontext.titlecase(document.title) }}</h1>
    {{ incontext.renderDocumentHTML(document) }}
    <p>Published {{ document.date.format("MMMM d, yyyy") }}</p>
  </body>
</html>]]
```

# Index Pages

It's very common to want to list all documents within a specific category, with a specific tag, or within a specific tree structure. For example, the following template uses Tilt's Lua code-blocks to iterate over the current document's immediate children and output an unordered list:

```html
[[
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
</html>]]
```

💡 Note that this template still includes the document's HTML–this can be helpful in creating reusable listings pages which can be easily annotated in their source Markdown.
