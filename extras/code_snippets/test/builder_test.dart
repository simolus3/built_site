// ignore_for_file: unnecessary_string_escapes

import 'dart:convert';

import 'package:build_test/build_test.dart';
import 'package:code_snippets/builder.dart';
import 'package:test/test.dart';

void main() {
  test('strips common indent', () {
    return testBuilder(
      CodeExcerptBuilder(dropIndendation: true),
      {
        'a|lib/test.txt': '''
void main() {
  // #docregion test
  var x;
  foo + bar;
  // #enddocregion test
}
''',
      },
      outputs: {
        'a|lib/test.txt.excerpt.json': json.encode({
          '(full)': '''
void main() {
  var x;
  foo + bar;
}''',
          'test': 'var x;\nfoo + bar;',
        }),
      },
    );
  });

  test('small dart example', () async {
    await testBuilder(
      CodeExcerptBuilder(dropIndendation: true),
      {
        'a|lib/a.dart': '''
void main() {
  // #docregion main
  1 + 2;

  'foo';
  // #enddocregion main
}
''',
      },
      outputs: {
        'a|lib/a.dart.excerpt.json': json.encode({
          '(full)': '''
<span class="hljs-built_in">void</span> main() <span class="hljs-punctuation">{</span>
  <span class="hljs-number">1</span> + <span class="hljs-number">2</span>;

  <span class="hljs-string">&#39;foo&#39;</span>;
<span class="hljs-punctuation">}</span>''',
          'main': '''
<span class="hljs-number">1</span> + <span class="hljs-number">2</span>;

<span class="hljs-string">&#39;foo&#39;</span>;''',
        }),
      },
    );
  });
}
