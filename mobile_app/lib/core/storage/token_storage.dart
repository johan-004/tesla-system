import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _tokenTypeKey = 'auth_token_type';
  static const _userNameKey = 'auth_user_name';
  static const _userRoleKey = 'auth_user_role';
  static const _userPermissionsKey = 'auth_user_permissions';

  Future<void> save({
    required String token,
    required String tokenType,
    required String userName,
    required String userRole,
    List<String> userPermissions = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_tokenTypeKey, tokenType);
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_userRoleKey, userRole);
    await prefs.setString(_userPermissionsKey, jsonEncode(userPermissions));
  }

  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> readTokenType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenTypeKey);
  }

  Future<String?> readUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenTypeKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userPermissionsKey);
  }
}
