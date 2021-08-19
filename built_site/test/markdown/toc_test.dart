//@dart=2.9
import 'package:built_site/src/markdown/markdown.dart';
import 'package:test/test.dart';

void main() {
  test('generates flat ToC', () {
    const md = '''
## foo
      
## bar

## baz
    ''';

    final toc = TableOfContents.readFrom(parse(md));
    expect(
      toc.formatToc(),
      '<nav id="TableOfContents"><ul>'
      '<li><a href="#foo">foo</a></li>'
      '<li><a href="#bar">bar</a></li>'
      '<li><a href="#baz">baz</a></li>'
      '</ul></nav>',
    );
  });

  test('generates nested ToC', () {
    const md = '''
# top
      
## second

### third

#### fourth

##### fifth

### another third

## second (b)
    ''';

    final toc = TableOfContents.readFrom(parse(md));
    expect(
      toc.formatToc(),
      '<nav id="TableOfContents"><ul>'
      '<li><a href="#top">top</a></li>'
      '<ul><li><a href="#second">second</a></li>'
      '<ul><li><a href="#third">third</a></li>'
      '<ul><li><a href="#fourth">fourth</a></li>'
      '<ul><li><a href="#fifth">fifth</a></li>'
      '</ul></ul><li><a href="#another-third">another third</a></li>'
      '</ul><li><a href="#second-b">second (b)</a></li>'
      '</ul></ul></nav>',
    );
  });
}
