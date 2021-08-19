import 'package:built_site/src/pages/front_matter.dart';
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';

void main() {
  group('parses', () {
    test('documents without front matter', () {
      final result =
          Document.parse(SourceFile.fromString('regular\n document'));
      expect(result.contentStartOffset, 0);
      expect(result.frontMatter, isNull);
    });

    test('documents with front matter', () {
      const input = '''
---
path: /foo/bar
aliases: ["x", "y"]
template: "foo|templates/bar.html"
data:
  hello: world
---
document content''';

      final result = Document.parse(SourceFile.fromString(input));
      expect(input.substring(result.contentStartOffset), 'document content');
      expect(result.frontMatter?.toJson(), <String, Object?>{
        'path': '/foo/bar',
        'aliases': ['x', 'y'],
        'template': 'foo|templates/bar.html',
        'data': {'hello': 'world'}
      });
    });
    test('documents only consisting of front matter', () {
      const input = '''
---
path: /foo/bar
aliases: ["x", "y"]
template: "foo|templates/bar.html"
data:
  hello: world
---''';

      final result = Document.parse(SourceFile.fromString(input));
      expect(input.substring(result.contentStartOffset), isEmpty);
      expect(result.frontMatter?.toJson(), <String, Object?>{
        'path': '/foo/bar',
        'aliases': ['x', 'y'],
        'template': 'foo|templates/bar.html',
        'data': {'hello': 'world'}
      });
    });

    test('empty documents', () {
      final parsed = Document.parse(SourceFile.fromString(''));
      expect(parsed.frontMatter, isNull);
      expect(parsed.contentStartOffset, 0);
    });
  });
}
