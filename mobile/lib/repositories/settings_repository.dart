import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _parentPhoneKey = 'parent_phone';
  static const _backendUrlKey = 'backend_url';
  static const _usernameKey = 'username';
  static const _destinationKey = 'destination';
  static const _autoOnKey = 'auto_on_enabled';

  Future<String> loadParentPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_parentPhoneKey) ?? '';
  }

  Future<String> loadBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backendUrlKey) ?? 'http://127.0.0.1:8000';
  }

  Future<String> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey) ?? '';
  }

  Future<String> loadDestination() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_destinationKey) ?? '';
  }

  Future<bool> loadAutoOn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoOnKey) ?? true;
  }

  Future<void> save({
    required String parentPhone,
    required String backendUrl,
    required String username,
    required String destination,
    bool autoOn = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_parentPhoneKey, parentPhone);
    await prefs.setString(_backendUrlKey, backendUrl);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_destinationKey, destination);
    await prefs.setBool(_autoOnKey, autoOn);
  }
}
