import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:source_span/source_span.dart';

import 'src/excerpts/excerpt.dart';
import 'src/highlight/highlighter.dart';
import 'src/highlight/dart/highlighter.dart';
import 'src/highlight/render.dart';
import 'src/highlight/style.dart';

export 'src/excerpts/excerpt.dart';

const excerptLineLeftBorderChar = '|';

class CodeExcerptBuilder implements Builder {
  /// Whether common indendation should be removed when rendering text.
  ///
  /// If enabled, a highlight region like:
  ///
  /// ```
  /// void myFunction() {
  ///   // #docregion test
  ///   fun1();
  ///   fun2();
  ///   // #enddocregion test
  /// }
  /// ```
  ///
  /// would be rendered like
  ///
  /// ```
  /// fun1();
  /// fun2();
  /// ```
  ///
  /// If disabled (the default), it would be rendered as
  ///
  /// ```
  ///  fun1();
  ///  fun2();
  /// ```
  final bool dropIndendation;

  final Map<String, Uri> overriddenDartDocUrls;
  final CodeStyleBuilder styles;

  CodeExcerptBuilder({
    this.dropIndendation = false,
    this.overriddenDartDocUrls = const {},
    this.styles = const HighlightJsStyles(),
  });

  bool shouldEmitFor(AssetId input, Excerpter excerpts) {
    return excerpts.containsDirectives;
  }

  Future<Highlighter?> highlighterFor(
      AssetId assetId, String content, BuildStep buildStep) async {
    switch (assetId.extension) {
      case '.dart':
        final source = SourceFile.fromString(content, url: assetId.uri);
        final library = await buildStep.inputLibrary;

        var resolvedUnit = await library.session
            .getResolvedUnit(library.firstFragment.source.fullName);
        CompilationUnit unit;

        if (resolvedUnit is ResolvedUnitResult) {
          unit = resolvedUnit.unit;
        } else {
          unit = await buildStep.resolver.compilationUnitFor(assetId);
        }

        return DartHighlighter(source, buildStep, unit, overriddenDartDocUrls);
    }

    return null;
  }

  String Function(
          Excerpt excerpt, ContinousRegion last, ContinousRegion upcoming)
      writePlasterFor(AssetId id) {
    return (_, __, ___) => '\n';
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final assetId = buildStep.inputId;
    if (assetId.package.startsWith(r'$') || assetId.path.endsWith(r'$')) return;

    final content = await buildStep.readAsString(assetId);
    final outputAssetId = buildStep.allowedOutputs.single;

    final excerpter = Excerpter(assetId.path, content)..weave();
    final excerpts = excerpter.excerpts;

    if (shouldEmitFor(assetId, excerpter)) {
      final source = SourceFile.fromString(content, url: assetId.uri);

      final highlighter = await highlighterFor(assetId, content, buildStep) ??
          NullHighlighter(source);
      await highlighter.highlight();

      final results = <String, Object?>{};
      final writePlaster = writePlasterFor(assetId);

      for (final excerpt in excerpts.values) {
        final renderer = HighlightRenderer(
            highlighter, excerpt, writePlaster, dropIndendation, styles);
        final html = renderer.renderHtml();

        results[excerpt.name] = html;
      }

      await buildStep.writeAsString(outputAssetId, json.encode(results));
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '': ['.excerpt.json'],
      };
}
