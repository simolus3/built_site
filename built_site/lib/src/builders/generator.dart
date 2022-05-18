import 'dart:convert';

import 'package:build/build.dart';
import 'package:messagepack/messagepack.dart';
import 'package:path/path.dart';
import 'package:synchronized/synchronized.dart';
import 'package:yaml/yaml.dart';

import '../config.dart';
import '../liquid/liquid.dart';
import '../markdown/markdown.dart' as md;
import '../minify_html.dart';
import '../pages/front_matter.dart';
import '../pages/generated_page.dart';
import '../pages/index_api.dart';
import '../version.dart';

final _cache = Resource(() => _BuildCache());

class SiteGenerator extends Builder {
  final String environment;
  final BuilderOptions options;

  SiteGenerator(this.environment, this.options);

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      '.page_meta': ['.generated_page']
    };
  }

  Future<TemplateResolver> _templates(BuildStep step) async {
    final cache = await step.fetchResource(_cache);
    await cache._loadConfig(step);
    return cache._resolver!;
  }

  Future<SiteConfig> _config(BuildStep step) async {
    return (await step.fetchResource(_cache))._loadConfig(step);
  }

  Future<Map<String, Map<String, String>>> _translations(BuildStep step) async {
    return (await step.fetchResource(_cache))._loadTranslations(step);
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final metaId = buildStep.inputId;
    final metaJson = json.decode(await buildStep.readAsString(metaId))
        as Map<String, dynamic>;
    final sourceId = AssetId.parse(metaJson['source'] as String);
    final doc = Document.fromJson(metaJson);

    final config = (await _config(buildStep)).env(environment);

    final templates = await _templates(buildStep);

    final frontMatter = doc.frontMatter;
    // Note that the metadata builder applies a default path if it hasn't
    // been overriden, so we'll always have something here.
    final path = frontMatter!.path!;
    IndexApi? index;

    Future<IndexApi> loadIndex() async {
      return index ??= await IndexApi.load(buildStep);
    }

    Future<String> render(TemplateComponent component,
        {String? content, String? toc, bool outputMarkdown = false}) {
      final evaluator = TemplateEvaluator(buildStep, templates,
          isEmittingMarkdown: outputMarkdown);

      return evaluator.render(
        component,
        variables: <String, Object?>{
          'path': frontMatter.path,
          'aliases': frontMatter.aliases,
          'page': {
            ...?frontMatter.data,
            if (content != null) 'content': content,
            if (toc != null) 'toc': toc,
            'source': sourceId.path,
            'meta_id': metaId.uri.toString(),
            'path': frontMatter.path,
          },
          'site': config.site,
          'environment': environment,
          'base_url': config.baseUrl,
          'built_site': {
            'version': packageVersion,
            'config': options.config,
          },
          'root_section': () async {
            final index = await loadIndex();
            return index.root.toJson();
          },
          'first_section': () async {
            final index = await loadIndex();
            var section = index.sectionOf(sourceId);

            while (section.parent?.parent != null) {
              section = section.parent!;
            }

            return section.toJson();
          },
          'page_section': () async {
            final index = await loadIndex();
            return index.sectionOf(sourceId).toJson();
          },
          'pages': () async {
            final index = await loadIndex();
            return index.pages.keys.map((id) => id.uri);
          },
        },
        additionalFilters: {
          'absUrl': (input, args) {
            final url = config.baseUri!.resolve(input.toString());
            return url.toString();
          },
          'relUrl': (input, args) {
            final parsed = Uri.parse(input.toString());
            if (parsed.isAbsolute || config.baseUri == null) {
              return parsed.toString();
            } else {
              final resolved = config.baseUri!.resolveUri(parsed);
              return resolved.path;
            }
          },
          'i18n': (input, args) async {
            final translations = await _translations(buildStep);

            String? language;
            if (frontMatter.data != null) {
              language = (frontMatter.data)?['language'] as String?;
            }
            language ??= (config.site as Map?)?['language'] as String?;

            final translation = language == null
                ? null
                : translations[language]?[input.toString()];
            if (translation == null) {
              log.warning('Translation $input not found for $language');
              return input.toString();
            }

            return translation;
          },
          'pageUrl': (input, args) async {
            final uri = Uri.parse(input.toString());
            final referenced = AssetId.resolve(uri, from: sourceId);
            final metadataOfReferenced =
                referenced.changeExtension('.page_meta');

            final content = await buildStep.readAsString(metadataOfReferenced);
            final document =
                Document.fromJson(json.decode(content) as Map<String, Object?>);

            final path = document.frontMatter!.path!;
            return config.baseUri!.resolve(path).replace(
                query: uri.query.nullIfEmpty,
                fragment: uri.fragment.nullIfEmpty);
          },
          'pageInfo': (input, args) async {
            final referenced =
                AssetId.resolve(Uri.parse(input.toString()), from: sourceId);
            final metadataOfReferenced =
                referenced.changeExtension('.page_meta');

            final content = await buildStep.readAsString(metadataOfReferenced);
            final document =
                Document.fromJson(json.decode(content) as Map<String, Object?>);

            return document.frontMatter!.toJson();
          },
          'hash': (input, args) async {
            final referenced =
                AssetId.resolve(Uri.parse(input.toString()), from: sourceId);
            final hashId = AssetId(
                referenced.package, '${referenced.path}.built_site_hash');

            final content = await buildStep.trackStage(
                'waiting for $hashId', () => buildStep.readAsString(hashId));
            return json.decode(content);
          },
          'sectionOf': (input, args) async {
            final index = await loadIndex();
            final referenced =
                AssetId.resolve(Uri.parse(input.toString()), from: sourceId);

            return index.sectionOf(referenced).toJson();
          },
          'isAncestor': (input, args) async {
            final index = await loadIndex();
            final self = index.sectionOf(
                AssetId.resolve(Uri.parse(input.toString()), from: sourceId));
            final potentialChild = index.sectionOf(
                AssetId.resolve(Uri.parse(args[0].toString()), from: sourceId));

            return self.isParentOf(potentialChild);
          },
          'isDescendant': (input, args) async {
            final index = await loadIndex();
            final self = index.sectionOf(
                AssetId.resolve(Uri.parse(input.toString()), from: sourceId));
            final potentialParent = index.sectionOf(
                AssetId.resolve(Uri.parse(args[0].toString()), from: sourceId));

            return self.isChildOf(potentialParent);
          },
          'sortedByWeight': (input, args) async {
            final entries = (input as Iterable?)!.toList();
            final weights = <Object?, int>{};

            for (final entry in entries) {
              AssetId pageMeta;
              if (entry is Map) {
                // Probably a section, use index as page
                pageMeta = AssetId.resolve(Uri.parse(entry['index'] as String));
              } else {
                pageMeta = AssetId.resolve(Uri.parse(entry as String));
              }

              final content = await buildStep.readAsString(pageMeta);
              final document = Document.fromJson(
                  json.decode(content) as Map<String, Object?>);

              final weight = document.frontMatter!.data?['weight'];
              if (weight != null) {
                weights[entry] = weight as int;
              }
            }

            entries.sort((Object? a, Object? b) {
              final wa = weights[a];
              final wb = weights[b];

              if (identical(wa, wb)) return 0;

              // Put null weights last
              if (wa == null && wb != null) {
                return 1; // treat a as bigger
              } else if (wb == null && wa != null) {
                return -1; // treat a as smaller
              } else {
                return wa!.compareTo(wb!);
              }
            });
            return entries;
          },
          'readString': (input, args) async {
            final asset =
                AssetId.resolve(Uri.parse(input.toString()), from: sourceId);
            return buildStep.readAsString(asset);
          }
        },
      );
    }

    final fullInput = await buildStep.readAsString(sourceId);
    final parsedContent = TemplateResolver.parseString(fullInput,
        offset: doc.contentStartOffset, url: sourceId.uri);
    final isMarkdown = sourceId.extension == '.md';

    var pageContent = await render(parsedContent, outputMarkdown: isMarkdown);
    var contents = const md.TableOfContents.empty();

    if (isMarkdown) {
      final nodes = md.parse(pageContent);
      pageContent = md.renderToHtml(nodes);
      contents = md.TableOfContents.readFrom(nodes);
    }

    String generated;
    if (frontMatter.template != null) {
      final template =
          await templates.getOrParse(buildStep, frontMatter.template!);

      generated = await render(template,
          content: pageContent, toc: contents.formatToc());
    } else {
      generated = pageContent;
    }

    final extension = url.extension(path);

    // An empty extension implicitly denotes an index.html, which we can minify
    // as well.
    if (config.minify && (extension.isEmpty || extension == '.html')) {
      generated = minifyHtml(generated);
    }

    final packer = Packer();
    GeneratedPage([path, ...frontMatter.aliases], 0, generated)
        .serialize(packer);

    final outputId = metaId.changeExtension('.generated_page');
    await buildStep.writeAsBytes(outputId, packer.takeBytes());
  }
}

