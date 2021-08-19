import 'package:markdown/markdown.dart' as md;
import 'highlight.dart';

export 'package:markdown/markdown.dart';
export 'toc.dart';

const embeddRawHtml = 'built_site_begin_raw_html';

final _document = md.Document(
  blockSyntaxes: const [
    _HighlightingFencedCodeBlockSyntax(),
    _HeaderWithCustomIdSyntax(),
    md.SetextHeaderSyntax(),
    md.TableSyntax(),
    _EmbeddRawHtmlSyntax(),
  ],
  inlineSyntaxes: [
    md.InlineHtmlSyntax(),
    md.StrikethroughSyntax(),
    md.EmojiSyntax(),
    md.AutolinkExtensionSyntax(),
  ],
);

List<md.Node> parse(String content, {bool inline = false}) {
  List<md.Node> nodes;
  if (inline) {
    nodes = _document.parseInline(content);
  } else {
    // Replace windows line endings with unix line endings, and split.
    final lines = content.replaceAll('\r\n', '\n').split('\n');
    nodes = _document.parseLines(lines);
  }

  return nodes;
}

class _EmbeddRawHtmlSyntax extends md.BlockSyntax {
  static final _pattern = RegExp('$embeddRawHtml (\\d+)');

  const _EmbeddRawHtmlSyntax();

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current)!;
    final lines = int.parse(match.group(1)!);

    final buffer = StringBuffer();
    for (var i = 0; i < lines; i++) {
      parser.advance();
      buffer.writeln(parser.current);
    }

    return md.Text(buffer.toString());
  }

  @override
  RegExp get pattern => _pattern;
}

class _HeaderWithCustomIdSyntax extends md.BlockSyntax {
  static final _pattern =
      RegExp(r'^ {0,3}(#{1,6})[ \x09\x0b\x0c](.*?)(?:{#(.+)})?#*$');

  const _HeaderWithCustomIdSyntax();

  @override
  RegExp get pattern => _pattern;

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current)!;
    parser.advance();

    final level = match[1]!.length;
    final contents = md.UnparsedContent(match[2]!.trim());
    final element = md.Element('h$level', [contents]);

    return element
      ..generatedId = match[3] ?? md.BlockSyntax.generateAnchorHash(element);
  }
}

class _HighlightingFencedCodeBlockSyntax extends md.FencedCodeBlockSyntax {
  const _HighlightingFencedCodeBlockSyntax();

  @override
  md.Node parse(md.BlockParser parser) {
    // Get the syntax identifier, if there is one.
    final match = pattern.firstMatch(parser.current)!;
    final endBlock = match.group(1);
    var infoString = match.group(2)!;

    final childLines = parseChildLines(parser, endBlock);

    // The Markdown tests expect a trailing newline.
    childLines.add('');

    final text = childLines.join('\n');

    // the info-string should be trimmed
    // http://spec.commonmark.org/0.22/#example-100
    infoString = infoString.trim();

    String? language;
    final List<md.Node> children;

    if (infoString.isNotEmpty) {
      // only use the first word in the syntax
      // http://spec.commonmark.org/0.22/#example-100
      final firstSpace = infoString.indexOf(' ');
      if (firstSpace >= 0) {
        infoString = infoString.substring(0, firstSpace);
      }

      language = infoString;
      children = markdownHighlight(text, language: language);
    } else {
      children = [md.Text(text)];
    }

    final code = md.Element('code', children);
    final element = md.Element('pre', [code]);

    return element;
  }
}
