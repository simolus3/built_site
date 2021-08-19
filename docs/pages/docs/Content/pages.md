---
data:
  title: Pages
  description: Learn how to write pages with built_site, including information about front matter and Markdown
template: layouts/docs/single
---

In built_site, a page consist of meta information declared in front matter and
its actual body, written in either Markdown or HTML.
Regardless of which markup language you prefer, you can use 
[template elements]({{ '../Templates/liquid.md' | pageUrl }}) in the content of a page.

## A simple example

Let's take a look at a very simple page. Assume that you have the following
directory structure:

```
my_website
  pages/
    index.html
  website.yaml
  pubspec.yaml
```

Further, assume that `pages/index.html` has the following content

```html
---
data:
  title: My first page
  language: en
---
<!doctype html>
<html lang="{{ "{{page.language}}" }}">
    <head>
        <title>{{ "{{page.title}}" }}</title>
    </head>
    <body>
        <h1>Welcome</h1>
        <p>
            This page is available at <code>{{ "{{ path }}" }}</code>
        </p>
    </body>
</html>
```

For this simple page, built_site would generate a (hidden) file 
`web/index.html` with the following content:

```html
<!doctype html>
<html lang="en">
    <head>
        <title>My first page</title>
    </head>
    <body>
        <h1>Welcome</h1>
        <p>
            This page is available at <code>/</code>
        </p>
    </body>
</html>
```

## Front Matter {#frontmatter}

At the beginning of your page, you can declare meta data as a yaml map.
To do so, just wrap it in three dashes.
built_site is very unopiniated about Front Matter and only defines a schema for
values necessary to know the result paths of a page. Everything else is left to
your convention (or the conventions of the themes you use).

built_site interprets the following keys:
 - `path` (optional string): The main path of the generated page, relative to
   your site's base url.
   When this value is absent, built_site will determine a suitable path based on
   the path of the source file.
 - `aliases` (optional list of string): An optional list of additional paths
   under which the page should be made available.
 - `template` (optional string): The template to apply before rendering the
   page.
 - `data` (optional dict): Custom used-defined values for the page. This would
   commonly contain the page's title and a short description, but how to
   interpret this data is entirely left to you.

## Content

After an optional Front Matter follows the body of your page.
Depending on the file ending of a page, content can be written in Markdown or 
HTML.

### How pages are rendered

When rendering a page, built_site uses the following three-step procedure:

1. Evaluate template components inside the page's body.
2. If the page is a markdown page, convert it to html.
3. If a template is set, process the result from step 2 through that template.

### Page Meta files {#meta}

For incremental builds, built_site writes the parsed front matter with the
resolved path to a `.page_meta` file. These files can be used wherever a
regular page is expected as well, mainly in template expressions.

## Markdown

built_site uses a sightly extended version of the [markdown](https://pub.dev/packages/markdown)
package to render markdown. Custom additions include a syntax highlighter and
custom ids for headers.

To declare a custom id for a heading, this syntax can be used:

```md
## My interesting heading {#anchor}
```

This would generate a `<h2 id="anchor">My interesting heading</h2>` tag in HTML.
