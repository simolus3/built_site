---
data:
  title: Configuration
  description: Configure built_site for local builds and deployments
template: layouts/docs/single
---

## Themes

With built_site, themes are just regular Dart packages which you can apply.
built_site includes a reduced version of [Docsy]({{ '../Themes/docsy.md' | relUrl }})
which you may use by putting this into your `website.yaml`:

```yaml
themes:
  - docsy
```

In addition to the theme packages mentioned in your website configuration,
built_site implicitly adds the following themes:

- Your website itself. That way, you can declare a `theme.yaml` to write
  a [custom theme]({{ '../Themes/writing_themes' | relUrl }}) specific to your website.
- The `built_site` package, which is also a theme declaring some built-in
  components.

When declaring themes, the order is important: Themes mentioned earlier take
precedence when it comes to resolving templates or static assets.
For instance, `package:docsy` contains a `templates/blocks/alert.html` file.
If your project also had such file and you're using an `blocks/alert` block
in your website, it would resolve to the template file declared in your project.

## Environments

When building websites, you may want them to behave differently for debug
and release build.
In particular, you probably want to turn on minification for release builds only.

For this purpose, built_site supports environments which you can also declare
in your `website.yaml`:

```yaml
site:
  foo: "bar"

environments:
  dev:
    foo: "dev"
    minify: false
    base_url: "http://localhost:8080/"
  prod:
    foo: "prod"
    minify: true
    base_url: "https://my_cool_url.netlify.app/"
```

When building your website, the content of `site` and the active environment is
merged to obtain the value for a configuration key.
By default, regular builds use the `dev` environment and `--release` builds use the
`prod` environment.
However, you can also define additional environments for specific purposes.
To apply a specific environment, set the `environment` build option on the `built_site` builder:

```yaml
# build.yaml
targets:
  $default:
    builders:
      built_site:
        options:
          environment: 'my_custom_env'
```