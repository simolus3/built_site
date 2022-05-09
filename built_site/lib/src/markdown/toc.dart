import 'package:markdown/markdown.dart';

class TableOfContents {
  final List<TocEntry> flatEntries;

  TableOfContents._(this.flatEntries);

  const TableOfContents.empty() : flatEntries = const [];

  static TableOfContents readFrom(List<Node> nodes) {
    final visitor = _ContentsFindingVisitor();
    for (final node in nodes) {
      node.accept(visitor);
    }

    return TableOfContents._(visitor._entries);
  }

  /// See also: https://gohugo.io/content-management/toc/
  String formatToc() {
    final buffer = StringBuffer('<nav id="TableOfContents">');
    final levelStack = <int>[];

    for (final entry in flatEntries) {
      final level = entry.level;

      if (levelStack.isEmpty) {
        // Entry starts the list
        buffer.write('<ul>');
        levelStack.add(level);
      } else if (level > levelStack.last) {
        // Entry is in a new, nested list
        buffer.write('<li><ul>');
        levelStack.add(level);
      } else {
        while (level < levelStack.last) {
          // Nested level closes
          levelStack.removeLast();
          buffer.write(levelStack.isEmpty ? '</ul>' : '</ul></li>');
        }
      }

      // Write the entry in the current list
      buffer.write('<li><a href="#${entry.anchor}">${entry.linkHtml}</a></li>');
    }

    while (levelStack.isNotEmpty) {
      levelStack.removeLast();
      buffer.write(levelStack.isEmpty ? '</ul>' : '</ul></li>');
    }

    buffer.write('</nav>');

    return buffer.toString();
  }
}

class _ContentsFindingVisitor implements NodeVisitor {
  static final RegExp _headerTag = RegExp('h(\\d)');
  final List<TocEntry> _entries = [];

  @override
  void visitElementAfter(Element element) {}

  @override
  bool visitElementBefore(Element element) {
    final match = _headerTag.firstMatch(element.tag);
    if (match != null) {
      final level = int.parse(match.group(1)!);
      final anchor = element.generatedId ?? '';
      final innerHtml = renderToHtml(element.children ?? const []);

      _entries.add(TocEntry(anchor, innerHtml, level));
    }

    return false;
  }

  @override
  void visitText(Text text) {}
}

class TocEntry {
  final String anchor;
  final String linkHtml;

  /// The level of this heading, from 1 to 6.
  final int level;

  TocEntry(this.anchor, this.linkHtml, this.level);
}
