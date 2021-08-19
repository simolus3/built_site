import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:built_site/src/config.dart';
import 'package:built_site/src/liquid/liquid.dart';
import 'package:test/test.dart';

void main() {
  final resolver = TemplateResolver(SiteConfig.fromJson('a', const {}));

  group('evaluates', () {
    final expressions = {'-3': '-3'};

    expressions.forEach((source, result) {
      test(source, () async {
        final component = TemplateResolver.parseString(
          '{{ $source }}',
          url: Uri.parse('package:foo/bar.html'),
        );
        final evaluator = TemplateEvaluator(StubAssetReader(), resolver);

        expect(await evaluator.render(component), result);
      });
    });
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
