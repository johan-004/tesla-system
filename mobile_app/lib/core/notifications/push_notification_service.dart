import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Ignorar para no romper la recepción en background.
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  bool _available = false;
  String? _currentToken;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (kIsWeb) {
      return;
    }

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _currentToken = await messaging.getToken();
      _available = _currentToken != null && _currentToken!.trim().isNotEmpty;

      messaging.onTokenRefresh.listen((token) {
        _currentToken = token.trim().isEmpty ? null : token.trim();
      });
    } catch (error) {
      debugPrint('Push no disponible en este build: $error');
      _available = false;
      _currentToken = null;
    }
  }

  Future<void> syncToken({
    required String authToken,
    required String tokenType,
  }) async {
    if (!_available || authToken.trim().isEmpty) {
      return;
    }

    final token = (_currentToken ?? '').trim();
    if (token.isEmpty) {
      return;
    }

    try {
      await ApiClient(token: authToken, tokenType: tokenType).post(
        '/auth/push-token',
        {
          'token': token,
          'platform': _platformName,
          'device_name': _deviceName,
        },
      );
    } catch (error) {
      debugPrint('No fue posible sincronizar token push: $error');
    }
  }

  Future<void> detachToken({
    required String authToken,
    required String tokenType,
  }) async {
    if (!_available || authToken.trim().isEmpty) {
      return;
    }

    final token = (_currentToken ?? '').trim();
    if (token.isEmpty) {
      return;
    }

    try {
      await ApiClient(token: authToken, tokenType: tokenType).delete(
        '/auth/push-token',
        {'token': token},
      );
    } catch (_) {
      // No bloquear logout por token push.
    }
  }

  String get _platformName {
    if (kIsWeb) {
      return 'web';
    }

    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    return 'unknown';
  }

  String get _deviceName {
    if (kIsWeb) {
      return 'flutter-web';
    }
    if (Platform.isAndroid) {
      return 'flutter-android';
    }
    if (Platform.isIOS) {
      return 'flutter-ios';
    }
    return 'flutter-app';
  }
}
