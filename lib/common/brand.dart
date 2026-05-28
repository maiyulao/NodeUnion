class BrandConfig {
  static const configUrlsRaw = String.fromEnvironment('BRAND_CONFIG_URLS');
  static const configKeyHex = String.fromEnvironment('BRAND_CONFIG_KEY');

  static List<String> get configUrls {
    if (configUrlsRaw.isEmpty) {
      return const [];
    }
    return configUrlsRaw
        .split(',')
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
  }

  static bool get hasRemoteConfig =>
      configUrls.isNotEmpty && configKeyHex.isNotEmpty;

  static bool isValidAirportUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }
}
