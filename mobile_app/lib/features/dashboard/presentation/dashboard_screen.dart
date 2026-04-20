import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../cotizaciones/presentation/cotizaciones_screen.dart';
import '../../facturas/presentation/facturas_screen.dart';
import '../../productos/presentation/productos_screen.dart';
import '../../servicios/presentation/servicios_screen.dart';
import 'dashboard_overview.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () async => authController.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: DashboardOverview(
        authController: authController,
        compact: true,
        onOpenProductos: () =>
            _open(context, ProductosScreen(authController: authController)),
        onOpenServicios: () =>
            _open(context, ServiciosScreen(authController: authController)),
        onOpenCotizaciones: () =>
            _open(context, CotizacionesScreen(authController: authController)),
        onOpenFacturas: () =>
            _open(context, FacturasScreen(authController: authController)),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
