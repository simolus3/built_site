import 'package:built_site/src/markdown/markdown.dart';
import 'package:test/test.dart';

void main() {
  test('headers with explicit ids', () {
    final html = renderToHtml(parse('''
## title {#custom-id}

Foo
'''));

    expect(html, '<h2 id="custom-id">title</h2>\n<p>Foo</p>');
  });
}
