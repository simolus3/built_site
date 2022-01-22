import 'dart:collection';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:path/path.dart' show url;

import 'front_matter.dart';

class IndexApi {
  final Section root;
  final List<Section> sections;
  final Map<AssetId, IndexedPage> pages;

  IndexApi(this.root, this.sections, this.pages);

  Section sectionOf(AssetId page) {
    return root.sectionFor(page);
  }

  static Future<IndexApi> load(BuildStep step) async {
    final indexId = AssetId(step.inputId.package, 'lib/site_index.json');
    final encoded =
        json.decode(await step.readAsString(indexId)) as Map<String, Object?>;

    final foundSections = <AssetId, Section>{};
    final foundPages = <AssetId, IndexedPage>{};

    final sections = encoded['sections']! as List;
    Section? root;
    for (final section in sections.cast<Map<String, Object?>>()) {
      final index = AssetId.parse(section['home']! as String);
      final parent = section['parent'] as String?;
      final parentSection =
          parent == null ? null : foundSections[AssetId.parse(parent)];

      final newSection = foundSections[index] = Section(parentSection, index);
      parentSection?.children.add(newSection);
      root ??= newSection;
    }

    final pages = encoded['pages']! as List;
    for (final page in pages.cast<String>()) {
      final metaId = AssetId.parse(page);
      final document = Document.fromJson(
          json.decode(await step.readAsString(metaId)) as Map<String, Object?>);

      final section = root!.sectionFor(metaId);
      section.pages.add(metaId);

      foundPages[metaId] =
          IndexedPage(metaId, document, root.sectionFor(metaId));
    }

    return IndexApi(
        root!, UnmodifiableListView(foundSections.values.toList()), foundPages);
  }
}

class Section {
  final Section? parent;
  final AssetId index;
  final List<Section> children = [];
  final List<AssetId> pages = [];

  late final baseDir = url.joinAll(index.pathSegments..removeLast());

  Section(this.parent, this.index);

  bool isChildOf(Section potentialParent) {
    Section? current = this;

    while (current?.parent != null) {
      final next = current = current!.parent;

      if (next == potentialParent) return true;
    }

    return false;
  }

  bool isParentOf(Section potentialChild) {
    return children.contains(potentialChild) ||
        children.any((c) => c.isParentOf(potentialChild));
  }

  Section sectionFor(AssetId page) {
    final directory = url.joinAll(page.pathSegments..removeLast());

    for (final child in children) {
      if (directory.startsWith(child.baseDir)) {
        return child.sectionFor(page);
      }
    }

    return this;
  }

  Map<String, Object?> toJson() {
    return {
      'index': index.uri.toString(),
      'parent': parent?.index.uri.toString(),
      'pages': [
        for (final page in pages) page.uri.toString(),
      ],
      'children': [
        for (final child in children) child.toJson(),
      ],
    };
  }
}

class IndexedPage {
  final AssetId pageMetaId;
  final Document document;
  final Section section;

  IndexedPage(this.pageMetaId, this.document, this.section);
}
