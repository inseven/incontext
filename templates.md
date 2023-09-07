# Templates

Templates are written in [Tilt](https://github.com/tomsci/tomscis-lua-templater). Tilt is, itself, written in Lua and the templating language and leans heavily on Lua and Lua syntax. Within reason, if you can do it in Lua, you can do it in Tilt. This makes the templates incredibly powerful and helps avoid the bloat that comes from trying to do more programmatic things with templating languages like [Jinja](https://jinja.palletsprojects.com/en/3.1.x/), while also keeping things pretty simple and readable.

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

## Global Functions

#### `incontext.titlecase(string)`

Returns a titlecased version of the input string

**Example**

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

### `nearestAnscestor() -> Document?`

Returns the first document found by walking up the document path; nil if no ancestor can be found.

### `children(sort: String = "ascending") -> [Document]`

Return all immediate children, sorted by date, "ascending" or "descending".

**Example**

```lua
<ul>
    {% for _, child in ipairs(document.children { sort = "descending" }) %}
        <li>{{ child.title }}</li>
    {% end %}
</ul>
```

