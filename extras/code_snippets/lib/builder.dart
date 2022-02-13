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

const excerptLineLeftBorderChar = '|';

class CodeExcerptBuilder implements Builder {
  static const outputExtension = '.excerpt.json';

  final BuilderOptions? options;

  CodeExcerptBuilder([this.options]);

  @override
  Future<void> build(BuildStep buildStep) async {
    final assetId = buildStep.inputId;
    if (assetId.package.startsWith(r'$') || assetId.path.endsWith(r'$')) return;

    final content = await buildStep.readAsString(assetId);
    final outputAssetId = assetId.addExtension(outputExtension);

    final excerpter = Excerpter(assetId.path, content)..weave();
    final excerpts = excerpter.excerpts;

    if (excerpter.containsDirectives) {
      final source = SourceFile.fromString(content, url: assetId.uri);
      Highlighter? highlighter;

      switch (assetId.extension) {
        case '.dart':
          final library = await buildStep.inputLibrary;
          var resolvedUnit =
              await library.session.getResolvedUnit(library.source.fullName);
          CompilationUnit unit;

          if (resolvedUnit is ResolvedUnitResult) {
            unit = resolvedUnit.unit;
          } else {
            unit = await buildStep.resolver.compilationUnitFor(assetId);
          }

          highlighter = DartHighlighter(source, unit);
      }

      if (highlighter != null) {
        highlighter.highlight();

        final results = <String, Object?>{};

        for (final excerpt in excerpts.values) {
          final renderer =
              HighlightRenderer(highlighter, excerpt, (_, __, ___) => '');
          final html = renderer.renderHtml();

          results[excerpt.name] = html;
        }

        await buildStep.writeAsString(outputAssetId, json.encode(results));
      }
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '': [outputExtension]
      };
}
