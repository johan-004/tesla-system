import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode(debugLabel: 'login-email');
  final _passwordFocusNode = FocusNode(debugLabel: 'login-password');
  bool _obscureLoginPassword = true;
  bool _loading = false;
  bool _checkingRecoveryEmail = false;
  bool _recoveryEmailExists = false;
  bool _checkingInitialAdminStatus = true;
  bool _canRegisterInitialAdmin = false;
  String? _error;
  Timer? _recoveryEmailDebounce;
  static final RegExp _emailPattern =
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  bool get _canUseRecovery =>
      !_loading &&
      !_checkingRecoveryEmail &&
      _emailPattern.hasMatch(_emailController.text.trim()) &&
      _recoveryEmailExists;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _loadInitialAdminStatus();
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _recoveryEmailDebounce?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (!_loading) {
                _submit();
              }
              return null;
            },
          ),
        },
        child: Scaffold(
          body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF7F4EA), Color(0xFFDDEEE8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Card(
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipOval(
                                child: SizedBox(
                                  width: 142,
                                  height: 142,
                                  child: Image.asset(
                                    'assets/images/icono_de_login.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text('Ingreso',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Correo',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: _obscureLoginPassword,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Clave',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscureLoginPassword =
                                            !_obscureLoginPassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscureLoginPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    tooltip: _obscureLoginPassword
                                        ? 'Mostrar contraseña'
                                        : 'Ocultar contraseña',
                                  ),
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Text(_error!,
                                    style: const TextStyle(color: Colors.red)),
                              ],
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _loading ? null : _submit,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Text('Entrar'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_checkingRecoveryEmail)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 6),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              TextButton(
                                onPressed:
                                    _canUseRecovery ? _openRecoveryOptionsDialog : null,
                                child: const Text('Olvidé mi contraseña'),
                              ),
                              if (_checkingInitialAdminStatus)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              else
                                TextButton.icon(
                                  onPressed: _canRegisterInitialAdmin
                                      ? _openInitialAdminRegisterDialog
                                      : null,
                                  icon: const Icon(Icons.verified_user_outlined),
                                  label: Text(
                                    _canRegisterInitialAdmin
                                        ? 'Registrarse (Admin)'
                                        : 'Registro admin cerrado',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
      ),
    );
  }

  void _onEmailChanged() {
    final email = _emailController.text.trim();
    final hasValidFormat = _emailPattern.hasMatch(email);

    _recoveryEmailDebounce?.cancel();

    if (!hasValidFormat) {
      if (_checkingRecoveryEmail || _recoveryEmailExists) {
        setState(() {
          _checkingRecoveryEmail = false;
          _recoveryEmailExists = false;
        });
      }
      return;
    }

    if (!_checkingRecoveryEmail) {
      setState(() => _checkingRecoveryEmail = true);
    }

    _recoveryEmailDebounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final exists = await widget.authController.recoveryEmailExists(
          email: email,
        );
        if (!mounted) return;
        setState(() {
          _recoveryEmailExists = exists;
          _checkingRecoveryEmail = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _recoveryEmailExists = false;
          _checkingRecoveryEmail = false;
        });
      }
    });
  }

  Future<void> _loadInitialAdminStatus() async {
    try {
      final canRegister = await widget.authController.canRegisterInitialAdmin();
      if (!mounted) return;
      setState(() {
        _canRegisterInitialAdmin = canRegister;
        _checkingInitialAdminStatus = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checkingInitialAdminStatus = false);
    }
  }

  Future<void> _openInitialAdminRegisterDialog() async {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    var requestingCode = false;
    var registering = false;
    var codeValidated = false;
    String? dialogError;
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: !requestingCode && !registering,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> requestCode() async {
              setStateDialog(() {
                requestingCode = true;
                dialogError = null;
              });
              try {
                await widget.authController.requestInitialAdminRegistrationCode();
              } on ApiException catch (error) {
                setStateDialog(() => dialogError = error.message);
              } catch (_) {
                setStateDialog(() {
                  dialogError = 'No fue posible solicitar el código.';
                });
              } finally {
                setStateDialog(() => requestingCode = false);
              }
            }

            Future<void> validateCode() async {
              final code = codeController.text.trim();
              if (code.length != 6) {
                setStateDialog(() {
                  dialogError = 'Ingresa el código de 6 dígitos.';
                });
                return;
              }

              setStateDialog(() {
                registering = true;
                dialogError = null;
              });

              try {
                await widget.authController.verifyInitialAdminRegistrationCode(
                  code: code,
                );
                setStateDialog(() {
                  codeValidated = true;
                  dialogError = null;
                });
              } on ApiException catch (error) {
                setStateDialog(() => dialogError = error.message);
              } catch (_) {
                setStateDialog(() {
                  dialogError = 'No fue posible validar el código.';
                });
              } finally {
                setStateDialog(() => registering = false);
              }
            }

            Future<void> submitAdminRegistration() async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              final phone = phoneController.text.trim();
              final password = passwordController.text;
              final confirmPassword = confirmPasswordController.text;

              if (name.isEmpty ||
                  email.isEmpty ||
                  phone.isEmpty ||
                  password.isEmpty ||
                  confirmPassword.isEmpty) {
                setStateDialog(() {
                  dialogError = 'Completa todos los campos.';
                });
                return;
              }

              if (!_emailPattern.hasMatch(email)) {
                setStateDialog(() {
                  dialogError = 'Ingresa un correo válido.';
                });
                return;
              }

              if (password.length < 8) {
                setStateDialog(() {
                  dialogError = 'La contraseña debe tener al menos 8 caracteres.';
                });
                return;
              }

              if (password != confirmPassword) {
                setStateDialog(() {
                  dialogError = 'Las contraseñas no coinciden.';
                });
                return;
              }

              setStateDialog(() {
                registering = true;
                dialogError = null;
              });

              try {
                await widget.authController.registerInitialAdmin(
                  code: codeController.text.trim(),
                  name: name,
                  email: email,
                  phone: phone,
                  password: password,
                  passwordConfirmation: confirmPassword,
                );
                if (!mounted) return;
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                await _loadInitialAdminStatus();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Administrador creado correctamente. Ahora inicia sesión.',
                    ),
                  ),
                );
              } on ApiException catch (error) {
                setStateDialog(() => dialogError = error.message);
              } catch (_) {
                setStateDialog(() {
                  dialogError = 'No fue posible crear el administrador.';
                });
              } finally {
                setStateDialog(() => registering = false);
              }
            }

            return AlertDialog(
              title: const Text('Registro único de administradora'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paso 1: solicita el código. Llegará al correo de aprobación configurado.',
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: requestingCode || registering ? null : requestCode,
                          icon: requestingCode
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.mark_email_unread_outlined),
                          label: const Text('Enviar código de verificación'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Código de verificación',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: requestingCode || registering ? null : validateCode,
                          icon: const Icon(Icons.verified_outlined),
                          label: Text(
                            codeValidated ? 'Código validado' : 'Validar código',
                          ),
                        ),
                      ),
                      if (codeValidated) ...[
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        const Text(
                          'Paso 2: datos de la cuenta administradora',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo existente',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () => setStateDialog(
                                () => obscurePassword = !obscurePassword,
                              ),
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () => setStateDialog(
                                () => obscureConfirmPassword = !obscureConfirmPassword,
                              ),
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (dialogError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          dialogError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: requestingCode || registering
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: !codeValidated || registering ? null : submitAdminRegistration,
                  child: registering
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crear cuenta admin'),
                ),
              ],
            );
          },
        );
      },
    );

    codeController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Ingresa correo y clave.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.authController.login(
        email: email,
        password: password,
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = 'No fue posible iniciar sesión: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openRecoveryOptionsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Recuperar contraseña'),
          content: const Text(
            'Elige cómo deseas recuperar tu acceso.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Future<void>.delayed(Duration.zero);
                if (!mounted) return;
                _openRecoveryDialog();
              },
              icon: const Icon(Icons.alternate_email_rounded),
              label: const Text('Por correo'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Future<void>.delayed(Duration.zero);
                if (!mounted) return;
                _openSmsRecoveryDialog();
              },
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Por SMS'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openRecoveryDialog() async {
    final rootContext = context;
    final emailController = TextEditingController();
    final codeController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String? localError;
    bool requesting = false;
    bool verifyingCode = false;
    bool resetting = false;
    bool codeRequested = false;
    bool codeVerified = false;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setStateDialog) {
            void safeSetStateDialog(VoidCallback fn) {
              if (!dialogContext.mounted) {
                return;
              }
              setStateDialog(fn);
            }

            Future<void> requestCode() async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                safeSetStateDialog(
                    () => localError = 'Ingresa el correo de la cuenta.');
                return;
              }

              safeSetStateDialog(() {
                requesting = true;
                localError = null;
              });

              try {
                await widget.authController
                    .requestPasswordRecovery(email: email);
                if (!mounted ||
                    !dialogContext.mounted ||
                    !rootContext.mounted) {
                  return;
                }
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Te enviamos un código de recuperación por correo.',
                    ),
                  ),
                );
                safeSetStateDialog(() {
                  codeRequested = true;
                  codeVerified = false;
                });
              } on ApiException catch (error) {
                safeSetStateDialog(() => localError = error.message);
              } catch (error) {
                safeSetStateDialog(() =>
                    localError = 'No fue posible iniciar recuperación: $error');
              } finally {
                safeSetStateDialog(() => requesting = false);
              }
            }

            Future<void> resetByEmail() async {
              final email = emailController.text.trim();
              final code = codeController.text.trim();
              final password = newPasswordController.text;
              final confirmation = confirmPasswordController.text;

              if (email.isEmpty ||
                  code.isEmpty ||
                  password.isEmpty ||
                  confirmation.isEmpty) {
                safeSetStateDialog(() =>
                    localError = 'Completa todos los campos para restablecer.');
                return;
              }

              if (password != confirmation) {
                safeSetStateDialog(
                    () => localError = 'La confirmación no coincide.');
                return;
              }

              safeSetStateDialog(() {
                resetting = true;
                localError = null;
              });

              try {
                await widget.authController.resetPasswordByEmail(
                  email: email,
                  code: code,
                  newPassword: password,
                  newPasswordConfirmation: confirmation,
                );

                if (!mounted ||
                    !dialogContext.mounted ||
                    !rootContext.mounted) {
                  return;
                }

                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Contraseña restablecida por correo. Ya puedes ingresar.'),
                  ),
                );
              } on ApiException catch (error) {
                safeSetStateDialog(() => localError = error.message);
              } catch (error) {
                safeSetStateDialog(() =>
                    localError = 'No fue posible restablecer por correo: $error');
              } finally {
                safeSetStateDialog(() => resetting = false);
              }
            }

            Future<void> verifyCodeByEmail() async {
              final email = emailController.text.trim();
              final code = codeController.text.trim();

              if (email.isEmpty || code.isEmpty) {
                safeSetStateDialog(
                  () => localError = 'Ingresa correo y código de 6 dígitos.',
                );
                return;
              }

              safeSetStateDialog(() {
                verifyingCode = true;
                localError = null;
              });

              try {
                await widget.authController.verifyPasswordRecoveryCode(
                  email: email,
                  code: code,
                );
                safeSetStateDialog(() {
                  codeVerified = true;
                });
              } on ApiException catch (error) {
                safeSetStateDialog(() => localError = error.message);
              } catch (error) {
                safeSetStateDialog(
                  () => localError = 'No fue posible validar el código: $error',
                );
              } finally {
                safeSetStateDialog(() => verifyingCode = false);
              }
            }

            return AlertDialog(
              title: const Text('Recuperación por correo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '1) Pide código por correo. 2) Ingresa código y nueva contraseña.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: requesting || resetting ? null : requestCode,
                        child: requesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Enviar código por correo'),
                      ),
                    ),
                    if (codeRequested) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Código de 6 dígitos',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: requesting || verifyingCode || resetting
                              ? null
                              : verifyCodeByEmail,
                          child: verifyingCode
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Validar código'),
                        ),
                      ),
                    ],
                    if (codeVerified) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: newPasswordController,
                        obscureText: obscureNewPassword,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              safeSetStateDialog(() {
                                obscureNewPassword = !obscureNewPassword;
                              });
                            },
                            icon: Icon(
                              obscureNewPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            tooltip: obscureNewPassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              safeSetStateDialog(() {
                                obscureConfirmPassword =
                                    !obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            tooltip: obscureConfirmPassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                          ),
                        ),
                      ),
                    ] else if (!codeRequested) ...[
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Primero solicita el código para habilitar el cambio de contraseña.',
                        ),
                      ),
                    ],
                    if (localError != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          localError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: requesting || verifyingCode || resetting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cerrar'),
                ),
                FilledButton(
                  onPressed: requesting ||
                          verifyingCode ||
                          resetting ||
                          !codeVerified
                      ? null
                      : resetByEmail,
                  child: resetting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Restablecer'),
                ),
              ],
            );
          },
        );
      },
    );

  }

  Future<void> _openSmsRecoveryDialog() async {
    final rootContext = context;
    final phoneController = TextEditingController();
    final codeController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String? localError;
    bool requesting = false;
    bool verifyingCode = false;
    bool resetting = false;
    bool codeRequested = false;
    bool codeVerified = false;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setStateDialog) {
            void safeSetStateDialog(VoidCallback fn) {
              if (!dialogContext.mounted) {
                return;
              }
              setStateDialog(fn);
            }

            Future<void> requestCode() async {
              final phone = phoneController.text.trim();
              if (phone.isEmpty) {
                safeSetStateDialog(() => localError = 'Ingresa tu teléfono.');
                return;
              }

              safeSetStateDialog(() {
                requesting = true;
                localError = null;
              });

              try {
                await widget.authController.requestPasswordRecoveryBySms(
                  phone: phone,
                );
                if (!mounted ||
                    !dialogContext.mounted ||
                    !rootContext.mounted) {
                  return;
                }
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Si el número existe, enviamos un código por SMS.',
                    ),
                  ),
                );
                safeSetStateDialog(() {
                  codeRequested = true;
                  codeVerified = false;
                });
              } on ApiException catch (error) {
                safeSetStateDialog(() => localError = error.message);
              } catch (error) {
                safeSetStateDialog(() =>
                    localError = 'No fue posible enviar el código: $error');
              } finally {
                safeSetStateDialog(() => requesting = false);
              }
            }

            Future<void> resetBySms() async {
              final phone = phoneController.text.trim();
              final code = codeController.text.trim();
              final password = newPasswordController.text;
              final confirmation = confirmPasswordController.text;

              if (phone.isEmpty ||
                  code.isEmpty ||
                  password.isEmpty ||
                  confirmation.isEmpty) {
                safeSetStateDialog(() =>
                    localError = 'Completa todos los campos para restablecer.');
                return;
              }

              if (password != confirmation) {
                safeSetStateDialog(
                    () => localError = 'La confirmación no coincide.');
                return;
              }

              safeSetStateDialog(() {
                resetting = true;
                localError = null;
              });

              try {
                await widget.authController.resetPasswordBySms(
                  phone: phone,
                  code: code,
                  newPassword: password,
                  newPasswordConfirmation: confirmation,
                );

                if (!mounted ||
                    !dialogContext.mounted ||
                    !rootContext.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Contraseña restablecida por SMS. Ya puedes ingresar.'),
                  ),
                );
              } on ApiException catch (error) {
                safeSetStateDialog(() => localError = error.message);
              } catch (error) {
                safeSetStateDialog(() =>
                    localError = 'No fue posible restablecer por SMS: $error');
              } finally {
                safeSetStateDialog(() => resetting = false);
              }
            }

            Future<void> verifyCodeBySms() async {
              final phone = phoneController.text.trim();
              final code = codeController.text.trim();

              if (phone.isEmpty || code.isEmpty) {
                safeSetStateDialog(
                  () => localError = 'Ingresa teléfono y código de 6 dígitos.',
                );
                return;
              }

              safeSetStateDialog(() {
                verifyingCode = true;
                localError = null;
              });

              try {
                await widget.authController.verifyPasswordRecoveryCodeBySms(
                  phone: phone,
                  code: code,
                );
                safeSetStateDialog(() {
                  codeVerified = true;
                });
              } on ApiException catch (error) {
                safeSetStateDialog(() => localError = error.message);
              } catch (error) {
                safeSetStateDialog(
                  () => localError = 'No fue posible validar el código: $error',
                );
              } finally {
                safeSetStateDialog(() => verifyingCode = false);
              }
            }

            return AlertDialog(
              title: const Text('Recuperación por SMS'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '1) Pide código por SMS. 2) Ingresa código y nueva contraseña.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono (+57...)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: requesting || resetting ? null : requestCode,
                        child: requesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Enviar código SMS'),
                      ),
                    ),
                    if (codeRequested) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Código de 6 dígitos',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: requesting || verifyingCode || resetting
                              ? null
                              : verifyCodeBySms,
                          child: verifyingCode
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Validar código'),
                        ),
                      ),
                    ],
                    if (codeVerified) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: newPasswordController,
                        obscureText: obscureNewPassword,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              safeSetStateDialog(() {
                                obscureNewPassword = !obscureNewPassword;
                              });
                            },
                            icon: Icon(
                              obscureNewPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            tooltip: obscureNewPassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              safeSetStateDialog(() {
                                obscureConfirmPassword =
                                    !obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            tooltip: obscureConfirmPassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                          ),
                        ),
                      ),
                    ] else if (!codeRequested) ...[
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Primero solicita el código SMS para habilitar el cambio de contraseña.',
                        ),
                      ),
                    ],
                    if (localError != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          localError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: requesting || verifyingCode || resetting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cerrar'),
                ),
                FilledButton(
                  onPressed: requesting ||
                          verifyingCode ||
                          resetting ||
                          !codeVerified
                      ? null
                      : resetBySms,
                  child: resetting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Restablecer'),
                ),
              ],
            );
          },
        );
      },
    );

  }
}
