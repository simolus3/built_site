class EnvironmentOptions {
  final Object? site;
  final String? baseUrl;
  final bool minify;

  late final Uri? baseUri = baseUrl == null ? null : Uri.parse(baseUrl!);

  EnvironmentOptions(this.site, this.baseUrl, this.minify);

  factory EnvironmentOptions.fromJson(Map<String, Object?> json) {
    return EnvironmentOptions(
      json['site'],
      json['base_url'] as String?,
      json['minify'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'site': site,
      'base_url': baseUrl,
      'minify': minify,
    };
  }
}

class SiteConfig extends EnvironmentOptions {
  final String rootPackage;
  final List<String> themes;
  final Map<String, Object?> _environments;

  SiteConfig(Object? site, bool minify, String? baseUrl, this.rootPackage,
      this.themes, this._environments)
      : super(site, baseUrl, minify);

  factory SiteConfig.fromJson(String rootPackage, Map<String, Object?> json) {
    final base = EnvironmentOptions.fromJson(json);
    final themes = (json['themes'] as List?)?.cast<String>() ?? const [];
    final env = json['environments'] as Map?;

    return SiteConfig(base.site, base.minify, base.baseUrl, rootPackage, themes,
        env?.cast() ?? const {});
  }

  List<String> get effectiveThemes => [rootPackage, ...themes, 'built_site'];

  EnvironmentOptions env(String name) {
    final rawOptions = _merge(toJson(), _environments[name]);
    if (rawOptions == null) return this;

    return EnvironmentOptions.fromJson((rawOptions as Map).cast());
  }

  @override
  Map<String, Object?> toJson() {
    return {
      ...super.toJson(),
      'themes': themes,
    };
  }
}

Object? _merge(Object? parent, Object? override) {
  if (override == null) return parent;

  if (parent is Map && override is Map) {
    final keys = parent.keys.cast<Object?>().followedBy(override.keys).toSet();

    return <String, Object?>{
      for (final key in keys) "$key": _merge(parent[key], override[key]),
    };
  }

  return override;
}
