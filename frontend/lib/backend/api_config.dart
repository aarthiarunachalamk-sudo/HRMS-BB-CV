class ApiConfig {
  static const String publicBaseUrl =
      'https://hrms-bitbyte-mobileapp-1.onrender.com/api';

  /// Override at build time when a different backend is needed:
  /// --dart-define=API_BASE_URL=https://api.example.com/api
  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: publicBaseUrl,
  );

  /// Render public services must be called with HTTPS from Android builds.
  /// This also protects older run commands that used the HTTP URL.
  static const String baseUrl =
      configuredBaseUrl == 'http://hrms-bitbyte-mobileapp-1.onrender.com/api' ||
          configuredBaseUrl ==
              'http://hrms-bitbyte-mobileapp-1.onrender.com/api/'
      ? publicBaseUrl
      : configuredBaseUrl;

  static Uri uri(String path) => Uri.parse('$baseUrl$path');

  static Uri publicUri(String path) => Uri.parse('$publicBaseUrl$path');

  static bool get usesPrivateNetworkAddress {
    final host = Uri.tryParse(baseUrl)?.host.toLowerCase() ?? '';
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2' ||
        host.startsWith('10.') ||
        host.startsWith('192.168.') ||
        RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(host);
  }
}
