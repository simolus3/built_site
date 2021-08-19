import 'package:json_annotation/json_annotation.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

part 'front_matter.g.dart';

@JsonSerializable()
class Document {
  FrontMatter? frontMatter;
  final int contentStartOffset;

  Document(this.frontMatter, this.contentStartOffset);

  factory Document.fromJson(Map<String, Object?> json) {
    return _$DocumentFromJson(json);
  }

  Map<String, Object?> toJson() => _$DocumentToJson(this);

  static Document parse(SourceFile file) {
    String line(int n) {
      final start = file.getOffset(n);
      final end = n == file.lines - 1 ? null : file.getOffset(n + 1);
      return file.getText(start, end);
    }

    if (file.lines > 1 && line(0).startsWith(_delimiter)) {
      var firstContentLine = 1;
      final frontMatterLines = StringBuffer();

      for (; firstContentLine < file.lines; firstContentLine++) {
        final content = line(firstContentLine);
        if (content.startsWith(_delimiter)) {
          firstContentLine++;
          break;
        }

        frontMatterLines.write(content);
      }

      final yaml = loadYaml(frontMatterLines.toString()) as Map;
      final frontMatter = FrontMatter.fromJson(yaml.cast());

      final startOffset = firstContentLine >= file.lines
          ? file.length
          : file.getOffset(firstContentLine);
      return Document(frontMatter, startOffset);
    }

    return Document(null, 0);
  }

  static const _delimiter = '---';
}

/// Parsed front-matter options that a page can declare.
@JsonSerializable(anyMap: true)
class FrontMatter {
  /// Path component of the url eventually containing the page.
  ///
  /// This is an optional field. If not set, the path will be inferred from the
  /// location of the document.
  String? path;

  /// Aliases: A optional list of alternative urls where this page will be
  /// available.
  @JsonKey(defaultValue: <String>[])
  List<String> aliases;

  /// The template used to render this page.
  String? template;

  /// Additional data that the page makes available.
  @JsonKey(name: 'data')
  Map<String, Object?>? data;

  FrontMatter({
    this.path,
    this.aliases = const [],
    this.data,
    this.template,
  });

  factory FrontMatter.fromJson(Map<Object, Object?>? json) {
    return _$FrontMatterFromJson(json ?? const <String, Object?>{});
  }

  Map<String, Object?> toJson() => _$FrontMatterToJson(this);
}
