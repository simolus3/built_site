# built_site

__Note__: I'm not actively maintaining `built_site` anymore, I've migrated my projects to use
[jaspr content](https://docs.jaspr.site/content) instead.

This repository still contains the original sources and some tools related to jaspr.

built_site is a static site generator, built entirely on top of Dart's [build system](https://github.com/dart-lang/build/).

## Warning

At the moment, parts of the implementation are super hacky and heavily tailored towards my personal use cases.
I started to document some things and clean up the implementation, but it's a long way to go and not a high priority for me.
Taking moor's documentation (https://github.com/simolus3/moor/tree/develop/docs) as an example is probably the best way to
get started with these builders.

## Features

Thanks to `build_runner` and `webdev`, built_site contains all the great features you'd expect from a site generator:

- :watch: Fast and incremental rebuilds
- :loop: Rebuilding after file changes
- :zap: Page reloads after changes

In addition, built_site's 

- :package: Composable: Easily use it with [sass](https://pub.dev/packages/sass_builder), [Dart compilers](https://pub.dev/packages/build_web_compilers) or
  your own builders.
- Special Dart support: Uses the `analyzer` package for accurate syntax highlighting
- :floppy_disk: Minification for release builds
