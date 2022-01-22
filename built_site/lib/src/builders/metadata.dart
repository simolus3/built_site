import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:path/path.dart' show url;
import 'package:source_span/source_span.dart';

import '../pages/front_matter.dart';

class MetadataBuilder extends Builder {
  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      '.md': ['.page_meta'],
      '.html': ['.page_meta'],
    };
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final input = buildStep.inputId;
    final content = await buildStep.readAsString(input);
    final doc = Document.parse(SourceFile.fromString(content, url: input.uri));
    final fm = doc.frontMatter ??= FrontMatter();

    String defaultPath() {
      final directorySegments = input.pathSegments..removeLast();
      final basename = url.basenameWithoutExtension(input.path);

      var htmlPath = url
          .joinAll([
            ...directorySegments,
            if (basename != 'index') url.basenameWithoutExtension(input.path)
          ])
          .replaceAll(' ', '-')
          .toLowerCase();

      if (url.isWithin('pages', htmlPath)) {
        htmlPath = url.relative(htmlPath, from: 'pages/');
      }

      return '$htmlPath/';
    }

    fm.path ??= defaultPath();

    final outputContent = json.encode({
      'source': input.toString(),
      ...doc.toJson(),
    });
    await buildStep.writeAsString(
        input.changeExtension('.page_meta'), outputContent);
  }
}
