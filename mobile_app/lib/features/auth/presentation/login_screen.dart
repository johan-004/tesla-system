import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController =
      TextEditingController(text: 'admin@tesla-system.test');
  final _passwordController = TextEditingController(text: 'password123');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F4EA), Color(0xFFDDEEE8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              margin: const EdgeInsets.all(24),
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
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Clave',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Entrar'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _openRecoveryOptionsDialog,
                      child: const Text('Olvidé mi contraseña'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _openRecoveryDialog();
              },
              icon: const Icon(Icons.alternate_email_rounded),
              label: const Text('Por correo'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
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
    final emailController = TextEditingController(text: _emailController.text);
    String? localError;
    bool loading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setStateDialog) {
            Future<void> submit() async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                setStateDialog(
                    () => localError = 'Ingresa el correo de la cuenta.');
                return;
              }

              setStateDialog(() {
                loading = true;
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
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Si el correo existe, enviamos instrucciones de recuperación.',
                    ),
                  ),
                );
              } on ApiException catch (error) {
                setStateDialog(() => localError = error.message);
              } catch (error) {
                setStateDialog(() =>
                    localError = 'No fue posible iniciar recuperación: $error');
              } finally {
                setStateDialog(() => loading = false);
              }
            }

            return AlertDialog(
              title: const Text('Recuperar contraseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Te enviaremos instrucciones al correo registrado de la cuenta.',
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
              actions: [
                TextButton(
                  onPressed:
                      loading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
  }

  Future<void> _openSmsRecoveryDialog() async {
    final rootContext = context;
    final phoneController = TextEditingController();
    final codeController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String? localError;
    bool requesting = false;
    bool resetting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setStateDialog) {
            Future<void> requestCode() async {
              final phone = phoneController.text.trim();
              if (phone.isEmpty) {
                setStateDialog(() => localError = 'Ingresa tu teléfono.');
                return;
              }

              setStateDialog(() {
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
              } on ApiException catch (error) {
                setStateDialog(() => localError = error.message);
              } catch (error) {
                setStateDialog(() =>
                    localError = 'No fue posible enviar el código: $error');
              } finally {
                setStateDialog(() => requesting = false);
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
                setStateDialog(() =>
                    localError = 'Completa todos los campos para restablecer.');
                return;
              }

              if (password != confirmation) {
                setStateDialog(
                    () => localError = 'La confirmación no coincide.');
                return;
              }

              setStateDialog(() {
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
                setStateDialog(() => localError = error.message);
              } catch (error) {
                setStateDialog(() =>
                    localError = 'No fue posible restablecer por SMS: $error');
              } finally {
                setStateDialog(() => resetting = false);
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
                    const SizedBox(height: 10),
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Código de 6 dígitos',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nueva contraseña',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        border: OutlineInputBorder(),
                      ),
                    ),
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
                  onPressed: requesting || resetting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cerrar'),
                ),
                FilledButton(
                  onPressed: requesting || resetting ? null : resetBySms,
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

    phoneController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }
}
