---
data:
  title: "Building your website"
  description: How to write, build and deploy your website
template: layouts/docs/single
---

built_site itself does not include any programs to build your website.
Instead, it delegates this work to an implementation of Dart's [build system](https://github.com/dart-lang/build/),
most notably the [`build_runner` package](https://pub.dev/packages/build_runner).

To build your website with `build_site`, first add a development dependency on the `build_runner`
package:

```yaml
dev_dependencies:
  build_runner: ^2.0.0
```

## Development

When you're working on a website, you're typically interested in fast and 
incremental rebuilds as you edit content. While `build_runner` supports this
out of the box, you may have a better experience with the `webdev` package.
`webdev` wraps a build implementation with special support for web development.
If can help you debug Dart code that you may use on your website.

Webdev can be activated globally, but we recommend adding a dependency to
ensure you'll always get a predictable version. So, just add it as a development
dependency as well:

```yaml
dev_dependencies:
  build_runner: ^2.0.0
  webdev: ^0.7.4
```

Then, you can run the following command to get a live view of your generated
website:

```
$ dart run webdev serve --auto refresh pages:9999 web:8080
```

This will serve your final website on port `8080`, reloading relevant pages as
they change.
Serving the `pages` directory on another port is unfortunately necessary as the
build system wouldn't compile pages otherwise. You can choose any free port for
this as you won't ever interact with it anyway.

## Release builds

You can obtain a built version of your website ready for deployment with the
following commands:

```
$ dart run build_runner --release
$ dart run build_runner --release -o web:build/
```

This will copy all generated assets into a `build/` folder.

Once again, the first invocation is unfortunately necessary to ensure
that `build_runner` runs on all inputs.
