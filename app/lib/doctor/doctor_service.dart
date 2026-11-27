import 'dart:async';
import 'dart:convert';
import 'package:atk/common/services/http_helpers.dart';
import 'package:http/http.dart' as http;
import '../patient/services/api_client.dart';
import '../patient/services/app_storage.dart';

class DoctorService {
  DoctorService._();

  static String get baseUrl => ApiClient.baseUrl;

  static Future<String?> getToken() async {
    return AppStorage.read(key: 'atk_access_token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> signOut() async {
    await AppStorage.delete(key: 'atk_access_token');
    await AppStorage.delete(key: 'atk_refresh_token');
    await AppStorage.delete(key: 'atk_doctor_email');
    await AppStorage.delete(key: 'atk_doctor_name');
  }

  static Future<Map<String, String>> _authHeaders() =>
      AtkHttpHelpers.authHeaders(getToken);

  static Future<http.Response> _sendSafe(
    Future<http.Response> Function() action,
  ) => AtkHttpHelpers.sendSafe(action);

  static Map<String, dynamic> _safeJsonDecode(String body) =>
      AtkHttpHelpers.safeJsonDecode(body);

  static Future<Map<String, dynamic>> sendOtp(String email) async {
    final uri = Uri.parse('$baseUrl/auth/send-otp');
    final response = await _sendSafe(() => http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim().toLowerCase(), 'role': 'doctor'}),
        )
        .timeout(const Duration(seconds: 60)));

    final decoded = _safeJsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['error'] as String? ?? 'Failed to send doctor verification code (${response.statusCode}).',
      );
    }

    return decoded;
  }

  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final uri = Uri.parse('$baseUrl/auth/verify-otp');
    final response = await _sendSafe(() => http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'otp': otp.trim(),
            'role': 'doctor',
          }),
        )
        .timeout(const Duration(seconds: 60)));

    final decoded = _safeJsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['error'] as String? ?? 'Invalid or expired verification code (${response.statusCode}).',
      );
    }

    final accessToken = decoded['accessToken'] as String?;
    final refreshToken = decoded['refreshToken'] as String?;
    if (accessToken != null) {
      await AppStorage.write(key: 'atk_access_token', value: accessToken);
    }
    if (refreshToken != null) {
      await AppStorage.write(key: 'atk_refresh_token', value: refreshToken);
    }
    await AppStorage.write(key: 'atk_doctor_email', value: email.trim().toLowerCase());

    return decoded;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/doctor/profile');
    final response = await _sendSafe(() => http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 25)));

    final decoded = _safeJsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['error'] as String? ?? 'Failed to load doctor profile (${response.statusCode}).',
      );
    }

    final doc = decoded['doctor'];
    if (doc is Map<String, dynamic>) return doc;
    if (doc is Map) return Map<String, dynamic>.from(doc);
    return <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? specialization,
    String? servicePincode,
    String? phoneNumber,
  }) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/doctor/profile');
    final response = await _sendSafe(() => http
        .put(
          uri,
          headers: headers,
          body: jsonEncode({
            if (name != null) 'name': name.trim(),
            if (specialization != null) 'specialization': specialization.trim(),
            if (servicePincode != null) 'servicePincode': servicePincode.trim(),
            if (phoneNumber != null) 'phoneNumber': phoneNumber.trim(),
          }),
        )
        .timeout(const Duration(seconds: 25)));

    final decoded = _safeJsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['error'] as String? ?? 'Failed to update doctor profile (${response.statusCode}).',
      );
    }

    final doc = decoded['doctor'];
    if (doc is Map<String, dynamic>) return doc;
    if (doc is Map) return Map<String, dynamic>.from(doc);
    return <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> getPatients() async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/doctor/patients');
    final response = await _sendSafe(() => http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 30)));

    final decoded = _safeJsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['error'] as String? ?? 'Failed to load patients list (${response.statusCode}).',
      );
    }

    return decoded;
  }
}
