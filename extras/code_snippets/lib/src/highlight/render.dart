import 'package:build/build.dart';
import 'package:code_snippets/src/highlight/regions.dart';
import 'package:source_span/source_span.dart';

import '../excerpts/excerpt.dart';
import 'highlighter.dart';

class HighlightRenderer {
  final Highlighter highlighter;
  final Excerpt excerpt;

  String Function(
          Excerpt excerpt, ContinousRegion last, ContinousRegion upcoming)
      writePlaster;

  HighlightRenderer(this.highlighter, this.excerpt, this.writePlaster);

  String renderHtml() {
    highlighter.foundRegions.sort((a, b) => a.source.compareTo(b.source));

    // Drop intersecting regions (which really shouldn't exist).
    var largestOffset = 0;
    final regions = <HighlightRegion>[];

    for (final region in highlighter.foundRegions) {
      final start = region.source.start.offset;
      if (start < largestOffset) {
        log.warning('Intersecting highlight regions at ${region.source.text}.');
      } else {
        regions.add(region);
      }

      largestOffset = region.source.end.offset;
    }

    final buffer = StringBuffer();

    void text(FileSpan span) {
      buffer.write((span).text);
    }

    void region(HighlightRegion region, [FileSpan? span]) {
      buffer.write('<span class="${region.type.cssClass}">');
      text(span ?? region.source);
      buffer.write('</span>');
    }

    var currentRegion = 0;
    ContinousRegion? last;

    for (final chunk in excerpt.regions) {
      if (last != null) {
        buffer.write(writePlaster(excerpt, last, chunk));
      }

      // Find the first region that intersects this chunk of the excerpt.
      while (currentRegion < regions.length) {
        final current = regions[currentRegion];
        final endLine = current.source.end.line;

        if (endLine < chunk.startLine) {
          currentRegion++;
        } else {
          break;
        }
      }

      var offset = highlighter.file.getOffset(chunk.startLine);

      while (currentRegion < regions.length) {
        final current = regions[currentRegion];
        final startLine = current.source.start.line;
        final endLine = current.source.end.line;

        int startOffset, endOffset;
        var lastInChunk = false;

        if (startLine >= chunk.endLineExclusive) {
          // Already too far, skip!
          break;
        }

        // Ok, this region ends in the current chunk. Does it start there too?
        if (startLine >= chunk.startLine) {
          // It does! We don't have to cut off text from the beginning then.
          startOffset = current.source.start.offset;
        } else {
          // It doesn't, start at the start of the first line in this chunk.
          startOffset = highlighter.file.getOffset(chunk.startLine);
        }

        // Raw text that potentially comes before this region
        text(highlighter.file.span(offset, startOffset));

        // Same story for the end. Does it exceed this chunk?
        if (endLine >= chunk.endLineExclusive) {
          endOffset = highlighter.file.getLine(chunk.endLineExclusive);
          lastInChunk = true;
        } else {
          endOffset = current.source.end.offset;
        }

        region(current, highlighter.file.span(startOffset, endOffset));
        currentRegion++;
        offset = endOffset;
        if (lastInChunk) break;
      }

      text(highlighter.file.span(
          offset, highlighter.file.getOffset(chunk.endLineExclusive) - 1));

      last = chunk;
    }

    return buffer.toString();
  }
}

extension on RegionType {
  static const prefix = 'hljs';

  String get cssClass {
    switch (this) {
      case RegionType.builtIn:
        return '$prefix-built_in';
      case RegionType.escapeCharacter:
        return '$prefix-char escape_';
      case RegionType.languageVariable:
        return '$prefix-variable language_';
      case RegionType.constantVariable:
        return '$prefix-variable constant_';
      case RegionType.classTitle:
        return '$prefix-title class_';
      case RegionType.inheritedClassTitle:
        return '$prefix-title class_ inherited__';
      case RegionType.functionTitle:
        return '$prefix-title function_';
      case RegionType.invokedFunctionTitle:
        return '$prefix-title function_ invoked__';
      case RegionType.metaKeyword:
        return '$prefix-meta keyword';
      case RegionType.metaString:
        return '$prefix-meta string';
      case RegionType.selectorTag:
        return '$prefix-template-tag';
      case RegionType.selectorId:
        return '$prefix-template-id';
      case RegionType.selectorClass:
        return '$prefix-template-class';
      case RegionType.selectorAttr:
        return '$prefix-template-attr';
      case RegionType.selectorPseudo:
        return '$prefix-template-pseudo';
      case RegionType.templateTag:
        return '$prefix-template-tag';
      case RegionType.templateVariable:
        return '$prefix-template-variable';
      default:
        return '$prefix-$name';
    }
  }
}
