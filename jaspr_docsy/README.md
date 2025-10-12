## jaspr_docsy

A port of the [Docsy](https://www.docsy.dev/) theme to `jaspr_content`.

This is used to build the website for drift, and is somewhat tailored towards
that.

## Differences to upstream:

- No `chroma` SCSS definitions.
- No embedded fonts for FontAwesome, these would have to be copied into the root project.
- Only a small subset of components have been ported so far.

Also note that this package uses SCSS (via `package:jaspr_docsy/style.scss`), that file would have
to be `@use`d from a custom entrypoint as well. Jaspr styles are not used here.
