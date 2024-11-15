import 'dart:convert';
import 'dart:math';

import 'package:build/build.dart';
import 'package:code_snippets/src/highlight/regions.dart';
import 'package:source_span/source_span.dart';

import '../excerpts/excerpt.dart';
import 'highlighter.dart';
import 'style.dart';

String _escape(String source) {
  const escaper = HtmlEscape();
  return escaper.convert(source);
}

class HighlightRenderer {
  final Highlighter highlighter;
  final Excerpt excerpt;
  final bool removeIndent;
  final CodeStyleBuilder styles;

  String Function(
          Excerpt excerpt, ContinousRegion last, ContinousRegion upcoming)
      writePlaster;

  HighlightRenderer(
    this.highlighter,
    this.excerpt,
    this.writePlaster,
    this.removeIndent,
    this.styles,
  );

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

    void text(FileSpan span, [int stripIndent = 0]) {
      if (stripIndent == 0) {
        buffer.write(_escape(span.text));
      } else {
        // Go through the span line by line. If it starts at the beginning of a
        // line, drop the first [stripIndent] units.
        final file = span.file;

        // First line, cut of `start column - stripIndent` chars at the start
        buffer.write(_escape(file.getText(
          span.start.offset + max(0, stripIndent - span.start.column),
          min(file.getOffset(span.start.line + 1) - 1, span.end.offset),
        )));

        for (var line = span.start.line + 1; line <= span.end.line; line++) {
          buffer.writeln();

          final endOffset = min(file.getOffset(line + 1) - 1, span.end.offset);
          final start = file.getOffset(line) + stripIndent;

          if (start < endOffset) {
            // If the span spans multiple lines and this isn't the first one, we
            // can just cut of the first chars.
            buffer.write(_escape(file.getText(start, endOffset)));
          }
        }
      }
    }

    void region(HighlightRegion region, [FileSpan? span, int stripIndent = 0]) {
      final docsUri = region.documentationUri;
      final classes = styles.cssClassesFor(region);

      buffer.write(classes != null ? '<span class="$classes">' : '<span>');
      if (docsUri != null) {
        buffer.write('<a href="$docsUri">');
      }
      text(span ?? region.source, stripIndent);
      if (docsUri != null) {
        buffer.write('</a>');
      }
      buffer.write('</span>');
    }

    var currentRegion = 0;
    ContinousRegion? last;

    for (final chunk in excerpt.regions) {
      final stripIndent = removeIndent ? chunk.indentation.length : 0;

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
        text(highlighter.file.span(offset, startOffset), stripIndent);

        // Same story for the end. Does it exceed this chunk?
        if (endLine >= chunk.endLineExclusive) {
          endOffset = highlighter.file.getLine(chunk.endLineExclusive);
          lastInChunk = true;
        } else {
          endOffset = current.source.end.offset;
        }

        region(current, highlighter.file.span(startOffset, endOffset),
            stripIndent);
        currentRegion++;
        offset = endOffset;
        if (lastInChunk) break;
      }

      // Raw text at the end of this continous region that is not a highlight
      // region.
      text(
        highlighter.file.span(
            offset, highlighter.file.getOffset(chunk.endLineExclusive) - 1),
        stripIndent,
      );

      last = chunk;
    }

    return buffer.toString();
  }
}
