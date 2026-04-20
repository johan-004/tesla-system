import 'package:flutter/foundation.dart';

class AppConfig {
  static const _apiBaseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiBaseUrlFromEnv.trim().isNotEmpty) {
      return _apiBaseUrlFromEnv.trim();
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }

    return 'http://127.0.0.1:8000/api/v1';
  }
}
