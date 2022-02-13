import 'package:source_span/source_span.dart';

class HighlightRegion {
  final RegionType type;
  final FileSpan source;

  final Uri? viewableDefinition;

  HighlightRegion(
    this.type,
    this.source, {
    this.viewableDefinition,
  });
}

// https://highlightjs.readthedocs.io/en/latest/css-classes-reference.html
enum RegionType {
  keyword,
  builtIn,
  type,
  literal,
  number,
  operator,
  punctuation,
  property,
  regexp,
  string,
  escapeCharacter,
  subst,
  symbol,
  variable,
  languageVariable,
  constantVariable,
  title,
  classTitle,
  inheritedClassTitle,
  functionTitle,
  invokedFunctionTitle,
  params,
  comment,
  doctag,
  meta,
  metaKeyword,
  metaString,
  section,
  tag,
  name,
  attr,
  attribute,
  bullet,
  code,
  emphasis,
  strong,
  formula,
  link,
  quote,
  selectorTag,
  selectorId,
  selectorClass,
  selectorAttr,
  selectorPseudo,
  templateTag,
  templateVariable,
  addition,
  delection,
}
