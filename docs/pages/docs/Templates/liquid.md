---
data:
  title: "Template Engine"
  description: Learn about Liquid, supported tags and variables
template: layouts/docs/single
---

## Liquid

built_site includes a custom Dart implementation of the [Liquid template engine](https://shopify.github.io/liquid/).
The template engine has been designed to work well with Dart's build system and its concept of incremental
rebuilds.

## Template components

Each template is made up by a sequential list of template components which are
evaluated to form the final page.
Every page itself is a template used once to render itself, which allows you to
embed template expressions inside a page.

### Assignments

You can assign expressions to a variable to re-use them later:

```liquid
{{ "{% assign foo = 'bar' %}" }}
{{ "Foo is {{ foo }}" }}
```

renders the following

```
{% assign foo = 'bar' %}
Foo is {{ foo }}
```

Variables are visible in the current template and all templates included later.

### Blocks

### Comments

A comment tag can be used to exclude the inner content from being rendered:

```liquid
{{ "{% comment %}" }}
Well, what did you expect?
{{ "{% endcomment %}" }}
```

renders as

```
{% comment %}
Well, what did you expect?
{% endcomment %}
```


### For-loops


### If-Statements

### Includes

### Expressions and objects

### Text