{% function link(title, url) %}
    {% if url then %}
        <a href="{{ url }}">{{ title }}</a>
    {% else %}
        {{ title }}
    {% end %}
{% end %}

{%

    function ancestors(document)
        local ancestor = document
        local ancestors = {}
        while true do
            ancestor = ancestor.closestAncestor()
            if ancestor then
                table.insert(ancestors, ancestor)
            else
                return ancestors
            end
        end
    end

    local function reversedipairsiter(t, i)
        i = i - 1
        if i ~= 0 then
            return i, t[i]
        end
    end

    function reversedipairs(t)
        return reversedipairsiter, t, #t + 1
    end

    function concat(values, separator)
        write(table.concat(values, separator))
    end

    function contains(items, item)
        for _, testItem in ipairs(items) do
            if testItem == item then
                return true
            end
        end
        return false
    end

    function empty(items)
        if next(items) == nil then
           return true
        else
            return false
        end
    end

    function last(items, index)
        return items[index+1] == nil
    end

    function filter(items, predicate)
        local result = {}
        for _, item in ipairs(items) do
            if predicate(item) then
                table.insert(result, item)
            end
        end
        return result
    end

    function gallery(path)
        local parentPath = document.resolve(path)
        local photos = site.query { parent = parentPath }
        include("album_content.html")
    end

    function adaptiveImage(light, dark, alt)
        include("adaptive_image.html")
    end

    function stl(src)
        include("stl.html")
    end

    function audio(src)
        include("audio.html")
    end

    function video(src)
        include("widgets/video.html")
    end

    function renderDocumentHTML(document)
        local html = document.html
        if html then
            eval(html, document.sourcePath)
        end
    end

%}

{% function tagged(tag) %}
    <ul>
        {% local posts = site.query { tag = tag } %}
        {% for _, post in ipairs(posts) do %}
            <li><a href="{{ post.url }}">{{ post.title }}</a>{% if post.date then %} &ndash; {{ post.date.format(site.date_format) }}{% end %}</li>
        {% end %}
    </ul>
{% end %}

{% function project(url, image, title, description) %}
    <li class="project">
        <div class="album aspect square line">
            <a href="{{ url }}"><img src="{{ document.resolve(image) }}"/></a>
        </div>
        <p>
            <a href="{{ url }}">{{ title }}</a><br />
            {{ titlecase(description) }}
        </p>
    </li>
{% end %}

{% function software(url, image, type, title, description) %}
    <div class="software">
        <p>
            <a class="{% if image then %}software-{{ type }}{% else %}software-placeholder{% end %}" href="{{ url }}">{% if image then %}<img src="{{ image }}" />{% end %}</a>
        </p>
        <p>
            <a href="{{ url }}">{{ title }}</a><br />
            {{ titlecase(description) }}
        </p>
    </div>
{% end %}

{% function showcase(tag, options) %}
    <ul class="grid sparse prefer-2-columns">
        {%
            local args = { tag = tag }
            for key, value in pairs(options or {}) do
                args[key] = value
            end
            local posts = site.query(args)
        %}
        {% for _, post in ipairs(posts) do %}
            {% assert(post.thumbnail, string.format("Missing thumbnail for '%s'.", post.url)) %}
            <li class="project">
                <div class="album aspect ratio-4-3 line">
                    <a href="{{ post.url }}">
                        <img src="{{ post.resolve(post.thumbnail) }}"/>
                    </a>
                </div>
                <p>
                    <a href="{{ post.url }}">{{ post.title }}</a>
                    {% if post.date then %}<br />{{ post.date.format(site.date_format) }}{% end %}
                </p>
            </li>
        {% end %}
    </ul>
{% end %}

{% function item_list(items, status) %}
    <ul>
        {% for _, item in ipairs(items) do %}
            {% if item.status == status then %}
            <li>
                {% link(item.title, item.link) %}{% if item.authors then %} by {% concat(item.authors, ", ") %}{% end %}
                {% if item.date_original or item.end_date then %}
                    &ndash;
                    {% if item.end_date then %}
                        {{ item.end_date.format(site.date_format) }}
                    {% else %}
                        {{ item.date_original.format(site.date_format) }}
                    {% end %}
                {% end %}
            </li>
            {% end %}
        {% end %}
    </ul>
{% end %}

{% function item_grid(items, status) %}
    <div class="grid prefer-4-columns sparse">
        {% for _, item in ipairs(items) do %}
            {% if item.status == status then %}
            <div>
                <a href="{{ item.link }}" title="{{ item.title }}">
                    {% thumbnail = item.cover or item.thumbnail %}
                    {% if thumbnail then %}
                        <img class="media" src="{{ item.resolve(thumbnail) }}" />
                    {% else %}
                        {{ item.title }}
                    {% end %}
                </a>
            </div>
            {% end %}
        {% end %}
    </div>
{% end %}
