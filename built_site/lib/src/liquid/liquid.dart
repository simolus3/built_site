/// A Dart implementation of the [Liquid][lq] templating engine.
///
/// [lq]: https://shopify.github.io/liquid/
library liquid;

import 'dart:async';
import 'dart:typed_data';

import 'package:build/build.dart';
import 'package:path/path.dart' show url;
import 'package:source_span/source_span.dart';
import 'package:synchronized/synchronized.dart';

import '../config.dart';

import 'ast/node.dart';
import 'parser/lexer.dart';
import 'parser/parser.dart';

export 'ast/components.dart';
export 'eval/evaluator.dart';

class TemplateResolver {
  final Map<AssetId, TemplateComponent> _parsedTemplates = {};
  final SiteConfig config;

  final Lock _readerLock = Lock();

  TemplateResolver(this.config) {
    log.finest('Tempate resolver created');
  }

  Future<AssetId> _resolveTemplate(AssetReader reader, String name) async {
    var resolvedName = name;
    if (url.withoutExtension(name) == name) {
      resolvedName = url.setExtension(name, '.html');
    }

    final candidates = config.effectiveThemes
        .map((pkg) => AssetId(pkg, 'templates/$resolvedName'))
        .toList();

    for (final id in candidates) {
      if (await reader.canRead(id)) return id;
    }

    throw Exception(
        'Template $name not found (looked in ${candidates.join(', ')})');
  }

  Future<TemplateComponent> getOrParse(AssetReader reader, String name) async {
    final id = await _resolveTemplate(reader, name);
    final fromCache = await _readFromCache(reader, id);
    if (fromCache != null) return fromCache;

    return _readerLock.synchronized(() async {
      return await _readFromCache(reader, id) ??
          await _parseUnlocked(reader, id);
    });
  }

  FutureOr<TemplateComponent?> _readFromCache(AssetReader reader, AssetId id) {
    if (_parsedTemplates.containsKey(id)) {
      final template = _parsedTemplates[id];
      // Still read the asset, we wan't reproducible builds!
      return reader.canRead(id).then((_) => template);
    } else {
      return null;
    }
  }

  Future<TemplateComponent> _parseUnlocked(
      AssetReader reader, AssetId id) async {
    final raw = await reader.readAsString(id);
    log.fine('Parsing template from $id');
    return _parsedTemplates[id] = parseString(raw, url: id.uri);
  }

  static TemplateComponent parseString(String source,
      {int offset = 0, Uri? url}) {
    final decoded = Uint32List.fromList(source.codeUnits);
    final input = SourceFile.decoded(decoded, url: url);

    final lexer = Lexer(input, decoded, offset);
    final parser = Parser(lexer);
    return parser.parseBlock();
  }
}
