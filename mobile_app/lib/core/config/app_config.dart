import 'package:flutter/foundation.dart';

class AppConfig {
  static const _apiBaseUrlFromEnv = String.fromEnvironment('API_BASE_URL');
  static const _releaseFallbackApiBaseUrl = 'https://api.example.com/api/v1';

  static String get apiBaseUrl {
    final configured = _apiBaseUrlFromEnv.trim().isNotEmpty
        ? _apiBaseUrlFromEnv.trim()
        : _defaultUrlByPlatform();

    if (!kDebugMode && configured.toLowerCase().startsWith('http://')) {
      throw StateError(
        'API_BASE_URL insegura en release. Usa HTTPS para proteger credenciales y tokens.',
      );
    }

    return configured;
  }

  static String _defaultUrlByPlatform() {
    if (!kDebugMode) {
      return _releaseFallbackApiBaseUrl;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }

    return 'http://127.0.0.1:8000/api/v1';
  }
}
