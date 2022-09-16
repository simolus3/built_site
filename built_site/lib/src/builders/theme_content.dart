import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' show url;
import 'package:tar/tar.dart';
import 'package:yaml/yaml.dart';

import '../theme.dart';

class LocalThemeIndexer implements Builder {
  const LocalThemeIndexer();

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'pubspec.yaml': ['lib/built_site_theme.json']
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    log.fine('Indexing theme package ${buildStep.inputId.package}');

    Future<List<String>> findAssets(Glob glob) {
      return buildStep.findAssets(glob).map((a) => a.path).toList();
    }

    final static = await findAssets(Glob('static/**'));
    final i18n = await findAssets(Glob('i18n/**'));

    final configId = AssetId(buildStep.inputId.package, 'theme.yaml');
    ThemeConfig config;
    if (await buildStep.canRead(configId)) {
      config = ThemeConfig.fromYaml(
          await buildStep.readAsString(configId), configId.uri);
    } else {
      config = ThemeConfig(const {});
    }

    final resources = FoundThemeResources(static, i18n, config);
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'lib/built_site_theme.json'),
      json.encode(resources.toJson()),
    );
  }
}

/// Runs on the root package, generating a tar file of static assets and all
/// translation keys contributed by themes.
///
/// We have another builder generating `built_site_themes.json` from the themes
/// referenced in a `website.yaml` file. This is to avoid rebuilds for harmless
/// edits to that file -- indexing themes is expensive!
class ThemeIndexer implements Builder {
  const ThemeIndexer();

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      'lib/built_site_themes.json': [
        'lib/static_content.tar',
        'lib/i18n_merged.json',
        'web/main.scss',
        'web/main.dart',
      ],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    log.info('Indexing themes, this might take a short while.');
    final websitePackages =
        (json.decode(await buildStep.readAsString(buildStep.inputId)) as List)
            .cast<String>();

    // Create a tar file of all static assets
    final contentFiles = <String>{};
    final outputBytes = BytesBuilder();
    final contents = StreamController<TarEntry>();
    final encodeTar =
        contents.stream.transform(tarWriter).forEach(outputBytes.add);

    // Also index all i18n keys. map from language to keys to values
    final i18n = <String, Map<String, String>>{};
    final contributions = <String, List<AssetId>>{};

    for (final pkg in websitePackages) {
      final themeDescriptorId = AssetId(pkg, 'lib/built_site_theme.json');
      if (!await buildStep.canRead(themeDescriptorId)) continue;

      final rawResources =
          json.decode(await buildStep.readAsString(themeDescriptorId))
              as Map<String, Object?>;
      final resources = FoundThemeResources.fromJson(rawResources);

      for (final path in resources.static) {
        final asset = AssetId(pkg, path);
        final name = url.relative(path, from: 'static/');
        if (contentFiles.add(name)) {
          final entry = TarEntry.data(
            TarHeader(name: name),
            await buildStep.readAsBytes(asset),
          );
          contents.add(entry);
        }
      }

      for (final path in resources.i18n) {
        final language = url.basenameWithoutExtension(path);
        final existing = i18n.putIfAbsent(language, () => {});
        final asset = AssetId(pkg, path);

        final definedHere =
            loadYaml(await buildStep.readAsString(asset), sourceUrl: asset.uri)
                as Map;
        definedHere.cast<String, String>().forEach((key, value) {
          existing.putIfAbsent(key, () => value);
        });
      }

      resources.config?.contributes.forEach((lang, path) {
        final asset = AssetId(pkg, path);
        contributions.putIfAbsent(lang, () => []).add(asset);
      });
    }

    await contents.close();
    await encodeTar;
    await buildStep.writeAsBytes(
        buildStep.inputId.sibling('static_content.tar'),
        outputBytes.takeBytes());

    await buildStep.writeAsString(
        buildStep.inputId.sibling('i18n_merged.json'), json.encode(i18n));
    final mainPackage = buildStep.inputId.package;

    // Write Dart and Sass sources referencing all the contributions across
    // themes.
    final sassContributions = contributions['sass'] ?? const [];
    if (sassContributions.isNotEmpty) {
      final sassOut = AssetId(mainPackage, 'web/main.scss');
      final mainSass = (contributions['sass'] ?? const [])
          .map((f) => '@import "${f.uri}";')
          .join('\n');
      await buildStep.writeAsString(sassOut, mainSass);
    }

    final dartContributions = contributions['dart'] ?? const [];
    if (dartContributions.isNotEmpty) {
      final dartOut = AssetId(mainPackage, 'web/main.dart');
      final mainDart = StringBuffer();
      final dartImports = contributions['dart'] ?? const [];
      for (var i = 0; i < dartImports.length; i++) {
        mainDart.writeln("import '${dartImports[i].uri}' as i$i;");
      }
      mainDart.writeln('void main() {');
      for (var i = 0; i < dartImports.length; i++) {
        mainDart.writeln('  i$i.built_site_main();');
      }
      mainDart.write('}');

      await buildStep.writeAsString(dartOut, mainDart.toString());
    }
  }
}

class ExtractStatic implements PostProcessBuilder {
  const ExtractStatic();

  @override
  Iterable<String> get inputExtensions => const ['static_content.tar'];

  @override
  Future<void> build(PostProcessBuildStep buildStep) async {
    // Extract tar file into web/
    final tarStream = Stream.value(await buildStep.readInputAsBytes());
    await TarReader.forEach(tarStream, (entry) async {
      final output =
          AssetId(buildStep.inputId.package, url.join('web/', entry.name));

      final bytesBuilder = BytesBuilder();
      await entry.contents.forEach(bytesBuilder.add);
      await buildStep.writeAsBytes(output, bytesBuilder.takeBytes());
    });
  }
}

extension on AssetId {
  AssetId sibling(String name) {
    final segments = pathSegments..last = name;
    return AssetId(package, url.joinAll(segments));
  }
}
