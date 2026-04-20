import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authController,
    this.embedded = false,
  });

  final AuthController authController;
  final bool embedded;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final TextEditingController _emailCurrentPasswordController =
      TextEditingController();
  final TextEditingController _phoneCurrentPasswordController =
      TextEditingController();
  final TextEditingController _passwordCurrentController =
      TextEditingController();
  final TextEditingController _passwordNewController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  bool _savingEmail = false;
  bool _savingPhone = false;
  bool _savingPassword = false;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _emailController =
        TextEditingController(text: widget.authController.userEmail ?? '');
    _phoneController =
        TextEditingController(text: widget.authController.userPhone ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _emailCurrentPasswordController.dispose();
    _phoneCurrentPasswordController.dispose();
    _passwordCurrentController.dispose();
    _passwordNewController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildIdentityCard(),
        const SizedBox(height: 14),
        _buildEmailCard(),
        const SizedBox(height: 14),
        _buildPhoneCard(),
        const SizedBox(height: 14),
        _buildPasswordCard(),
      ],
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: body,
    );
  }

  Widget _buildIdentityCard() {
    return _CardShell(
      title: 'Tu cuenta',
      subtitle: 'Información actual del usuario autenticado.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(
              label: 'Nombre', value: widget.authController.userName ?? '-'),
          _InfoLine(
              label: 'Correo', value: widget.authController.userEmail ?? '-'),
          _InfoLine(
              label: 'Telefono', value: widget.authController.userPhone ?? '-'),
          _InfoLine(label: 'Rol', value: widget.authController.userRole ?? '-'),
        ],
      ),
    );
  }

  Widget _buildEmailCard() {
    return _CardShell(
      title: 'Cambiar correo',
      subtitle: 'Para seguridad, confirma tu contraseña actual.',
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Nuevo correo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailCurrentPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña actual',
              border: OutlineInputBorder(),
            ),
          ),
          if (_emailError != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _emailError!,
                style: const TextStyle(color: Color(0xFFB91C1C)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _savingEmail ? null : _submitEmail,
              icon: _savingEmail
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.alternate_email_rounded),
              label: const Text('Actualizar correo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneCard() {
    return _CardShell(
      title: 'Teléfono de recuperación',
      subtitle: 'Número SIM para recuperación por SMS.',
      child: Column(
        children: [
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono (ej: +573001112233)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCurrentPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña actual',
              border: OutlineInputBorder(),
            ),
          ),
          if (_phoneError != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _phoneError!,
                style: const TextStyle(color: Color(0xFFB91C1C)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _savingPhone ? null : _submitPhone,
              icon: _savingPhone
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sim_card_outlined),
              label: const Text('Actualizar teléfono'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return _CardShell(
      title: 'Cambiar contraseña',
      subtitle: 'Usa una contraseña nueva y confírmala.',
      child: Column(
        children: [
          TextField(
            controller: _passwordCurrentController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña actual',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordNewController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordConfirmController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmar nueva contraseña',
              border: OutlineInputBorder(),
            ),
          ),
          if (_passwordError != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _passwordError!,
                style: const TextStyle(color: Color(0xFFB91C1C)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _savingPassword ? null : _submitPassword,
              icon: _savingPassword
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_reset_rounded),
              label: const Text('Actualizar contraseña'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEmail() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final currentPassword = _emailCurrentPasswordController.text;

    if (email.isEmpty || currentPassword.isEmpty) {
      setState(() => _emailError = 'Completa correo y contraseña actual.');
      return;
    }

    setState(() {
      _savingEmail = true;
      _emailError = null;
    });

    try {
      await widget.authController.updateEmail(
        email: email,
        currentPassword: currentPassword,
      );

      _emailCurrentPasswordController.clear();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo actualizado correctamente.')),
      );
    } on ApiException catch (error) {
      setState(() => _emailError = error.message);
    } catch (error) {
      setState(
          () => _emailError = 'No fue posible actualizar el correo: $error');
    } finally {
      if (mounted) {
        setState(() => _savingEmail = false);
      }
    }
  }

  Future<void> _submitPassword() async {
    FocusScope.of(context).unfocus();

    final currentPassword = _passwordCurrentController.text;
    final newPassword = _passwordNewController.text;
    final confirmation = _passwordConfirmController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmation.isEmpty) {
      setState(
          () => _passwordError = 'Completa todos los campos de contraseña.');
      return;
    }

    if (newPassword != confirmation) {
      setState(() => _passwordError = 'La confirmación no coincide.');
      return;
    }

    setState(() {
      _savingPassword = true;
      _passwordError = null;
    });

    try {
      await widget.authController.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: confirmation,
      );

      _passwordCurrentController.clear();
      _passwordNewController.clear();
      _passwordConfirmController.clear();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada correctamente.')),
      );
    } on ApiException catch (error) {
      setState(() => _passwordError = error.message);
    } catch (error) {
      setState(() =>
          _passwordError = 'No fue posible actualizar la contraseña: $error');
    } finally {
      if (mounted) {
        setState(() => _savingPassword = false);
      }
    }
  }

  Future<void> _submitPhone() async {
    FocusScope.of(context).unfocus();

    final phone = _phoneController.text.trim();
    final currentPassword = _phoneCurrentPasswordController.text;

    if (phone.isEmpty || currentPassword.isEmpty) {
      setState(() => _phoneError = 'Completa teléfono y contraseña actual.');
      return;
    }

    setState(() {
      _savingPhone = true;
      _phoneError = null;
    });

    try {
      await widget.authController.updatePhone(
        phone: phone,
        currentPassword: currentPassword,
      );

      _phoneCurrentPasswordController.clear();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teléfono actualizado correctamente.')),
      );
    } on ApiException catch (error) {
      setState(() => _phoneError = error.message);
    } catch (error) {
      setState(
          () => _phoneError = 'No fue posible actualizar el teléfono: $error');
    } finally {
      if (mounted) {
        setState(() => _savingPhone = false);
      }
    }
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
