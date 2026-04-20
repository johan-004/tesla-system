import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../api/api_client.dart';
import '../storage/token_storage.dart';

class AuthController extends ChangeNotifier with WidgetsBindingObserver {
  AuthController(this._storage);

  static const inactivityTimeout = Duration(minutes: 15);

  final TokenStorage _storage;

  String? token;
  String? tokenType;
  String? userName;
  String? userEmail;
  String? userPhone;
  String? userRole;
  List<String> userPermissions = const [];
  String? defaultFirmaPath;
  String? defaultFirmaNombre;
  String? defaultFirmaCargo;
  String? defaultFirmaEmpresa;
  Timer? _inactivityTimer;
  DateTime? _lastActivityAt;
  bool _isLoggingOut = false;

  bool get isAuthenticated => token != null && token!.isNotEmpty;
  bool get isAdministrador => _normalizeRole(userRole) == 'administrador';
  bool get canCreateProductos => _hasPermission('productos.create');
  bool get canEditProductos => _hasPermission('productos.update');
  bool get canToggleProductos => _hasPermission('productos.toggle');
  bool get canManageProductos =>
      canCreateProductos || canEditProductos || canToggleProductos;
  bool get canCreateServicios => _hasPermission('servicios.create');
  bool get canEditServicios => _hasPermission('servicios.update');
  bool get canToggleServicios => _hasPermission('servicios.toggle');
  bool get canViewCotizaciones => _hasPermission('cotizaciones.view');
  bool get canCreateCotizaciones => _hasPermission('cotizaciones.create');
  bool get canEditCotizaciones => _hasPermission('cotizaciones.update');
  bool get canViewFacturacion => _hasPermission('facturacion.view');
  bool get canCreateFacturacion => _hasPermission('facturacion.create');
  bool get canEditFacturacion => _hasPermission('facturacion.update');

  Future<void> restoreSession() async {
    final storedToken = await _storage.readToken();
    final storedTokenType = await _storage.readTokenType() ?? 'Bearer';
    final storedUserName = await _storage.readUserName();
    final storedUserEmail = await _storage.readUserEmail();
    final storedUserPhone = await _storage.readUserPhone();
    final storedUserRole = await _storage.readUserRole();
    final storedUserPermissions = await _storage.readUserPermissions();

    if (storedToken == null || storedToken.trim().isEmpty) {
      await _clearLocalSession(notify: false);
      notifyListeners();
      return;
    }

    token = storedToken.trim();
    tokenType = storedTokenType;
    userName = storedUserName;
    userEmail = storedUserEmail;
    userPhone = storedUserPhone;
    userRole = _normalizeRole(storedUserRole);
    userPermissions = storedUserPermissions;

    try {
      final response = await ApiClient(
        token: token,
        tokenType: tokenType,
      ).get('/auth/me');
      final rawUser = response['data'];

      if (rawUser is! Map<String, dynamic>) {
        throw ApiException(
          'La sesión almacenada no devolvió un usuario válido.',
          0,
        );
      }

      _applyUserPayload(rawUser);

      await _storage.save(
        token: token!,
        tokenType: tokenType!,
        userName: userName ?? '',
        userEmail: userEmail ?? '',
        userPhone: userPhone ?? '',
        userRole: userRole ?? '',
        userPermissions: userPermissions,
      );
      _startInactivityTracking();
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _clearLocalSession(notify: false);
      } else {
        rethrow;
      }
    } catch (_) {
      await _clearLocalSession(notify: false);
    }

    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final api = ApiClient();
    final response = await api.post('/auth/login', {
      'email': email,
      'password': password,
      'device_name': _deviceName,
    });

    final rawUser = response['user'];
    if (rawUser is! Map<String, dynamic>) {
      throw ApiException(
        'La respuesta de login no incluye un objeto "user" válido.',
        0,
      );
    }

    final parsedToken = response['token']?.toString().trim() ?? '';
    final parsedTokenType =
        response['token_type']?.toString().trim() ?? 'Bearer';

    if (parsedToken.isEmpty) {
      throw ApiException(
        'La respuesta de login no incluye un token válido.',
        0,
      );
    }

