import 'package:markdown/markdown.dart' as md;
import 'highlight.dart';

export 'package:markdown/markdown.dart';
export 'toc.dart';

const embeddRawHtml = 'built_site_begin_raw_html';

List<md.Node> parse(String content, {bool inline = false}) {
  final document = md.Document(
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

  List<md.Node> nodes;
  if (inline) {
    nodes = document.parseInline(content);
  } else {
    // Replace windows line endings with unix line endings, and split.
    final lines = content.replaceAll('\r\n', '\n').split('\n');
    nodes = document.parseLines(lines);
  }

  return nodes;
}

class _EmbeddRawHtmlSyntax extends md.BlockSyntax {
  static final _pattern = RegExp('$embeddRawHtml (\\d+)');

  const _EmbeddRawHtmlSyntax();

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content)!;
    final lines = int.parse(match.group(1)!);

    final buffer = StringBuffer();
    for (var i = 0; i < lines; i++) {
      parser.advance();
      buffer.writeln(parser.current.content);
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
    final match = pattern.firstMatch(parser.current.content)!;
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
    final openingFence =
        _FenceMatch.fromMatch(pattern.firstMatch(parser.current.content)!);

    final childLines = parseChildLines(
      parser,
      openingFence.marker,
      openingFence.indent,
    );

    // The Markdown tests expect a trailing newline.
    childLines.add(md.Line(''));

    final text = childLines.map((e) => e.content).join('\n');

    var language = openingFence.hasLanguage ? openingFence.language : null;
    final List<md.Node> children;

    if (language != null) {
      // only use the first word in the syntax
      // http://spec.commonmark.org/0.22/#example-100
      final firstSpace = language.indexOf(' ');
      if (firstSpace >= 0) {
        language = language.substring(0, firstSpace);
      }

      children = markdownHighlight(text, language: language);
    } else {
      children = [md.Text(text)];
    }

    final code = md.Element('code', children);
    final element = md.Element('pre', [code]);

    return element;
  }
}

class _FenceMatch {
  _FenceMatch._({
    required this.indent,
    required this.marker,
    required this.info,
  });

  factory _FenceMatch.fromMatch(RegExpMatch match) {
    String marker;
    String info;

    if (match.namedGroup('backtick') != null) {
      marker = match.namedGroup('backtick')!;
      info = match.namedGroup('backtickInfo')!;
    } else {
      marker = match.namedGroup('tilde')!;
      info = match.namedGroup('tildeInfo')!;
    }

    return _FenceMatch._(
      indent: match[1]!.length,
      marker: marker,
      info: info.trim(),
    );
  }

  final int indent;
  final String marker;

  // The info-string should be trimmed,
  // https://spec.commonmark.org/0.30/#info-string.
  final String info;

  // The first word of the info string is typically used to specify the language
  // of the code sample,
  // https://spec.commonmark.org/0.30/#example-143.
  String get language => info.split(' ').first;

  bool get hasInfo => info.isNotEmpty;

  bool get hasLanguage => language.isNotEmpty;
}
