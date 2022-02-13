import 'package:code_snippets/src/excerpts/excerpt.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  test('finds line numbers for excerpts', () {
    const source = r'''
// #docregion imports
import 'dart:async';
// #enddocregion imports

// #docregion main, main-stub
void main() async {
  // #enddocregion main-stub
  print('Compute π using the Monte Carlo method.');
  await for (var estimate in computePi().take(500)) {
    print('π ≅ $estimate');
  }
  // #docregion main-stub
}
// #enddocregion main, main-stub

/// Generates a stream of increasingly accurate estimates of π.
Stream<double> computePi({int batch: 100000}) async* {
  // ...
}
''';

    final sub = Logger('build.fallback').onRecord.listen((r) {
      fail('Unexpected log record $r');
    });
    addTearDown(sub.cancel);

    final excerpter = Excerpter('test', source)..weave();
    final excerpts = excerpter.excerpts.values;

    expect(excerpts, [
      Excerpt('(full)', [
        ContinousRegion(1, 2), // import 'dart:async';
        ContinousRegion(3, 4), //
        ContinousRegion(5, 6), // void main() async {
        ContinousRegion(7, 11), // print(...) until the `}` of `await for`
        ContinousRegion(12, 13), // closing brace of main
        ContinousRegion(14, 19), // rest of file without directives
      ]),
      Excerpt('imports', [
        ContinousRegion(1, 2), // import 'dart:async';
      ]),
      Excerpt('main', [
        ContinousRegion(5, 6), // void main() async {
        ContinousRegion(7, 11), // print(...) until the `}` of `await for`
        ContinousRegion(12, 13), // closing brace of main
      ]),
      Excerpt('main-stub', [
        ContinousRegion(5, 6), // void main() async {
        ContinousRegion(12, 13), // closing brace of main
      ]),
    ]);
  });
}
