import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Set with `--dart-define=ATK_API_URL=https://your-api.example.com`.
/// Android emulator users should use `http://10.0.2.2:8080`.
class ApiClient {
  ApiClient._();

  static const _configuredBaseUrl = String.fromEnvironment('ATK_API_URL');
  static String get baseUrl => _baseUrl;
  static String get _baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static const _storage = FlutterSecureStorage();

  static void _requireSecureTransport() {
    if (kReleaseMode && Uri.parse(_baseUrl).scheme != 'https') {
      throw const ApiException('The production API must use HTTPS.');
    }
  }

  static Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'POST',
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    _requireSecureTransport();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      final token = await _storage.read(key: 'atk_access_token');
      if (token == null) throw const ApiException('Please sign in again.');
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$_baseUrl$path');
    Future<http.Response> send() => (switch (method) {
      'GET' => http.get(uri, headers: headers),
      'PUT' => http.put(uri, headers: headers, body: jsonEncode(body)),
      // A bodyless POST must be sent with no body. Encoding a nullable body
      // here sends the JSON literal `null`, which Express's strict JSON parser
      // rejects before routes such as survey completion can run.
      _ => http.post(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
    }).timeout(const Duration(seconds: 30));
    var response = await send();
    if (authenticated &&
        response.statusCode == 401 &&
        path != '/auth/refresh') {
      final refreshed = await _refreshSession();
      if (refreshed) {
        headers['Authorization'] =
            'Bearer ${await _storage.read(key: 'atk_access_token')}';
        response = await send();
      }
    }
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        decoded['error'] as String? ?? 'Request failed. Please try again.',
      );
    }
    return decoded;
  }

  static Future<void> sendOtp(String email) async {
    await _request('/auth/send-otp', body: {'email': email, 'role': 'user'});
  }

  static Future<bool> verifyOtp(String email, String otp) async {
    final result = await _request(
      '/auth/verify-otp',
      body: {'email': email, 'otp': otp, 'role': 'user'},
    );
    await _storage.write(
      key: 'atk_access_token',
      value: result['accessToken'] as String,
    );
    await _storage.write(
      key: 'atk_refresh_token',
      value: result['refreshToken'] as String,
    );
    return result['isProfileComplete'] as bool? ?? false;
  }

  static Future<bool> _refreshSession() async {
    final token = await _storage.read(key: 'atk_refresh_token');
    if (token == null) return false;
    try {
      final result = await _request(
        '/auth/refresh',
        body: {'refreshToken': token},
      );
      await _storage.write(
        key: 'atk_access_token',
        value: result['accessToken'] as String,
      );
      await _storage.write(
        key: 'atk_refresh_token',
        value: result['refreshToken'] as String,
      );
      return true;
    } on ApiException {
      await _storage.delete(key: 'atk_access_token');
      await _storage.delete(key: 'atk_refresh_token');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getAccountProfile() =>
      _request('/user/profile', method: 'GET', authenticated: true);

  static Future<Map<String, dynamic>?> getProfile() async =>
      (await getAccountProfile())['profile'] as Map<String, dynamic>?;

  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    await _request(
      '/user/profile',
      method: 'PUT',
      body: profile,
      authenticated: true,
    );
  }

  static Future<Map<String, dynamic>> surveyStatus() =>
      _request('/v1/surveys/status', method: 'GET', authenticated: true);

  static Future<Map<String, dynamic>> startSurvey(String type) =>
      _request('/v1/surveys/start', body: {'type': type}, authenticated: true);

  static Future<void> saveSurveyAnswers(
    String id,
    Map<String, int> answers,
  ) async {
    await _request(
      '/v1/surveys/$id/answers',
      method: 'PUT',
      body: {'answers': answers},
      authenticated: true,
    );
  }

  static Future<int> completeSurvey(String id) async {
    final result = await _request(
      '/v1/surveys/$id/complete',
      authenticated: true,
    );
    return result['score'] as int? ?? 0;
  }

  static Future<void> saveWellbeingCheckIn(
    String topic,
    Map<String, String> responses,
  ) async {
    await _request(
      '/v1/wellbeing/$topic',
      method: 'PUT',
      body: {'responses': responses},
      authenticated: true,
    );
  }

  static Future<void> logout() async {
    try {
      // Refresh first so logout can revoke the current refresh token even if
      // the access token expired while the app was open.
      if (await _refreshSession()) {
        final refreshToken = await _storage.read(key: 'atk_refresh_token');
        await _request(
          '/auth/logout',
          body: {'refreshToken': refreshToken},
          authenticated: true,
        );
      }
    } catch (_) {
      // Always clear the local session, even if the API is unavailable.
    } finally {
      await _storage.delete(key: 'atk_access_token');
      await _storage.delete(key: 'atk_refresh_token');
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
