import 'package:checked_yaml/checked_yaml.dart';
import 'package:json_annotation/json_annotation.dart';

part 'theme.g.dart';

@JsonSerializable()
class FoundThemeResources {
  final List<String> static;
  final List<String> i18n;
  final ThemeConfig? config;

  FoundThemeResources(this.static, this.i18n, this.config);

  factory FoundThemeResources.fromJson(Map<String, Object?> json) {
    return _$FoundThemeResourcesFromJson(json);
  }

  Map<String, Object?> toJson() => _$FoundThemeResourcesToJson(this);
}

@JsonSerializable(anyMap: true)
class ThemeConfig {
  final Map<String, String> contributes;

  ThemeConfig(this.contributes);

  factory ThemeConfig.fromJson(Map<Object, Object?> json) {
    return _$ThemeConfigFromJson(json);
  }

  factory ThemeConfig.fromYaml(String content, Uri uri) {
    return checkedYamlDecode(
      content,
      (map) => _$ThemeConfigFromJson(map!),
      sourceUrl: uri,
    );
  }

  Map<String, Object?> toJson() => _$ThemeConfigToJson(this);
}
