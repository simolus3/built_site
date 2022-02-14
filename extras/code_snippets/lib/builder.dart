import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:source_span/source_span.dart';

import 'src/excerpts/excerpt.dart';
import 'src/highlight/highlighter.dart';
import 'src/highlight/languages/dart.dart';
import 'src/highlight/render.dart';

export 'src/excerpts/excerpt.dart';

const excerptLineLeftBorderChar = '|';

class CodeExcerptBuilder implements Builder {
  bool shouldEmitFor(AssetId input, Excerpter excerpts) {
    return excerpts.containsDirectives;
  }

  Future<Highlighter?> highlighterFor(
      AssetId assetId, String content, BuildStep buildStep) async {
    switch (assetId.extension) {
      case '.dart':
        final source = SourceFile.fromString(content, url: assetId.uri);
        final library = await buildStep.inputLibrary;
        var resolvedUnit =
            await library.session.getResolvedUnit(library.source.fullName);
        CompilationUnit unit;

        if (resolvedUnit is ResolvedUnitResult) {
          unit = resolvedUnit.unit;
        } else {
          unit = await buildStep.resolver.compilationUnitFor(assetId);
        }

        return DartHighlighter(source, unit);
    }

    return null;
  }

  String Function(
          Excerpt excerpt, ContinousRegion last, ContinousRegion upcoming)
      writePlasterFor(AssetId id) {
    return (_, __, ___) => '';
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
      highlighter.highlight();

      final results = <String, Object?>{};
      final writePlaster = writePlasterFor(assetId);

      for (final excerpt in excerpts.values) {
        final renderer = HighlightRenderer(highlighter, excerpt, writePlaster);
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
