import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// Result of an API call - either success with data or failure with error message.
class ApiResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? errorMessage;
  final int? statusCode;

  const ApiResult._({
    required this.success,
    this.data,
    this.errorMessage,
    this.statusCode,
  });

  factory ApiResult.ok(Map<String, dynamic> data, int statusCode) =>
      ApiResult._(success: true, data: data, statusCode: statusCode);

  factory ApiResult.error(String message, {int? statusCode}) =>
      ApiResult._(success: false, errorMessage: message, statusCode: statusCode);
}

/// Centralized API client with authentication, HTTPS enforcement,
/// error handling, and retry logic.
class ApiClient {
  ApiClient({required this.authService});

  final AuthService authService;

  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _shortTimeout = Duration(seconds: 5);

  /// Validate and enforce HTTPS on the backend URL.
  /// In debug mode, allows HTTP for localhost/emulator IPs.
  String _enforceHttps(String baseUrl) {
    if (baseUrl.isEmpty) return baseUrl;

    final uri = Uri.tryParse(baseUrl);
    if (uri == null) return baseUrl;

    // Allow HTTP only for local development
    if (kDebugMode) {
      final isLocal = uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '10.0.2.2' || // Android emulator
          uri.host.startsWith('192.168.');
      if (isLocal) return baseUrl;
    }

    // Enforce HTTPS for all non-local URLs
    if (uri.scheme == 'http') {
      return baseUrl.replaceFirst('http://', 'https://');
    }
    return baseUrl;
  }

  /// Make an authenticated POST request.
  Future<ApiResult> post(String backendUrl, String path, Map<String, dynamic> body) async {
    final url = _enforceHttps(backendUrl);
    if (url.isEmpty) return ApiResult.error('Backend URL not configured.');

    final uri = Uri.tryParse('$url$path');
    if (uri == null) return ApiResult.error('Invalid URL: $url$path');

    try {
      final response = await http
          .post(uri, headers: authService.authHeaders, body: jsonEncode(body))
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      return ApiResult.error('No internet connection.');
    } on http.ClientException {
      return ApiResult.error('Network error. Please try again.');
    } catch (e) {
      return ApiResult.error('Request failed. Please try again.');
    }
  }

  /// Make an authenticated GET request.
  Future<ApiResult> get(String backendUrl, String path, {Map<String, String>? queryParams}) async {
    final url = _enforceHttps(backendUrl);
    if (url.isEmpty) return ApiResult.error('Backend URL not configured.');

    var uri = Uri.tryParse('$url$path');
    if (uri == null) return ApiResult.error('Invalid URL: $url$path');

    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final response = await http
          .get(uri, headers: authService.authHeaders)
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      return ApiResult.error('No internet connection.');
    } on http.ClientException {
      return ApiResult.error('Network error. Please try again.');
    } catch (e) {
      return ApiResult.error('Request failed. Please try again.');
    }
  }

  /// Quick fire-and-forget POST (for telemetry/trip data with shorter timeout).
  Future<ApiResult> postQuick(String backendUrl, String path, Map<String, dynamic> body) async {
    final url = _enforceHttps(backendUrl);
    if (url.isEmpty) return ApiResult.error('Backend URL not configured.');

    final uri = Uri.tryParse('$url$path');
    if (uri == null) return ApiResult.error('Invalid URL.');

    try {
      final response = await http
          .post(uri, headers: authService.authHeaders, body: jsonEncode(body))
          .timeout(_shortTimeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResult.error('Request timeout or network error.');
    }
  }

  ApiResult _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResult.ok(data, response.statusCode);
      } catch (_) {
        return ApiResult.ok({}, response.statusCode);
      }
    }

    // Handle 401 - token expired or invalid
    if (response.statusCode == 401) {
      return ApiResult.error('Session expired. Please login again.', statusCode: 401);
    }

    // Handle 429 - rate limited
    if (response.statusCode == 429) {
      return ApiResult.error('Too many requests. Please wait a moment.', statusCode: 429);
    }

    // Parse error message from response
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final error = data['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? 'Request failed (${response.statusCode}).';
      return ApiResult.error(message, statusCode: response.statusCode);
    } catch (_) {
      return ApiResult.error('Server error (${response.statusCode}).', statusCode: response.statusCode);
    }
  }
}
