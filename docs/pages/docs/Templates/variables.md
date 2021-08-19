---
data:
  title: "Available variables"
  description: Template variables injected by built_site
template: layouts/docs/single
---

## Available variables

When rendering a page, you have access to the following variables:

- `path` (string): The main path of the current page, relative to the website's base url
- `aliases` (list of string): A list of paths of the current page, excluding the main `path`.
- `page` (dict): An object containing information about the current page
- `site` (dict): The effective site configuration with the current environment applied
- `environment` (string): The selected environment identifier, defaults to `dev` for regular builds
  and to `prod` when the `--release` flag is used.
- `base_url` (string): The effective base url from the configuration
- `built_site` (dict):
  - `version` (string): The version of `built_site` used to generate the page
- `root_section` (dict): The section of the root pages
- `first_section` (dict): The first section under the root section that's an ancestor of the current page.
  This is equivalent to `root_section` iff the current page is in the root section
- `page_section` (dict): The section of the page being rendered
- `pages` (list of dict): A list of _all_ pages in the website

## Supported filters

At the moment, built_site supports the following filters. Filters have a
primary input followed by optional arguments.

- `abs`: Returns the absolute value of a number. `{{ "{{ -3 | abs }}" }}` would print `{{ -3 | abs }}`
- `append`: Concatenates the primary input and all arguments `{{ "{{ 'hello' | append: ' ', 'world' }}" }}` prints `{{ 'hello' | append: ' ', 'world' }}`

In addition, the following filters are available when rendering a page:

- `absUrl`: Resolves a path against the site's base url. For this website, `{{ "{{ 'docs/templates/liquid' | absUrl }}" }}` prints `{{ 'docs/templates/liquid' | absUrl }}`
- `relUrl`: Like `absUrl`, but urls that are absolute already will not be modified.
 For instance, `'https://moor.simonbinder.eu' | relUrl` will not transform the input uri.
- `i18n`: Looks up the translation key for the language of the current page
- `pageUrl`: Takes a page or [page meta]({{ '../Content/pages.md#meta' | pageUrl }}) and returns its
  absolute uri.
  For this page, `{{ "{{ '' | pageUrl }}" }}` resolves to `{{ '' | pageUrl }}`.
  (Note that the empty uri always resolves to the current source)
- `pageInfo`: Returns the parsed Front Matter for a given page as a dictionary. For this page,
  `{{ "{{ '' | pageInfo }}" }}` resolves to `{{ '' | pageInfo }}`.
- `hash`: Returns a hashsum of a given asset, encoded in base64. For instance, the hash
  for the current input markdown file can be computed with `{{ "{{ '' | hash }}" }}`
  (which evaluates to `{{ '' | hash }}`).
  This is useful to implement [subresource integrity](https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity).
- `sectionOf`: Returns the information about the section of the provided page. For this page,
  `{{ "{{ '' | sectionOf }}" }}` evaluates to `{{ '' | sectionOf }}`.
- `isAncestor`: In addition to the primary input, this takes one further argument.
  It resolves the sections of both inputs (using `sectionOf`) and then computes
  whether the primary input is an ancestor of the input argument.
- `isDescendant`: Like `isAncestor`, but reversed: It resolves the section of
  the primary input and the argument and returns whether the section of the
  primary input is a descendant of the section of the argument.
- `sortedByWeight`: The primary input must be a list of pages, page references or
  sections. `sortedByWeight` sorts that list in ascending `weight`.
  The `weight` of a page or section can be set through `data.weight` in a page's
  [front matter]({{ '../Content/pages.md#frontmatter' | pageUrl }}).