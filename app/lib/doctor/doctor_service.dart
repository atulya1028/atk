import 'dart:async';
import 'dart:convert';
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

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> _sendSafe(Future<http.Response> Function() action) async {
    try {
      return await action();
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Request timed out. Please check your network connection.');
      }
      throw Exception('Network connection error: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  static Future<Map<String, dynamic>> sendOtp(String email) async {
    final uri = Uri.parse('$baseUrl/auth/send-otp');
    final response = await _sendSafe(() => http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim().toLowerCase(), 'role': 'doctor'}),
        )
        .timeout(const Duration(seconds: 60)));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['error'] as String? ?? 'Failed to send doctor verification code.',
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

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['error'] as String? ?? 'Invalid or expired verification code.',
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

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['error'] as String? ?? 'Failed to load doctor profile.',
      );
    }

    return (decoded['doctor'] as Map<String, dynamic>?) ?? <String, dynamic>{};
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

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['error'] as String? ?? 'Failed to update doctor profile.',
      );
    }

    return (decoded['doctor'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> getPatients() async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/doctor/patients');
    final response = await _sendSafe(() => http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 30)));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['error'] as String? ?? 'Failed to load patients list.',
      );
    }

    return decoded;
  }
}
