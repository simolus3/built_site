## 0.2.13

- Fix parsing `offset` parameters in for loops.
- Add `emit_content_file` builder option. When enabled, the rendered markdown of a page
  will be emitted before the page's template is applied into a `.page_content` file.
- Add the `changeExtension` filter.

## 0.2.12

- Fix markdown link references not being scoped to documents as they should be.

## 0.2.11

- Support analyzer 5.x

## 0.2.10

- Upgrade to the latest `markdown` and `analyzer` packages.

## 0.2.9

- Fix a bug in the liquid lexer causing `{` to not be recognized in some cases.

## 0.2.8

- Support latest analyzer version

## 0.2.7

- Support [whitespace control](https://shopify.github.io/liquid/basics/whitespace/)
  in Liquid filters.

## 0.2.6

- Add `reverse` filter for lists
- Builder options passed to `built_site:built_site` are now available to pages
  via `built_site.config`.
