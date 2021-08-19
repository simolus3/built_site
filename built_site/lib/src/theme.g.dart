// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoundThemeResources _$FoundThemeResourcesFromJson(Map<String, dynamic> json) {
  return $checkedNew('FoundThemeResources', json, () {
    final val = FoundThemeResources(
      $checkedConvert(json, 'static',
          (v) => (v as List<dynamic>).map((e) => e as String).toList()),
      $checkedConvert(json, 'i18n',
          (v) => (v as List<dynamic>).map((e) => e as String).toList()),
      $checkedConvert(
          json,
          'config',
          (v) => v == null
              ? null
              : ThemeConfig.fromJson(v as Map<String, dynamic>)),
    );
    return val;
  });
}

Map<String, dynamic> _$FoundThemeResourcesToJson(
        FoundThemeResources instance) =>
    <String, dynamic>{
      'static': instance.static,
      'i18n': instance.i18n,
      'config': instance.config,
    };

ThemeConfig _$ThemeConfigFromJson(Map json) {
  return $checkedNew('ThemeConfig', json, () {
    final val = ThemeConfig(
      $checkedConvert(
          json, 'contributes', (v) => Map<String, String>.from(v as Map)),
    );
    return val;
  });
}

Map<String, dynamic> _$ThemeConfigToJson(ThemeConfig instance) =>
    <String, dynamic>{
      'contributes': instance.contributes,
    };
