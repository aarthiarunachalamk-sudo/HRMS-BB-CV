class ApiConfig {
  /// Override at build time when a different backend is needed:
  /// --dart-define=API_BASE_URL=https://api.example.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://hrms-bitbyte-mobileapp.onrender.com',
  );

  static Uri uri(String path) => Uri.parse('$baseUrl$path');

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
