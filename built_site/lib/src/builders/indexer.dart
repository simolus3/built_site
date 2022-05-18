import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' show url;

class Indexer extends Builder {
  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$package$': ['lib/site_index.json']
    };
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final pages =
        await buildStep.findAssets(Glob('pages/**.page_meta')).toSet();

    final root = _SectionTreeNode(null);
    pages
        .where((id) => url.basenameWithoutExtension(id.path) == 'index')
        .forEach(root.insert);

    final sections = <_SectionTreeNode>[];
    root._writeSections(sections);

    final data = {
      'sections': [
        for (final section in sections)
          {
            'home': section.page.toString(),
            'parent': section.firstParentWithPage?.page?.toString(),
          }
      ],
      'pages': [
        for (final page in pages) page.toString(),
      ],
    };

    final outputId = AssetId(buildStep.inputId.package, 'lib/site_index.json');
    await buildStep.writeAsString(outputId, json.encode(data));
  }
}

class _SectionTreeNode {
  final _SectionTreeNode? parent;
  final Map<String, _SectionTreeNode> children = {};

  // Sections without an index page don't exist, but we need them to build an
  // accurate tree.
  AssetId? page;

  // ignore: unused_element, https://github.com/dart-lang/sdk/issues/49007
  _SectionTreeNode(this.parent, [this.page]);

  void insert(AssetId id) {
    // Removing the file name (index.whatever) since we only care about the
    // directory here.
    final parts = url.split(url.relative(id.path, from: 'pages/'))
      ..removeLast();
    var current = this;

    for (var i = 0; i < parts.length; i++) {
      final segment = parts[i];

      if (current.children.containsKey(segment)) {
        current = current.children[segment]!;
      } else {
        current = current.children[segment] = _SectionTreeNode(current);
      }
    }

    current.page = id;
  }

  _SectionTreeNode? get firstParentWithPage {
    return parent?.page != null ? parent : parent?.firstParentWithPage;
  }

  _SectionTreeNode sectionFor(AssetId id) {
    final parts = url.split(url.relative(id.path, from: 'pages/'))
      ..removeLast();
    var current = this;

    for (final segment in parts) {
      if (current.children.containsKey(segment)) {
        current = current.children[segment]!;
      } else {
        break;
      }
    }

    // Now, find the first parent that isn't virtual
    while (current.page == null) {
      current = current.parent!;
    }

    return current;
  }

  void _writeSections(List<_SectionTreeNode> target) {
    if (page != null) {
      target.add(this);
    }

    for (final child in children.values) {
      child._writeSections(target);
    }
  }
}
