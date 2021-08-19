---
data:
  title: Docsy
  description: A port of the [docsy](https://www.docsy.dev/) theme to built_site
template: layouts/docs/single
---

Docsy is a popular theme for technical documentation written for the hugo
static site generator. `package:docsy` is a built_site re-implementation of
docsy.

## Applying the theme

To apply the theme, add a dependency to it to your `pubspec.yaml` and then use
it in `website.yaml`:

```yaml
dependencies:
  docsy: current

dev_dependencies:
  build_runner: ^2.0.3
```

```yaml
themes:
  - docsy
```

## Supported templates

At the moment, the docsy port for built_site supports the following templates:

### Site index

### Documentation index

### Documentation page

A single page of documentation typically uses the `layouts/docs/single` template.
