import 'dart:convert';

import 'package:build/build.dart';
import 'package:yaml/yaml.dart';

import 'src/builders/copy_to_web.dart';
import 'src/builders/generator.dart';
import 'src/builders/hash.dart';
import 'src/builders/indexer.dart';
import 'src/builders/metadata.dart';
import 'src/builders/theme_content.dart';
import 'src/config.dart';

Builder extractThemes(BuilderOptions options) => const _ExtractThemes();

Builder metadata(BuilderOptions options) {
  return MetadataBuilder();
}

Builder index(BuilderOptions options) {
  return Indexer();
}

Builder hash(BuilderOptions options) {
  return const HashBuilder();
}

Builder generator(BuilderOptions options) {
  return SiteGenerator(options.config['environment'] as String, options);
}

Builder localThemeIndex(BuilderOptions options) => const LocalThemeIndexer();

Builder indexThemes(BuilderOptions options) => const ThemeIndexer();

PostProcessBuilder postProcess(BuilderOptions options) {
  return CopyToWeb();
}

PostProcessBuilder extractStatic(BuilderOptions options) {
  return const ExtractStatic();
}

class _ExtractThemes implements Builder {
  const _ExtractThemes();

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      'website.yaml': ['lib/built_site_themes.json']
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final input = buildStep.inputId;
    final dynamic content =
        loadYaml(await buildStep.readAsString(input), sourceUrl: input.uri);
    if (content is! Map) return;

    final config = SiteConfig.fromJson(input.package, content.cast());
    await buildStep.writeAsString(
        AssetId(input.package, 'lib/built_site_themes.json'),
        json.encode(config.effectiveThemes));
  }
}
