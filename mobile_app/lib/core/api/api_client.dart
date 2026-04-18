import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiClient {
  ApiClient({this.token, this.tokenType});

  final String? token;
  final String? tokenType;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': '${tokenType ?? 'Bearer'} $token',
      };

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    try {
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _decode(response, uri);
    } on SocketException catch (error) {
      throw ApiException(
        'No se pudo conectar con ${uri.host}:${uri.port}. Verifica que Laravel esté activo y accesible desde esta app. ${error.message}',
        0,
      );
    } on TimeoutException {
      throw ApiException(
        'La solicitud a $uri tardó demasiado. Revisa la conectividad entre Flutter y Laravel.',
        0,
      );
    } on FormatException {
      throw ApiException(
        'La API respondió con un formato inválido en $uri.',
        0,
      );
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    try {
      final response = await http
          .get(
            uri,
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      return _decode(response, uri);
    } on SocketException catch (error) {
      throw ApiException(
        'No se pudo conectar con ${uri.host}:${uri.port}. Verifica que Laravel esté activo y accesible desde esta app. ${error.message}',
        0,
      );
    } on TimeoutException {
      throw ApiException(
        'La solicitud a $uri tardó demasiado. Revisa la conectividad entre Flutter y Laravel.',
        0,
      );
    } on FormatException {
      throw ApiException(
        'La API respondió con un formato inválido en $uri.',
        0,
      );
    }
  }

  Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    try {
      final response = await http
          .put(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _decode(response, uri);
    } on SocketException catch (error) {
      throw ApiException(
        'No se pudo conectar con ${uri.host}:${uri.port}. Verifica que Laravel esté activo y accesible desde esta app. ${error.message}',
        0,
      );
    } on TimeoutException {
      throw ApiException(
        'La solicitud a $uri tardó demasiado. Revisa la conectividad entre Flutter y Laravel.',
        0,
      );
    } on FormatException {
      throw ApiException(
        'La API respondió con un formato inválido en $uri.',
        0,
      );
    }
  }

  Future<Map<String, dynamic>> patch(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    try {
      final response = await http
          .patch(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _decode(response, uri);
    } on SocketException catch (error) {
      throw ApiException(
        'No se pudo conectar con ${uri.host}:${uri.port}. Verifica que Laravel esté activo y accesible desde esta app. ${error.message}',
        0,
      );
    } on TimeoutException {
      throw ApiException(
        'La solicitud a $uri tardó demasiado. Revisa la conectividad entre Flutter y Laravel.',
        0,
      );
    } on FormatException {
      throw ApiException(
        'La API respondió con un formato inválido en $uri.',
        0,
      );
    }
  }

  Future<Map<String, dynamic>> postMultipartFile({
    required String path,
    required String fieldName,
    required String filePath,
    Map<String, String> fields = const {},
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Accept': 'application/json',
          if (token != null) 'Authorization': '${tokenType ?? 'Bearer'} $token',
        })
        ..fields.addAll(fields)
        ..files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      final streamed =
          await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamed);
      return _decode(response, uri);
    } on SocketException catch (error) {
      throw ApiException(
        'No se pudo conectar con ${uri.host}:${uri.port}. Verifica que Laravel esté activo y accesible desde esta app. ${error.message}',
        0,
      );
    } on TimeoutException {
      throw ApiException(
        'La solicitud a $uri tardó demasiado. Revisa la conectividad entre Flutter y Laravel.',
        0,
      );
    } on FormatException {
      throw ApiException(
        'La API respondió con un formato inválido en $uri.',
        0,
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response, Uri uri) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      final message = body['message']?.toString().trim();
      throw ApiException(
        _errorMessageForStatus(
          statusCode: response.statusCode,
          message: message,
          uri: uri,
        ),
        response.statusCode,
      );
    }

    return body;
  }

  String _errorMessageForStatus({
    required int statusCode,
    required Uri uri,
    String? message,
  }) {
    if (statusCode == 401) {
      return message?.isNotEmpty == true
          ? '$message Tu sesión de este dispositivo ya no es válida. Inicia sesión de nuevo.'
          : 'Tu sesión de este dispositivo ya no es válida. Inicia sesión de nuevo.';
    }

    if (statusCode == 403) {
      return message?.isNotEmpty == true
          ? '$message No tienes permisos para realizar esta acción.'
          : 'No tienes permisos para realizar esta acción.';
    }

    return message?.isNotEmpty == true
        ? message!
        : 'Error inesperado en la API ($uri).';
  }
}

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;
}
