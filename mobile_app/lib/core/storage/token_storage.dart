import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _tokenTypeKey = 'auth_token_type';
  static const _userNameKey = 'auth_user_name';
  static const _userEmailKey = 'auth_user_email';
  static const _userPhoneKey = 'auth_user_phone';
  static const _userRoleKey = 'auth_user_role';
  static const _userPermissionsKey = 'auth_user_permissions';
  static const _secureStorage = FlutterSecureStorage();

  Future<void> _secureWrite(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {
      // En algunos escritorios puede no estar disponible el backend seguro.
    }
  }

  Future<String?> _secureRead(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _secureDelete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {
      // Ignorar para no bloquear cierre de sesión.
    }
  }

  Future<void> save({
    required String token,
    required String tokenType,
    required String userName,
    String userEmail = '',
    String userPhone = '',
    required String userRole,
    List<String> userPermissions = const [],
  }) async {
    await _secureWrite(_tokenKey, token);
    await _secureWrite(_tokenTypeKey, tokenType);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_userEmailKey, userEmail);
    await prefs.setString(_userPhoneKey, userPhone);
    await prefs.setString(_userRoleKey, userRole);
    await prefs.setString(_userPermissionsKey, jsonEncode(userPermissions));
  }

  Future<String?> readToken() async {
    final secureToken = await _secureRead(_tokenKey);
    if (secureToken != null && secureToken.trim().isNotEmpty) {
      return secureToken;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_tokenKey);
    if (legacyToken != null && legacyToken.trim().isNotEmpty) {
      await _secureWrite(_tokenKey, legacyToken);
      await prefs.remove(_tokenKey);
      return legacyToken;
    }

    return null;
  }

  Future<String?> readTokenType() async {
    final secureTokenType = await _secureRead(_tokenTypeKey);
    if (secureTokenType != null && secureTokenType.trim().isNotEmpty) {
      return secureTokenType;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyTokenType = prefs.getString(_tokenTypeKey);
    if (legacyTokenType != null && legacyTokenType.trim().isNotEmpty) {
      await _secureWrite(_tokenTypeKey, legacyTokenType);
      await prefs.remove(_tokenTypeKey);
      return legacyTokenType;
    }

    return null;
  }

  Future<String?> readUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<String?> readUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  Future<String?> readUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  Future<String?> readUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  Future<List<String>> readUserPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userPermissionsKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      return decoded.map((item) => item.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> clear() async {
    await _secureDelete(_tokenKey);
    await _secureDelete(_tokenTypeKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userPermissionsKey);
  }
}
