---
data:
  title: "Static content"
  description: Add static content to your website
template: layouts/docs/single
---

You can add static files to your website or to a theme. Static content will not
be processed by built_site in any way, it will directly be copied to your 
generated site.

## Adding static content to a website

The easiest and fastest way to add static content to your website is to just
add it into the `web/` folder of your project. In the end, this folder is what
`webdev` and `build_runner` will serve or build.
Since static files are not meant to be transformed, you can just copy them into
`web/` and skip the whole build process for them.

For instance, if you had a structure as follows:

```
└── my_website/
    ├── web/
    │   ├── favicon.ico
    │   └── images/
    │       └── dog.png
    ├── website.yaml
    └── pubspec.yaml
```

Then `favicon.ico` would be avilable under `$baseUri/favicon.ico` and the image
would be available under `$baseUri/images/dog.png`.

## Adding static content to a theme

If you have content in a theme that should be copied into every website 
applying that theme, add it to the `static` directory of your theme package.
built_site will merge all `static` folders across all themes, filter out
duplicates (see the section below) and finally write them as cached files into
`web/`.

For instance, if you declare a theme as follows

```
└── my_theme/
    ├── static/
    │   └── theme.txt
    ├── theme.yaml
    └── pubspec.yaml
```

Then the `theme.txt` file would be copied into every website applying that
theme (available under `/theme.txt` in the website's base uri).

### Overriding static content

When built_site collects static files across themes, it goes through themes in
the following order:

1. Your own website
2. The themes listed in your `website.yaml`
3. The `built_site` package (which does not contain any static content)

When a static file has already been seen, further declarations of that file
will be ignored. Effectively, this means that you can override the static
content of themes by putting a file with the same name under `static/`.
For instance, if you applied the theme from above and have the following 
directory layout, the `theme.txt` from the theme would not be copied.

```
└── my_website/
    ├── static/
    │   └── theme.txt
    ├── website.yaml
    └── pubspec.yaml
```

Please note that the process of indexing static content across themes is fairly
expensive and hard to do incrementally with Dart's build system. For this
reason, it is recommended to just add static content to `web/` and avoid 
`static/` where possible.
