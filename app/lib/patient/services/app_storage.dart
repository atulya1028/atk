import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_storage_stub.dart' if (dart.library.html) 'app_storage_web.dart';

class AppStorage {
  AppStorage._();

  static const _secureStorage = FlutterSecureStorage();
  static final Map<String, String> _memory = <String, String>{};

  static Future<void> write({required String key, required String value}) async {
    _memory[key] = value;
    if (kIsWeb) {
      setWebLocalStorage(key, value);
    }
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {
      // Insecure web contexts (HTTP non-localhost) lack window.crypto.subtle.
      // Gracefully fall back to localStorage and memory without throwing.
    }
  }

  static Future<String?> read({required String key}) async {
    if (_memory.containsKey(key) && _memory[key] != null && _memory[key]!.isNotEmpty) {
      return _memory[key];
    }
    if (kIsWeb) {
      final local = getWebLocalStorage(key);
      if (local != null && local.isNotEmpty) {
        _memory[key] = local;
        return local;
      }
    }
    try {
      final secure = await _secureStorage.read(key: key);
      if (secure != null && secure.isNotEmpty) {
        _memory[key] = secure;
        return secure;
      }
    } catch (_) {
      // Ignore insecure context failure
    }
    return _memory[key];
  }

  static Future<void> delete({required String key}) async {
    _memory.remove(key);
    if (kIsWeb) {
      removeWebLocalStorage(key);
    }
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {}
  }

  static Future<void> deleteAll() async {
    _memory.clear();
    if (kIsWeb) {
      clearWebLocalStorage();
    }
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
  }
}
