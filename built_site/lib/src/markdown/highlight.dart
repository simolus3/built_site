import 'dart:convert';

import 'package:analyzer/dart/analysis/utilities.dart' as analyzer;

import 'package:highlight/highlight.dart';
import 'package:markdown/markdown.dart' as md;

import 'dart_highlight.dart' as dart;

List<md.Node> markdownHighlight(String source, {String? language}) {
  List<Node> highlightNodes;

  if (language == 'dart') {
    final result =
        analyzer.parseString(content: source, throwIfDiagnostics: false);
    highlightNodes = dart.highlightParsed(source, result.unit);
  } else {
    highlightNodes = _regularHighlight(source, language);
  }

  final converter = _HighlightToMarkdown();
  return converter.convert(highlightNodes);
}

List<Node> _regularHighlight(String source, String? language) {
  return highlight
          .parse(source, language: language, autoDetection: language == null)
          .nodes ??
      const [];
}

class _HighlightToMarkdown {
  List<md.Node> nodes = const [];

  void _visit(Node node) {
    final className = node.className;
    final needsSpan = className != null &&
        ((node.value != null && node.value!.isNotEmpty) ||
            (node.children != null && node.children!.isNotEmpty));

    if (needsSpan) {
      final safedNodes = nodes;
      nodes = [];
      _addChildNodes(node);

      final prefix = node.noPrefix ? '' : 'hljs-';
      final element = md.Element.withTag('span');
      element.children!.addAll(nodes);
      element.attributes['class'] = prefix + className;

      nodes = safedNodes..add(element);
    } else {
      _addChildNodes(node);
    }
  }

  void _addChildNodes(Node node) {
    if (node.value != null) {
      nodes.add(md.Text(escaper.convert(node.value!)));
    } else if (node.children != null) {
      node.children!.forEach(_visit);
    }
  }

  List<md.Node> convert(List<Node> resultNodes) {
    nodes = [];
    resultNodes.forEach(_visit);
    return nodes;
  }

  static const escaper = HtmlEscape(HtmlEscapeMode.element);
}
