// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? getWebLocalStorage(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

void setWebLocalStorage(String key, String value) {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {}
}

void removeWebLocalStorage(String key) {
  try {
    html.window.localStorage.remove(key);
  } catch (_) {}
}

void clearWebLocalStorage() {
  try {
    html.window.localStorage.removeWhere((key, _) => key.startsWith('atk_'));
  } catch (_) {}
}
