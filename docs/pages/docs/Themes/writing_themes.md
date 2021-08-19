---
data:
  title: Writing themes
  description: How to setup your own theme package for built_site
  weight: 1
template: layouts/docs/single
---

In built_site, themes are just regular Dart packages that can be distributed
just like other Dart packages.

## Setup

To create a new theme, create a new Dart package which just involves creating a
`pubspec.yaml` in an empty folder.

Your theme package should depend on `built_site`. If you want to include 
additional Dart or Sass packages, you can depend on them as well. Since the
build configuration is part of a theme's public api, it's good practice to also
add a regular dependency on `build_config`.


```yaml
name: your_theme
version: 0.1.1

environment:
  sdk: '>=2.12.0 <3.0.0'

dependencies:
  built_site:
  build_config: ^1.0.0
```

Next, your theme needs a special build configuration so that its file available
in a built_site build.
To configure your theme, add a `build.yaml` file next to your `pubspec.yaml`
with the following content:

```yaml
additional_public_assets:
 - "i18n/**"
 - "static/**"
 - "templates/**"
 - "theme.yaml"
```

This tells Dart's build systems that the mentioned files and directories are
part of your themes public files and should be accessible in a build. 

## Adding content

With built_site, themes can contribute the following resources:

- Dart scripts
- Sass stylesheets
- Templates
- Static content - see [static content]({{ '../Content/static.md' | pageUrl }}) for details.