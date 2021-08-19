---
data:
  title: Sections
  description: Sections are a hierarchical group of pages
template: layouts/docs/single
---

## Creating sections

A section gets created for each `index.html` or `index.md` file in `pages/`.
Sections form a tree which can be accessed in templates to build complex patterns like
breadcrumbs, navigation bars, or sitemaps.

## Using sections

You can use sections to render navigation patterns. built_site supports the following
Liquid filters and variables to interact with sections:

- `root_section`: The most top-level section in the tree, usually the section for your `pages/index.html` or `pages/index.md` file.
- `first_section`: A child section of the `root_section` that is also an ancestor of
  the current page. For this page, the `first_section` is `pages/docs/index.md`.
  For pages in the root section, `frist_section` and `root_section` are equal.
- `page_section`: The section directly enclosing this page.
  For this page, that's `docs/pages/docs/Content/index.md`

In addition, the following filters are available:

- `sectionOf`: This takes an uri or a path as input and returns the section enclosing
  that element. For instance `{{"{{ '../Templates/liquid.md' | sectionOf }}"}}` can
  be used to return the "Templates" section in this documentation.
- `isAncestor`: This takes an uri as an input and takes another uri as a parameter.
  It returns true if the section of the input is an ancestor of the section of the
  parameter.
  For instance, `{{"{{ '/index.html' | isAncestor: '' }}"}}` is `true`.
- Similarly, `isDescendant` takes two uris and returns `true` if the first section is
  a descendant of the second one.