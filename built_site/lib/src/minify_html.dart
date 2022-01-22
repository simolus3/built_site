import 'package:charcode/ascii.dart';
import 'package:html/dom.dart';
import 'package:html/dom_parsing.dart' show isVoidElement, htmlSerializeEscape;
import 'package:html/parser.dart';

/// Parses [input] as an html document and removes unecessary whitespace.
String minifyHtml(String input) {
  final document = parse(input);
  final visitor = _MinifyingVisitor()..visit(document);
  return visitor.out.toString();
}

class _MinifyingVisitor {
  final StringBuffer out = StringBuffer();

  void visit(Node node, {bool isFirst = false, bool isLast = false}) {
    switch (node.nodeType) {
      case Node.ATTRIBUTE_NODE:
      case Node.CDATA_SECTION_NODE:
      case Node.COMMENT_NODE:
      case Node.ENTITY_REFERENCE_NODE:
      case Node.NOTATION_NODE:
      case Node.PROCESSING_INSTRUCTION_NODE:
      case Node.ENTITY_NODE:
        break;
      case Node.DOCUMENT_NODE:
      case Node.DOCUMENT_FRAGMENT_NODE:
        visitList((node as Document).nodes);
        break;
      case Node.DOCUMENT_TYPE_NODE:
        final name = (node as DocumentType).name;
        out.write('<!doctype $name>');
        break;
      case Node.ELEMENT_NODE:
        final el = node as Element;
        if (el.localName == 'pre') {
          out.write(el.outerHtml);
          break;
        }

        out.write('<${el.localName}');
        el.attributes.forEach((key, v) {
          out.write(' ');
          out.write(key);
          out.write('="');
          out.write(htmlSerializeEscape(v, attributeMode: true));
          out.write('"');
        });
        out.write('>');

        visitList(node.nodes);

        if (!isVoidElement(el.localName)) {
          out.write('</${el.localName}>');
        }

        break;
      case Node.TEXT_NODE:
        final text = (node as Text).text;
        _text(text, trimStart: isFirst, trimEnd: isLast);
    }
  }

  void _text(String text, {bool trimStart = false, bool trimEnd = true}) {
    var hasWhitespace = false;
    var hadNonWhitespace = false;

    final buffer = StringBuffer();
    for (final char in text.codeUnits) {
      if (_whitespace.contains(char)) {
        hasWhitespace = !trimStart | hadNonWhitespace;
      } else {
        if (hasWhitespace) {
          buffer.writeCharCode($space);
          hasWhitespace = false;
        }
        buffer.writeCharCode(char);
        hadNonWhitespace = true;
      }
    }

    if (hasWhitespace && !trimEnd) buffer.writeCharCode($space);

    out.write(htmlSerializeEscape(buffer.toString()));
  }

  void visitList(NodeList list) {
    for (var i = 0; i < list.length; i++) {
      visit(list[i], isFirst: i == 0, isLast: i == list.length - 1);
    }
  }

  static const _whitespace = [
    $space,
    $lf,
    $cr,
    $tab,
  ];
}
