import 'dart:convert';
import 'package:http/http.dart' as http;
import '../patient/services/api_client.dart';
import '../patient/services/app_storage.dart';

class AdminService {
  AdminService._();

  static String? _cachedToken;

  static String get baseUrl => ApiClient.baseUrl;

  static Future<String?> getToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) return _cachedToken;
    final token = await AppStorage.read(key: 'atk_admin_token');
    if (token != null && token.isNotEmpty) {
      _cachedToken = token;
      return token;
    }
    return _cachedToken;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> signOut() async {
    _cachedToken = null;
    await AppStorage.delete(key: 'atk_admin_token');
    await AppStorage.delete(key: 'atk_admin_refresh_token');
    await AppStorage.delete(key: 'atk_admin_email');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> sendOtp(String email) async {
    final uri = Uri.parse('$baseUrl/auth/send-otp');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim().toLowerCase(), 'role': 'admin'}),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['error'] as String? ?? 'Failed to send admin verification code.',
      );
    }

    return decoded;
  }

  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final uri = Uri.parse('$baseUrl/auth/verify-otp');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'otp': otp.trim(),
            'role': 'admin',
          }),
        )
        .timeout(const Duration(seconds: 30));

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
      _cachedToken = accessToken;
      await AppStorage.write(key: 'atk_admin_token', value: accessToken);
    }
    if (refreshToken != null) {
      await AppStorage.write(key: 'atk_admin_refresh_token', value: refreshToken);
    }
    await AppStorage.write(key: 'atk_admin_email', value: email.trim().toLowerCase());

    return decoded;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/profile');
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 25));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] as String? ?? 'Failed to load admin profile.');
    }

    return (decoded['admin'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> getStats({String? category}) async {
    final headers = await _authHeaders();
    final q = category != null && category.isNotEmpty ? '?category=$category' : '';
    final uri = Uri.parse('$baseUrl/admin/stats$q');
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] as String? ?? 'Failed to load admin statistics.');
    }

    return decoded;
  }

  static Future<List<dynamic>> getSubmissions({String? stage}) async {
    final headers = await _authHeaders();
    final q = stage != null && stage.isNotEmpty ? '?stage=$stage' : '';
    final uri = Uri.parse('$baseUrl/admin/submissions$q');
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] as String? ?? 'Failed to load submissions.');
    }

    return (decoded['submissions'] as List?) ?? [];
  }

  static Future<List<dynamic>> getLogs() async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/logs');
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] as String? ?? 'Failed to load audit logs.');
    }

    return (decoded['logs'] as List?) ?? [];
  }

  static Future<List<dynamic>> getDoctors() async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/doctors');
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] as String? ?? 'Failed to load doctors list.');
    }

    return (decoded['doctors'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> createDoctor({
    required String email,
    required String fullName,
    String? specialization,
    String? phoneNumber,
    String? servicePincode,
  }) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/doctors');
    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'fullName': fullName.trim(),
            if (specialization != null) 'specialization': specialization.trim(),
            if (phoneNumber != null) 'phoneNumber': phoneNumber.trim(),
            if (servicePincode != null) 'servicePincode': servicePincode.trim(),
          }),
        )
        .timeout(const Duration(seconds: 25));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] as String? ?? 'Failed to create doctor.');
    }

    return decoded;
  }

  static Future<Map<String, dynamic>> updateDoctor(
    String id, {
    String? fullName,
    String? specialization,
    String? phoneNumber,
    String? servicePincode,
  }) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/doctors/$id');
    final response = await http
        .put(
          uri,
          headers: headers,
          body: jsonEncode({
            if (fullName != null) 'fullName': fullName.trim(),
            if (specialization != null) 'specialization': specialization.trim(),
            if (phoneNumber != null) 'phoneNumber': phoneNumber.trim(),
            if (servicePincode != null) 'servicePincode': servicePincode.trim(),
          }),
        )
        .timeout(const Duration(seconds: 25));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] as String? ?? 'Failed to update doctor.');
    }

    return decoded;
  }

  static Future<void> deleteDoctor(String id) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/doctors/$id');
    final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(decoded['error'] as String? ?? 'Failed to delete doctor.');
    }
  }

  static Future<List<dynamic>> getPatients() async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/patients');
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] as String? ?? 'Failed to load patients directory.');
    }

    return (decoded['patients'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> updatePatient(
    String id, {
    String? fullName,
    String? phoneNumber,
    String? ageGroup,
    String? gender,
    String? postcode,
    String? occupation,
    String? maritalStatus,
  }) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/patients/$id');
    final response = await http
        .put(
          uri,
          headers: headers,
          body: jsonEncode({
            if (fullName != null) 'fullName': fullName.trim(),
            if (phoneNumber != null) 'phoneNumber': phoneNumber.trim(),
            if (ageGroup != null) 'ageGroup': ageGroup.trim(),
            if (gender != null) 'gender': gender.trim(),
            if (postcode != null) 'postcode': postcode.trim(),
            if (occupation != null) 'occupation': occupation.trim(),
            if (maritalStatus != null) 'maritalStatus': maritalStatus.trim(),
          }),
        )
        .timeout(const Duration(seconds: 25));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] as String? ?? 'Failed to update patient.');
    }

    return decoded;
  }

  static Future<void> deletePatient(String id) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/patients/$id');
    final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(decoded['error'] as String? ?? 'Failed to delete patient.');
    }
  }

  static Future<Map<String, dynamic>> getAnalytics({String? category}) async {
    final headers = await _authHeaders();
    final q = category != null && category.isNotEmpty && category != 'ALL' ? '?category=$category' : '';
    final uri = Uri.parse('$baseUrl/admin/analytics$q');
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] as String? ?? 'Failed to load analytics.');
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> getDiagnostics() async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/diagnostics');
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 25));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] as String? ?? 'Failed to load diagnostics.');
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> sendTestEmail() async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/diagnostics/test-email');
    final response = await http.post(uri, headers: headers).timeout(const Duration(seconds: 25));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] as String? ?? 'Failed to send test email.');
    }
    return decoded;
  }

  static Future<void> purgeLogs() async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/purge-logs');
    final response = await http.post(uri, headers: headers).timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(decoded['error'] as String? ?? 'Failed to purge logs.');
    }
  }

  static Future<Map<String, dynamic>> getSurveyEditor({String? category}) async {
    final headers = await _authHeaders();
    final q = category != null && category.isNotEmpty ? '?surveyCategory=$category' : '';
    final uri = Uri.parse('$baseUrl/admin/survey-editor$q');
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] as String? ?? 'Failed to load survey editor data.');
    }
    return decoded;
  }

  static Future<void> saveSurveySettings(Map<String, dynamic> settings) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/survey-editor/settings');
    final response = await http
        .post(uri, headers: headers, body: jsonEncode(settings))
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(decoded['error'] as String? ?? 'Failed to save survey settings.');
    }
  }

  static Future<void> saveQuestion(Map<String, dynamic> question) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/survey-editor/question');
    final response = await http
        .post(uri, headers: headers, body: jsonEncode(question))
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(decoded['error'] as String? ?? 'Failed to save question.');
    }
  }

  static Future<void> resetPatientSurvey(String userId) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/reset-patient-survey');
    final response = await http
        .post(uri, headers: headers, body: jsonEncode({'userId': userId}))
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(decoded['error'] as String? ?? 'Failed to reset survey.');
    }
  }

  static Future<void> updateSubmissionTriage(
    String id, {
    String? status,
    String? assignedDoctorId,
    String? clinicalNotes,
  }) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/submissions/$id/triage');
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status;
    if (assignedDoctorId != null) body['assignedDoctorId'] = assignedDoctorId;
    if (clinicalNotes != null) body['clinicalNotes'] = clinicalNotes;
    final response = await http
        .put(uri, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(decoded['error'] as String? ?? 'Failed to update triage.');
    }
  }

  static Future<void> deleteSubmission(String id) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/admin/submissions/$id');
    final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(decoded['error'] as String? ?? 'Failed to delete submission.');
    }
  }
}
