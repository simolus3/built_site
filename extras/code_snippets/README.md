# code_snippets

__NOTE__: A more modern variant of this package is available for Jaspr [here](https://pub.dev/packages/jaspr_content_snippets).
I'm not using this package anymore, it's not maintained.

Builders to deal with code snippets extraced from source files.

Extracting snippets from source files is helpful as they can then be tested
more easily.

## Basic usage

```dart
// #docregion imports
import 'dart:async';
// #enddocregion imports

// #docregion main, main-stub
void main() async {
  // #enddocregion main-stub
  print('Compute π using the Monte Carlo method.');
  await for (var estimate in computePi().take(500)) {
    print('π ≅ $estimate');
  }
  // #docregion main-stub
}
// #enddocregion main, main-stub

/// Generates a stream of increasingly accurate estimates of π.
Stream<double> computePi({int batch: 100000}) async* {
  // ...
}
```

Use `#docregion` to open a region and `#enddocregion` to end it.
An implicit region named `(full)` contains the entire source file.
Directives like `#docregion` and `#enddocregion` are not included
in generated excerpts.

## Setup

This package defines builder classes, but doesn't configure them by default. It
is expected that users will subclass the builder to extract snippets and perhaps
customize it.

You can define a builder like this:

```yaml
builders:
  code_snippets:
    import: 'tool/snippets.dart'
    build_to: cache
    builder_factories: ["SnippetsBuilder.new"]
    build_extensions: {"": [".excerpt.json"]}
    auto_apply: none
```

where, in `tools/snippets.dart`, you can write:

```dart
class SnippetsBuilder extends CodeExcerptBuilder {
  SnippetsBuilder([BuilderOptions? options]) : super(dropIndendation: true);

  @override
  bool shouldEmitFor(AssetId input, Excerpter excerpts) {
    return true;
  }

  @override
  Future<Highlighter?> highlighterFor(
      AssetId assetId, String content, BuildStep buildStep) async {
    switch (assetId.extension) {
      case '.drift':
        // custom extensions supported by your builder
      default:
        // the default builder only supports dart files, which are semantically
        // highlighted using build_resolvers
        return super.highlighterFor(assetId, content, buildStep);
    }
  }
}
```

For each input file, the builder will emit a `.excerpt.json` file which contains
a  `Map<String, String>` from every highlight region to formatted HTML.

## Linking to dartdoc documentation

The builtin Dart highlighter can automatically create links to
dartdoc-generated documentation pages for some packages. For recognized
identifiers that reference elements from those package, a link to the relevant
page (typically under `https://pub.dev/documentation`) is added.

This feature requires an additional build step for setup: When we resolve an
element under `lib/src`, we need to find the proper, public library import
under `lib/` that exports this element.
This is currently implemented by another builder creating an index of exported
elements and their corresponding imports. This builder is provided under
`package:code_snippets/indexer.dart` but not configured. To enable it, define
it in your `build.yaml`:

```yaml
builders:
  api_index:
    import: 'package:code_snippets/indexer.dart'
    build_to: cache
    builder_factories: ['DartIndexBuilder.new']
    auto_apply: all_packages
    runs_before: [code_snippets]
    build_extensions: {"lib/lib": ['api.json']}
```

By default, this builder will do nothing. Configure the packages the builder
should run on in `global_options`:

```yaml
global_options:
  ":api_index":
    options:
      # generate index for these packages
      packages: ['drift', 'drift_dev']
```
