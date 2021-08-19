// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'front_matter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Document _$DocumentFromJson(Map<String, dynamic> json) {
  return $checkedNew('Document', json, () {
    final val = Document(
      $checkedConvert(
          json,
          'frontMatter',
          (v) => v == null
              ? null
              : FrontMatter.fromJson(v as Map<String, dynamic>?)),
      $checkedConvert(json, 'contentStartOffset', (v) => v as int),
    );
    return val;
  });
}

Map<String, dynamic> _$DocumentToJson(Document instance) => <String, dynamic>{
      'frontMatter': instance.frontMatter,
      'contentStartOffset': instance.contentStartOffset,
    };

FrontMatter _$FrontMatterFromJson(Map json) {
  return $checkedNew('FrontMatter', json, () {
    final val = FrontMatter(
      path: $checkedConvert(json, 'path', (v) => v as String?),
      aliases: $checkedConvert(json, 'aliases',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()) ??
          [],
      data: $checkedConvert(
          json,
          'data',
          (v) => (v as Map?)?.map(
                (k, e) => MapEntry(k as String, e),
              )),
      template: $checkedConvert(json, 'template', (v) => v as String?),
    );
    return val;
  });
}

Map<String, dynamic> _$FrontMatterToJson(FrontMatter instance) =>
    <String, dynamic>{
      'path': instance.path,
      'aliases': instance.aliases,
      'template': instance.template,
      'data': instance.data,
    };
