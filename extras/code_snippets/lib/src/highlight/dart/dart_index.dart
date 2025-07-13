import 'dart:convert';

import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' show url;

import 'export_canonicalization.dart';

final class ElementIdentifier {
  final Uri definedSource;
  final int offsetInSource;

  ElementIdentifier(this.definedSource, this.offsetInSource);

  static ElementIdentifier? fromElement(Element2 element) {
    final uri = element.library2?.uri;
    final offset = element.firstFragment.nameOffset2;
    if (uri == null || offset == null) return null;

    return ElementIdentifier(uri, offset);
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

final class PublicLibrary {
  final AssetId id;
  final List<ElementIdentifier> exportedElements;
  final String dartDocName;
  final String dirName;
  final bool isDeprecated;

  PublicLibrary._(this.id, this.exportedElements, this.dirName,
      this.dartDocName, this.isDeprecated);

  factory PublicLibrary.fromJson(Map<String, Object?> json) {
    return PublicLibrary._(
      AssetId.deserialize(json['id'] as List),
      [
        for (final entry in json['exportedElements'] as List)
          ElementIdentifier.fromJson(entry),
      ],
      json['dirName'] as String,
      json['dartDocName'] as String,
      json['isDeprecated'] as bool,
    );
  }

  factory PublicLibrary(AssetId id, LibraryElement2 element) {
    final exportedHere = <ElementIdentifier>[];

    for (final export in element.exportNamespace.definedNames2.values) {
      final id = ElementIdentifier.fromElement(export);
      if (id != null) {
        exportedHere.add(id);
      }
    }

    // Also mark the library element itself as exported
    final libraryId = ElementIdentifier.fromElement(element);
    if (libraryId != null) {
      exportedHere.add(libraryId);
    }

    return PublicLibrary._(
      id,
      exportedHere,
      _computeDirName(element, id),
      _computeDartDocName(element, id),
      element.metadata2.hasDeprecated,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id.serialize(),
      'exportedElements': [
        for (final element in exportedElements) element.toJson(),
      ],
      'dartDocName': dartDocName,
      'dirName': dirName,
      'isDeprecated': isDeprecated,
    };
  }

  static String _computeDirName(LibraryElement2 element, AssetId id) {
    // Ported over from https://github.com/dart-lang/dartdoc/blob/e1295863b11c54680bf178ec9c2662a33b0e24be/lib/src/model/library.dart#L164
    final name = element.name3;
    String nameFromPath;
    if (name == null || name.isEmpty) {
      nameFromPath = url.relative('/${id.path}', from: '/lib');
      if (nameFromPath.endsWith('.dart')) {
        const dartExtensionLength = '.dart'.length;
        nameFromPath = nameFromPath.substring(
            0, nameFromPath.length - dartExtensionLength);
      }
    } else {
      nameFromPath = name;
    }

    // Turn `package:foo/bar/baz` into `package-foo_bar_baz`.
    return nameFromPath.replaceAll(':', '-').replaceAll('/', '_');
  }

  static String _computeDartDocName(LibraryElement2 element, AssetId id) {
    var uri = element.uri;
    if (uri.isScheme('dart')) {
      // There are inconsistencies in library naming + URIs for the Dart
      // SDK libraries; we rationalize them here.
      if (uri.toString().contains('/')) {
        return element.name3!.replaceFirst('dart.', 'dart:');
      }
      return uri.toString();
    } else if (element.name3 != null && element.name3!.isNotEmpty) {
      // An empty name indicates that the library is "implicitly named" with the
      // empty string. That is, it either has no `library` directive, or it has
      // a `library` directive with no name.
      return element.name3!;
    }

    var baseName = url.basename(id.path);
    if (baseName.endsWith('.dart')) {
      const dartExtensionLength = '.dart'.length;
      return baseName.substring(0, baseName.length - dartExtensionLength);
    }
    return baseName;
  }
}

class DartIndex {
  static final _resource = Resource(DartIndex.new);

  static Future<DartIndex> of(BuildStep step) => step.fetchResource(_resource);

  final List<String> _loadedPackages = [];
  final Map<ElementIdentifier, List<PublicLibrary>> _knownImports = {};

  Future<PublicLibrary?> publicLibraryForElement(
      Element2 element, BuildStep buildStep) async {
    Element2? possiblyExported;

    // The element itself might be something nested like a getter in a class.
    // Here, we should check if the surrounding class might be exported.
    if (element is LibraryElement2) {
      possiblyExported = element;
    } else {
      possiblyExported = element.library2;
    }

    if (possiblyExported == null) {
      return null;
    }

    return await _importUriForExportedElement(possiblyExported, buildStep);
  }

  Future<PublicLibrary?> _importUriForExportedElement(
      Element2 element, BuildStep buildStep) async {
    try {
      final id = await buildStep.resolver.assetIdForElement(element);
      await _loadPackage(id.package, buildStep);

      final elementId = ElementIdentifier.fromElement(element);
      final candidates = _knownImports[elementId];
      if (elementId == null || candidates == null || candidates.isEmpty) {
        return null;
      }

      if (candidates case [final candidate]) {
        return candidate;
      }

      return Canonicalization(elementId).canonicalLibraryCandidate(candidates);
    } on UnresolvableAssetException {
      // ignore
      return null;
    }
  }

  Future<void> _loadPackage(String package, BuildStep buildStep) async {
    final index = AssetId(package, 'lib/api.json');
    final indexExists = await buildStep.canRead(index);

    if (!_loadedPackages.contains(package) && indexExists) {
      final decl = json.decode(await buildStep.readAsString(index)) as List;

      for (final entry in decl) {
        final library = PublicLibrary.fromJson(entry as Map<String, Object?>);
        for (final exportedElement in library.exportedElements) {
          _knownImports.putIfAbsent(exportedElement, () => []).add(library);
        }
      }

      _loadedPackages.add(package);
    }
  }
}
