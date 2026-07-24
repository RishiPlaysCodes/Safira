import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for app settings persistence.
/// Backend URL is validated and HTTPS is enforced for non-local URLs.
class SettingsRepository {
  static const _parentPhoneKey = 'parent_phone';
  static const _backendUrlKey = 'backend_url';
  static const _destinationKey = 'destination';

  Future<String> loadParentPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_parentPhoneKey) ?? '';
  }

  Future<String> loadBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_backendUrlKey) ?? '';
    return _enforceHttps(url);
  }

  Future<String> loadDestination() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_destinationKey) ?? '';
  }

  Future<void> save({
    required String parentPhone,
    required String backendUrl,
    required String destination,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_parentPhoneKey, parentPhone);
    await prefs.setString(_backendUrlKey, _enforceHttps(backendUrl));
    await prefs.setString(_destinationKey, destination);
  }

  /// Enforce HTTPS on all non-local backend URLs.
  String _enforceHttps(String url) {
    if (url.isEmpty) return url;

    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    // Allow HTTP for local development only
    if (kDebugMode) {
      final isLocal = uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '10.0.2.2' ||
          uri.host.startsWith('192.168.');
      if (isLocal) return url;
    }

    if (uri.scheme == 'http') {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }
}
