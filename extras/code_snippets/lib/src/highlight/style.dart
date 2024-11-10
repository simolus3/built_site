import 'package:code_snippets/highlight.dart';

abstract class CodeStyleBuilder {
  String? cssClassesFor(HighlightRegion region);
}

final class HighlightJsStyles implements CodeStyleBuilder {
  static const prefix = 'hljs';

  const HighlightJsStyles();

  @override
  String? cssClassesFor(HighlightRegion region) {
    switch (region.type) {
      case RegionType.builtIn:
        return '$prefix-built_in';
      case RegionType.escapeCharacter:
        return '$prefix-char escape_';
      case RegionType.languageVariable:
        return '$prefix-variable language_';
      case RegionType.constantVariable:
        return '$prefix-variable constant_';
      case RegionType.classTitle:
        return '$prefix-title class_';
      case RegionType.inheritedClassTitle:
        return '$prefix-title class_ inherited__';
      case RegionType.functionTitle:
        return '$prefix-title function_';
      case RegionType.invokedFunctionTitle:
        return '$prefix-title function_ invoked__';
      case RegionType.metaKeyword:
        return '$prefix-meta keyword';
      case RegionType.metaString:
        return '$prefix-meta string';
      case RegionType.selectorTag:
        return '$prefix-template-tag';
      case RegionType.selectorId:
        return '$prefix-template-id';
      case RegionType.selectorClass:
        return '$prefix-template-class';
      case RegionType.selectorAttr:
        return '$prefix-template-attr';
      case RegionType.selectorPseudo:
        return '$prefix-template-pseudo';
      case RegionType.templateTag:
        return '$prefix-template-tag';
      case RegionType.templateVariable:
        return '$prefix-template-variable';
      default:
        return '$prefix-${region.type.name}';
    }
  }
}

final class PygmentStyles implements CodeStyleBuilder {
  const PygmentStyles();

  @override
  String? cssClassesFor(HighlightRegion region) {
    return switch (region.type) {
      RegionType.keyword => 'k',
      RegionType.builtIn => 'k',
      RegionType.symbol => 'nl',
      RegionType.number => 'm',
      RegionType.operator => 'o',
      RegionType.comment => 'c',
      RegionType.doctag => 'cs',
      RegionType.punctuation => 'p',
      RegionType.title => 'nc',
      RegionType.classTitle => 'nc',
      RegionType.functionTitle => 'nf',
      RegionType.type => 'nc',
      RegionType.variable => 'nv',
      RegionType.strong => 'gs',
      RegionType.addition => 'gi',
      RegionType.deletion => 'gd',
      _ => null,
    };
  }
}
