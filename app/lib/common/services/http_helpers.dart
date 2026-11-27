import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Shared HTTP, JSON parsing, and host-policy helpers used by app API services.
class AtkHttpHelpers {
  AtkHttpHelpers._();

  /// Returns `true` for local/development hosts or known Novtek AWS endpoints
  /// where plain HTTP is permitted by app policy.
  static bool isLocalOrAllowedHttpHost(Uri? uri) {
    final host = uri?.host.toLowerCase() ?? '';
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        host.isEmpty ||
        RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(host) ||
        host.contains('nip.io') ||
        host.contains('duckdns.org') ||
        host.contains('novtek');
  }

  /// Safely decodes a JSON object response body, returning `{}` on empty or
  /// non-object payloads.
  static Map<String, dynamic> safeJsonDecode(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Executes an HTTP call and normalizes timeouts/network errors into readable
  /// [Exception] messages.
  static Future<http.Response> sendSafe(
    Future<http.Response> Function() action,
  ) async {
    try {
      return await action();
    } on TimeoutException {
      throw Exception(
        'Request timed out. Please check your network connection.',
      );
    } catch (e) {
      if (e is Exception) {
        throw Exception(e.toString().replaceFirst('Exception: ', ''));
      }
      throw Exception('Network connection error: $e');
    }
  }

  /// Builds JSON headers with an optional Bearer token.
  static Future<Map<String, String>> authHeaders(
    Future<String?> Function() readToken,
  ) async {
    final token = await readToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Decodes the response body and throws an [Exception] with the server's
  /// `error` field (or [fallbackError]) when the status code is not 2xx.
  static Map<String, dynamic> decodeOrThrow(
    http.Response response, {
    required String fallbackError,
  }) {
    final decoded = safeJsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] as String? ?? fallbackError);
    }
    return decoded;
  }
}