    final user = rawUser;
    token = parsedToken;
    tokenType = parsedTokenType;
    _applyUserPayload(user);

    await _storage.save(
      token: token!,
      tokenType: tokenType!,
      userName: userName ?? '',
      userEmail: userEmail ?? '',
      userPhone: userPhone ?? '',
      userRole: userRole ?? '',
      userPermissions: userPermissions,
    );

    _startInactivityTracking();
    notifyListeners();
  }

  void registerActivity() {
    if (!isAuthenticated || _isLoggingOut) {
      return;
    }

    _restartInactivityTimer();
  }

  Future<void> logout({bool autoTriggered = false}) async {
    if (_isLoggingOut) {
      return;
    }

    _isLoggingOut = true;
    _stopInactivityTracking();

    if (token != null) {
      try {
        await ApiClient(token: token, tokenType: tokenType)
            .post('/auth/logout', {});
      } catch (_) {
        // Se limpia almacenamiento local aunque el backend no responda.
      }
    }

    await _clearLocalSession();
    _isLoggingOut = false;
  }

  Future<void> updateEmail({
    required String email,
    required String currentPassword,
  }) async {
    if (!isAuthenticated) {
      throw ApiException(
          'No hay una sesión activa para actualizar el perfil.', 401);
    }

    final response = await ApiClient(token: token, tokenType: tokenType).patch(
      '/auth/email',
      {
        'email': email.trim(),
        'current_password': currentPassword,
      },
    );

    final rawUser = response['data'];
    if (rawUser is! Map<String, dynamic>) {
      throw ApiException('La API no devolvió el usuario actualizado.', 0);
    }

    _applyUserPayload(rawUser);
    await _storage.save(
      token: token!,
      tokenType: tokenType!,
      userName: userName ?? '',
      userEmail: userEmail ?? '',
      userPhone: userPhone ?? '',
      userRole: userRole ?? '',
      userPermissions: userPermissions,
    );
    notifyListeners();
  }

  Future<void> updatePhone({
    required String phone,
    required String currentPassword,
  }) async {
    if (!isAuthenticated) {
      throw ApiException(
          'No hay una sesión activa para actualizar el perfil.', 401);
    }

    final response = await ApiClient(token: token, tokenType: tokenType).patch(
      '/auth/phone',
      {
        'phone': phone.trim(),
        'current_password': currentPassword,
      },
    );

    final rawUser = response['data'];
    if (rawUser is! Map<String, dynamic>) {
      throw ApiException('La API no devolvió el usuario actualizado.', 0);
    }

    _applyUserPayload(rawUser);
    await _storage.save(
      token: token!,
      tokenType: tokenType!,
      userName: userName ?? '',
      userEmail: userEmail ?? '',
      userPhone: userPhone ?? '',
      userRole: userRole ?? '',
      userPermissions: userPermissions,
    );
    notifyListeners();
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    if (!isAuthenticated) {
      throw ApiException(
          'No hay una sesión activa para actualizar la contraseña.', 401);
    }

    await ApiClient(token: token, tokenType: tokenType).patch(
      '/auth/password',
      {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPasswordConfirmation,
      },
    );
  }

  Future<void> requestPasswordRecovery({
    required String email,
  }) async {
    await ApiClient().post('/auth/forgot-password', {
      'email': email.trim(),
    });
  }

  Future<void> requestPasswordRecoveryBySms({
    required String phone,
  }) async {
    await ApiClient().post('/auth/forgot-password-sms', {
      'phone': phone.trim(),
    });
  }

  Future<void> resetPasswordBySms({
    required String phone,
    required String code,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    await ApiClient().post('/auth/reset-password-sms', {
      'phone': phone.trim(),
      'code': code.trim(),
      'password': newPassword,
      'password_confirmation': newPasswordConfirmation,
    });
  }

  Future<void> _clearLocalSession({bool notify = true}) async {
    _stopInactivityTracking();
    token = null;
    tokenType = null;
    userName = null;
    userEmail = null;
    userPhone = null;
    userRole = null;
    userPermissions = const [];
    defaultFirmaPath = null;
    defaultFirmaNombre = null;
    defaultFirmaCargo = null;
    defaultFirmaEmpresa = null;
    await _storage.clear();
    if (notify) {
      notifyListeners();
    }
  }

  bool hasPermission(String permission) {
    if (userPermissions.contains(permission)) {
      return true;
    }

    return _defaultPermissionsForRole(_normalizeRole(userRole))
        .contains(permission);
  }

  bool _hasPermission(String permission) => hasPermission(permission);

  List<String> _parsePermissions(dynamic rawPermissions, String? role) {
    if (rawPermissions is List) {
      return rawPermissions.map((item) => item.toString()).toList();
    }

    return _defaultPermissionsForRole(role);
  }

  List<String> _defaultPermissionsForRole(String? role) {
    switch (role) {
      case 'administrador':
        return const [
          'productos.view',
          'productos.create',
          'productos.update',
          'productos.toggle',
          'productos.delete',
          'servicios.view',
          'servicios.create',
          'servicios.update',
          'servicios.toggle',
          'servicios.delete',
          'clientes.view',
          'clientes.create',
          'clientes.update',
          'clientes.delete',
          'categorias_servicio.view',
          'categorias_servicio.create',
          'categorias_servicio.update',
          'categorias_servicio.delete',
          'cotizaciones.view',
          'cotizaciones.create',
          'cotizaciones.update',
          'cotizaciones.delete',
          'facturacion.view',
          'facturacion.create',
          'facturacion.update',
          'facturacion.delete',
          'usuarios.view',
          'usuarios.create',
          'usuarios.update',
          'usuarios.delete',
        ];
      case 'vendedor':
        return const [
          'productos.view',
          'servicios.view',
          'clientes.view',
          'categorias_servicio.view',
          'cotizaciones.view',
          'cotizaciones.create',
          'cotizaciones.update',
          'facturacion.view',
          'facturacion.create',
          'facturacion.update',
        ];
      default:
        return const [];
    }
  }

  String? _normalizeRole(String? role) {
    switch (role) {
      case 'administradora':
        return 'administrador';
      case 'vendedora':
        return 'vendedor';
      default:
        return role;
    }
  }

  void _applyUserPayload(Map<String, dynamic> rawUser) {
    userName = rawUser['name']?.toString() ?? userName ?? '';
    userEmail = rawUser['email']?.toString() ?? userEmail ?? '';
    userPhone = rawUser['phone']?.toString() ?? userPhone ?? '';
    userRole = _normalizeRole(rawUser['role']?.toString()) ?? userRole ?? '';
    userPermissions = _parsePermissions(rawUser['permissions'], userRole);
    defaultFirmaPath = rawUser['firma_path_default']?.toString();
    defaultFirmaNombre = rawUser['firma_nombre_default']?.toString();
    defaultFirmaCargo = rawUser['firma_cargo_default']?.toString();
    defaultFirmaEmpresa = rawUser['firma_empresa_default']?.toString();
  }

  void _startInactivityTracking() {
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);
    _restartInactivityTimer();
  }

  void _restartInactivityTimer() {
    _lastActivityAt = DateTime.now();
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, _handleInactivityTimeout);
  }

  void _stopInactivityTracking() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _lastActivityAt = null;
  }

  Future<void> _handleInactivityTimeout() async {
    if (!isAuthenticated || _isLoggingOut) {
      return;
    }

    await logout(autoTriggered: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isAuthenticated || _isLoggingOut) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      final lastActivityAt = _lastActivityAt;
      if (lastActivityAt == null) {
        _restartInactivityTimer();
        return;
      }

      final inactiveFor = DateTime.now().difference(lastActivityAt);
      if (inactiveFor >= inactivityTimeout) {
        unawaited(logout(autoTriggered: true));
        return;
      }

      _restartInactivityTimer();
    }
  }

  String get _deviceName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'flutter-android';
      case TargetPlatform.macOS:
        return 'flutter-macos';
      default:
        return 'flutter-app';
    }
  }

  @override
  void dispose() {
    _stopInactivityTracking();
    super.dispose();
  }
}
