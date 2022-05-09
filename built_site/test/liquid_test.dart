import 'package:build_test/build_test.dart';
import 'package:built_site/src/config.dart';
import 'package:built_site/src/liquid/liquid.dart';
import 'package:test/test.dart';

void main() {
  final resolver = TemplateResolver(SiteConfig.fromJson('a', const {}));
  final evaluator = TemplateEvaluator(StubAssetReader(), resolver);

  group('evaluates', () {
    final expressions = {'-3': '-3'};

    expressions.forEach((source, result) {
      test(source, () async {
        final component = TemplateResolver.parseString(
          '{{ $source }}',
          url: Uri.parse('package:foo/bar.html'),
        );

        expect(await evaluator.render(component), result);
      });
    });
  });

  test('generates pages', () {
    const template = '''
<!doctype html>
<html lang="{{ site.language }}" class="no-js">
  <head>
    {{ '<!-- head -->' }}
  </head>
  <body class="td-{{ kind }}">
    <header>
      {{ '<!-- header -->' }}
    </header>
    <div class="container-fluid td-default td-outer">
      <main role="main" class="td-main">
        {{ '<!-- main -->' }}
      </main>
      {{ '<!-- footer -->' }}
    </div>
  </body>
</html>''';

    final component = TemplateResolver.parseString(template);
    final rendered = evaluator.render(component);

    expect(rendered, completion('''<!doctype html>
<html lang="null" class="no-js">
  <head>
    <!-- head -->
  </head>
  <body class="td-null">
    <header>
      <!-- header -->
    </header>
    <div class="container-fluid td-default td-outer">
      <main role="main" class="td-main">
        <!-- main -->
      </main>
      <!-- footer -->
    </div>
  </body>
</html>'''));
  });

  test('whitespace control', () {
    const template = '''
{%- if username and (username | length | gt: 10) -%}
  Wow, {{ username -}} , you have a long name!
{%- else -%}
  Hello there!
{%- endif -%}

''';

    final component = TemplateResolver.parseString(template);
    expect(evaluator.render(component), completion('Hello there!'));
    expect(
        evaluator
            .render(component, variables: {'username': 'this is a long name'}),
        completion('Wow, this is a long name, you have a long name!'));
  });

  test('provides a contextual error message for evaluation errors', () {
    final component = TemplateResolver.parseString(
      '{{ "foo" | throw }}',
      url: Uri.parse('package:foo/bar.html'),
    );
    final evaluator = TemplateEvaluator(StubAssetReader(), resolver);
    expect(
      evaluator.render(component, additionalFilters: {
        'throw': (input, args) => throw StateError('expected')
      }),
      throwsA(isA<Exception>().having(
        (e) => e.toString(),
        'toString()',
        '''
Error evaluating package:foo/bar.html: 
line 1, column 4 of package:foo/bar.html: Bad state: expected
  ╷
1 │ {{ "foo" | throw }}
  │    ^^^^^^^^^^^^^
  ╵''',
      )),
    );
  });
}