class _BuildCache {
  TemplateResolver? _resolver;
  SiteConfig? _configCache;
  Map<String, Map<String, String>>? _i18n;

  final Lock _configAndResolverLock = Lock();
  final Lock _translationsLock = Lock();

  _BuildCache() {
    log.finer('Creating shared build cache for templates');
  }

  Future<SiteConfig> _loadConfig(BuildStep step) async {
    final configId = AssetId(step.inputId.package, 'website.yaml');

    Future<SiteConfig> readCached() async {
      // Still read, we want deterministic builds
      await step.canRead(configId);
      return _configCache!;
    }

    if (_configCache != null) {
      return readCached();
    } else {
      return _configAndResolverLock.synchronized(() async {
        if (_configCache != null) {
          return readCached();
        }

        final dynamic rawConfig = loadYaml(await step.readAsString(configId));
        final cache = _configCache = SiteConfig.fromJson(
            step.inputId.package, (rawConfig as Map).cast<String, dynamic>());
        _resolver = TemplateResolver(cache);
        return cache;
      });
    }
  }

  Future<Map<String, Map<String, String>>> _loadTranslations(
      BuildStep step) async {
    if (_i18n != null) return _i18n!;

    return _translationsLock.synchronized(() async {
      if (_i18n != null) return _i18n!;

      final raw = await step
          .readAsString(AssetId(step.inputId.package, 'lib/i18n_merged.json'));
      final loadedKeys = json.decode(raw) as Map<String, dynamic>;
      return _i18n = {
        for (final entry in loadedKeys.entries)
          entry.key: (entry.value as Map).cast()
      };
    });
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
