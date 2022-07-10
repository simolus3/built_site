import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:meta/meta.dart';

@sealed
class ElementIdentifier {
  final Uri definedSource;
  final int offsetInSource;

  ElementIdentifier(this.definedSource, this.offsetInSource);

  static ElementIdentifier? fromElement(Element element) {
    final declaration = element.declaration;
    final source = declaration?.source;
    if (declaration == null || source == null) return null;

    return ElementIdentifier(source.uri, declaration.nameOffset);
  }

  factory ElementIdentifier.fromJson(Map<String, Object?> json) {
    return ElementIdentifier(
      Uri.parse(json['source'] as String),
      json['offset'] as int,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'source': definedSource.toString(),
      'offset': offsetInSource,
    };
  }

  @override
  int get hashCode =>
      Object.hash(ElementIdentifier, definedSource, offsetInSource);

  @override
  bool operator ==(Object other) {
    return other is ElementIdentifier &&
        other.definedSource == definedSource &&
        other.offsetInSource == offsetInSource;
  }
}

class DartIndex {
  static final _resource = Resource(DartIndex.new);

  static Future<DartIndex> of(BuildStep step) => step.fetchResource(_resource);

  final List<String> _loadedPackages = [];
  final Map<ElementIdentifier, AssetId> _knownImports = {};

  /// Map from any top-level (parent is a library) element to the proper asset
  /// id to import for this element.
  ///
  /// For elements in `src/`, this attempts to find a public `lib/` import which
  /// exports said element.
  final Map<ElementIdentifier, AssetId> topLevelMembersToProperImport = {};

  Future<AssetId?> findImportForElement(
      Element element, BuildStep buildStep) async {
    // First, find a top-level ancestor of the element
    final topLevelAncestor = element.thisOrAncestorMatchingNullable(
        (el) => el.enclosingElement is CompilationUnitElement);

    if (topLevelAncestor == null) return null;

    try {
      final id = await buildStep.resolver.assetIdForElement(topLevelAncestor);
      await _loadPackage(id.package, buildStep);

      return _knownImports[ElementIdentifier.fromElement(topLevelAncestor)];
    } on UnresolvableAssetException {
      // ignore
      return null;
    }
  }

  Future<void> _loadPackage(String package, BuildStep buildStep) async {
    final index = AssetId(package, 'lib/api.json');
    final indexExists = await buildStep.canRead(index);

    if (!_loadedPackages.contains(package) && indexExists) {
      final decl = json.decode(await buildStep.readAsString(index))
          as Map<String, Object?>;

      decl.forEach((library, elements) {
        final import = AssetId(package, library);

        final parsedElements = (elements as List)
            .cast<Map<String, Object?>>()
            .map(ElementIdentifier.fromJson);

        for (final element in parsedElements) {
          _knownImports[element] = import;
        }
      });

      _loadedPackages.add(package);
    }
  }
}

extension on Element {
  E? thisOrAncestorMatchingNullable<E extends Element>(
    bool Function(Element) predicate,
  ) {
    Element? element = this;
    while (element != null && !predicate(element)) {
      element = element.enclosingElement;
    }
    return element as E?;
  }
}
