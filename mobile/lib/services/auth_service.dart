import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Manages authentication state - login, signup, token storage, and logout.
///
/// Tokens are stored in SharedPreferences (use flutter_secure_storage
/// for production apps handling sensitive financial/health data).
class AuthService extends ChangeNotifier {
  AuthService();

  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'auth_username';
  static const _userIdKey = 'auth_user_id';

  String? _token;
  String? _username;
  int? _userId;
  bool _isLoading = false;

  String? get token => _token;
  String? get username => _username;
  int? get userId => _userId;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;

  /// Load saved auth state from local storage.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _username = prefs.getString(_usernameKey);
    _userId = prefs.getInt(_userIdKey);
    notifyListeners();
  }

  /// Login with username and password. Returns error message or null on success.
  Future<String?> login({
    required String backendUrl,
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$backendUrl/api/auth/login/');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveAuth(
          token: data['token'] as String,
          username: (data['user'] as Map<String, dynamic>)['username'] as String,
          userId: (data['user'] as Map<String, dynamic>)['id'] as int,
        );
        return null; // Success
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final error = data['error'] as Map<String, dynamic>?;
        return error?['message'] as String? ?? 'Login failed. Please try again.';
      }
    } catch (e) {
      return 'Network error. Please check your connection and try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new user. Returns error message or null on success.
  Future<String?> signup({
    required String backendUrl,
    required String username,
    required String email,
    required String password,
    required String phoneNumber,
    String vehicleType = 'bike',
    String role = 'driver',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$backendUrl/api/auth/signup/');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
              'phone_number': phoneNumber,
              'vehicle_type': vehicleType,
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveAuth(
          token: data['token'] as String,
          username: (data['user'] as Map<String, dynamic>)['username'] as String,
          userId: (data['user'] as Map<String, dynamic>)['id'] as int,
        );
        return null; // Success
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final error = data['error'] as Map<String, dynamic>?;
        if (error != null && error['details'] != null) {
          // Extract first field error
          final details = error['details'] as Map<String, dynamic>;
          final firstError = details.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
        }
        return error?['message'] as String? ?? 'Signup failed. Please try again.';
      }
    } catch (e) {
      return 'Network error. Please check your connection and try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout - invalidate token on server and clear local state.
  Future<void> logout({required String backendUrl}) async {
    if (_token != null) {
      try {
        final uri = Uri.parse('$backendUrl/api/auth/logout/');
        await http
            .post(uri, headers: _authHeaders())
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Ignore network errors during logout - clear local state regardless
      }
    }
    await _clearAuth();
  }

  /// Get authorization headers for authenticated requests.
  Map<String, String> get authHeaders => _authHeaders();

  Map<String, String> _authHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Token $_token',
    };
  }

  Future<void> _saveAuth({
    required String token,
    required String username,
    required int userId,
  }) async {
    _token = token;
    _username = username;
    _userId = userId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, username);
    await prefs.setInt(_userIdKey, userId);
    notifyListeners();
  }

  Future<void> _clearAuth() async {
    _token = null;
    _username = null;
    _userId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_userIdKey);
    notifyListeners();
  }
}
